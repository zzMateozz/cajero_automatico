import 'package:cajero_automatico/services/validation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // Identificación básica - ESENCIAL
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber; // Para NEQUI (debe ser 10 dígitos)
  final String documentType;
  final String documentNumber;
  final String hashedPin; // Clave de 4 dígitos para ahorros

  // Control de seguridad - IMPORTANTE
  final int failedLoginAttempts;
  final bool isBlocked;
  final DateTime? blockedUntil;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  // NEQUI - CRÍTICO para retiro tipo 1
  final String? nequiPhoneNumber; // 10 dígitos, se mostrará como 11 (con 0 al inicio)
  final double nequiBalance;
  final bool nequiEnabled;

  // Ahorro a la Mano - CRÍTICO para retiro tipo 2
  final String? savingsHandAccountNumber; // 11 dígitos, inicia con 0 o 1, segundo dígito debe ser 3
  final double savingsHandBalance;
  final bool savingsHandEnabled;

  // Cuenta de Ahorros - CRÍTICO para retiro tipo 3
  final String? savingsAccountNumber; // 11 dígitos (0-9)
  final double savingsAccountBalance;
  final bool savingsAccountEnabled;

  // Límites diarios - IMPORTANTE para control
  final double dailyWithdrawalLimit;
  final double todayWithdrawnAmount;
  final int dailyTransactionLimit;
  final int todayTransactionCount;
  final DateTime? lastResetDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.documentType,
    required this.documentNumber,
    required this.hashedPin,
    this.failedLoginAttempts = 0,
    this.isBlocked = false,
    this.blockedUntil,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
    this.nequiPhoneNumber,
    this.nequiBalance = 0.0,
    this.nequiEnabled = false,
    this.savingsHandAccountNumber,
    this.savingsHandBalance = 0.0,
    this.savingsHandEnabled = false,
    this.savingsAccountNumber,
    this.savingsAccountBalance = 0.0,
    this.savingsAccountEnabled = false,
    this.dailyWithdrawalLimit = 2700000.0,
    this.todayWithdrawnAmount = 0.0,
    this.dailyTransactionLimit = 15,
    this.todayTransactionCount = 0,
    this.lastResetDate,
  });

  // Validaciones específicas para tu proyecto
  bool isValidNequiPhone(String phone) {
    final cleanedPhone = ValidationService.cleanNumber(phone);
    return ValidationService.isValidNequiPhone(cleanedPhone);
  }

  bool isValidSavingsHandAccount(String account) {
    final cleanedAccount = ValidationService.cleanNumber(account);
    return ValidationService.isValidSavingsHandAccount(cleanedAccount);
  }

  bool isValidSavingsAccount(String account) {
    final cleanedAccount = ValidationService.cleanNumber(account);
    return ValidationService.isValidSavingsAccount(cleanedAccount);
  }

  // Método para validar que el monto sea dispensable (sin billetes de 5000)
  bool isValidWithdrawalAmount(double amount) {
    // Solo billetes de 10000, 20000, 50000, 100000
    if (amount < 10000 || amount % 10000 != 0) return false;
    
    // Algoritmo de verificación para combinación de billetes
    int remaining = amount.toInt();
    
    // Intentar con billetes disponibles (metodología del acarreo)
    List<int> bills = [100000, 50000, 20000, 10000];
    
    for (int bill in bills) {
      remaining = remaining % bill;
    }
    
    return remaining == 0;
  }

  // Método para validar límites de retiro
  Map<String, dynamic> validateWithdrawal(double amount) {
    Map<String, dynamic> result = {
      'isValid': true,
      'message': '',
      'exceedsDailyLimit': false,
      'exceedsTransactionLimit': false,
      'invalidAmount': false
    };

    // Validar monto mínimo
    if (amount < 10000) {
      result['isValid'] = false;
      result['message'] = 'El monto mínimo de retiro es \$10.000';
      result['invalidAmount'] = true;
      return result;
    }

    // Validar monto máximo por transacción
    if (amount > 2700000) {
      result['isValid'] = false;
      result['message'] = 'El monto máximo por transacción es \$600.000';
      result['invalidAmount'] = true;
      return result;
    }

    // Validar límite diario
    if ((todayWithdrawnAmount + amount) > dailyWithdrawalLimit) {
      result['isValid'] = false;
      result['message'] = 'Excede su límite diario de retiro de \$${dailyWithdrawalLimit.toStringAsFixed(0)}';
      result['exceedsDailyLimit'] = true;
      return result;
    }

    // Validar límite de transacciones
    if (todayTransactionCount >= dailyTransactionLimit) {
      result['isValid'] = false;
      result['message'] = 'Ha alcanzado el límite de $dailyTransactionLimit transacciones diarias';
      result['exceedsTransactionLimit'] = true;
      return result;
    }

    // Validar si el monto es dispensable
    if (!isValidWithdrawalAmount(amount)) {
      result['isValid'] = false;
      result['message'] = 'El monto no es dispensable. Solo se permiten múltiplos de \$10.000';
      result['invalidAmount'] = true;
      return result;
    }

    return result;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      documentType: data['documentType'] ?? 'CC',
      documentNumber: data['documentNumber'] ?? '',
      hashedPin: data['hashedPin'] ?? '',
      failedLoginAttempts: data['failedLoginAttempts'] ?? 0,
      isBlocked: data['isBlocked'] ?? false,
      blockedUntil: (data['blockedUntil'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      nequiPhoneNumber: data['nequiPhoneNumber'],
      nequiBalance: (data['nequiBalance'] ?? 0.0).toDouble(),
      nequiEnabled: data['nequiEnabled'] ?? false,
      savingsHandAccountNumber: data['savingsHandAccountNumber'],
      savingsHandBalance: (data['savingsHandBalance'] ?? 0.0).toDouble(),
      savingsHandEnabled: data['savingsHandEnabled'] ?? false,
      savingsAccountNumber: data['savingsAccountNumber'],
      savingsAccountBalance: (data['savingsAccountBalance'] ?? 0.0).toDouble(),
      savingsAccountEnabled: data['savingsAccountEnabled'] ?? false,
      dailyWithdrawalLimit: (data['dailyWithdrawalLimit'] ?? 2000000.0).toDouble(),
      todayWithdrawnAmount: (data['todayWithdrawnAmount'] ?? 0.0).toDouble(),
      dailyTransactionLimit: data['dailyTransactionLimit'] ?? 15,
      todayTransactionCount: data['todayTransactionCount'] ?? 0,
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'hashedPin': hashedPin,
      'failedLoginAttempts': failedLoginAttempts,
      'isBlocked': isBlocked,
      'blockedUntil': blockedUntil != null ? Timestamp.fromDate(blockedUntil!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
      'nequiPhoneNumber': nequiPhoneNumber,
      'nequiBalance': nequiBalance,
      'nequiEnabled': nequiEnabled,
      'savingsHandAccountNumber': savingsHandAccountNumber,
      'savingsHandBalance': savingsHandBalance,
      'savingsHandEnabled': savingsHandEnabled,
      'savingsAccountNumber': savingsAccountNumber,
      'savingsAccountBalance': savingsAccountBalance,
      'savingsAccountEnabled': savingsAccountEnabled,
      'dailyWithdrawalLimit': dailyWithdrawalLimit,
      'todayWithdrawnAmount': todayWithdrawnAmount,
      'dailyTransactionLimit': dailyTransactionLimit,
      'todayTransactionCount': todayTransactionCount,'lastResetDate': lastResetDate != null ? Timestamp.fromDate(lastResetDate!) : null,
    };
  }
}