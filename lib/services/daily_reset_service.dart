import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Verificar y realizar reinicio diario si es necesario
  static Future<void> checkAndResetDailyCounters(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      
      final lastResetDate = userData['lastResetDate'] != null 
          ? (userData['lastResetDate'] as Timestamp).toDate() 
          : null;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Si no hay fecha de último reinicio o no es hoy, reiniciamos
      if (lastResetDate == null || 
          !isSameDay(lastResetDate, now)) {
        
        await _firestore.collection('users').doc(userId).update({
          'todayWithdrawnAmount': 0.0,
          'todayTransactionCount': 0,
          'lastResetDate': Timestamp.fromDate(now),
        });
        
        print('Contadores reiniciados para el usuario: $userId');
      }
    } catch (e) {
      print('Error al verificar/reiniciar contadores diarios: $e');
    }
  }
  
  // Verificar si dos fechas son el mismo día
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  // Para uso futuro: reinicio forzado (útil para testing)
  static Future<void> forceResetDailyCounters(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'todayWithdrawnAmount': 0.0,
        'todayTransactionCount': 0,
        'lastResetDate': Timestamp.now(),
      });
    } catch (e) {
      print('Error en reinicio forzado: $e');
    }
  }
}