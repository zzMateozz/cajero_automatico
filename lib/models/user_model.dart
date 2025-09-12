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
    this.dailyWithdrawalLimit = 2000000.0,
    this.todayWithdrawnAmount = 0.0,
    this.dailyTransactionLimit = 10,
    this.todayTransactionCount = 0,
  });

  // Validaciones específicas para tu proyecto
  bool isValidNequiPhone(String phone) {
    return phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  bool isValidSavingsHandAccount(String account) {
    return account.length == 11 && 
           RegExp(r'^[01]3[0-9]{9}$').hasMatch(account); // Inicia con 0 o 1, segundo dígito es 3
  }

  bool isValidSavingsAccount(String account) {
    return account.length == 11 && RegExp(r'^[0-9]{11}$').hasMatch(account);
  }

  bool canWithdraw(double amount) {
    return (todayWithdrawnAmount + amount) <= dailyWithdrawalLimit &&
           todayTransactionCount < dailyTransactionLimit;
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
      dailyTransactionLimit: data['dailyTransactionLimit'] ?? 10,
      todayTransactionCount: data['todayTransactionCount'] ?? 0,
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
      'todayTransactionCount': todayTransactionCount,
    };
  }
}