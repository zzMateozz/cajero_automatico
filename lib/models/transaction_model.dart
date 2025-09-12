import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  nequiWithdrawal,        // Retiro tipo 1: por número celular
  savingsHandWithdrawal,  // Retiro tipo 2: ahorro a la mano
  savingsAccountWithdrawal, // Retiro tipo 3: cuenta de ahorros
}

enum TransactionStatus {
  pending,   // Pendiente (esperando código de autorización)
  completed, // Completada exitosamente
  failed,    // Falló
  expired    // Código de autorización expirado
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final TransactionStatus status;
  
  // Para diferentes tipos de cuenta
  final String? accountNumber;  // Para ahorros y ahorro a la mano (11 dígitos)
  final String? phoneNumber;    // Para NEQUI (10 dígitos)
  
  // CRÍTICO: Para NEQUI - Código temporal de 6 dígitos visible por 60 segundos
  final String? authCode;
  final DateTime? authCodeExpires;
  
  // CRÍTICO: Desglose de billetes según metodología del acarreo
  final Map<int, int>? billBreakdown; // {denominación: cantidad}
  
  final String? failureReason;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.date,
    this.status = TransactionStatus.pending,
    this.accountNumber,
    this.phoneNumber,
    this.authCode,
    this.authCodeExpires,
    this.billBreakdown,
    this.failureReason,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return TransactionModel(
      id: doc.id,
      userId: data['userId'],
      type: _parseTransactionType(data['type']),
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: _parseTransactionStatus(data['status']),
      accountNumber: data['accountNumber'],
      phoneNumber: data['phoneNumber'],
      authCode: data['authCode'],
      authCodeExpires: (data['authCodeExpires'] as Timestamp?)?.toDate(),
      billBreakdown: _parseBillBreakdown(data['billBreakdown']),
      failureReason: data['failureReason'],
    );
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'nequiWithdrawal': return TransactionType.nequiWithdrawal;
      case 'savingsHandWithdrawal': return TransactionType.savingsHandWithdrawal;
      case 'savingsAccountWithdrawal': return TransactionType.savingsAccountWithdrawal;
      default: return TransactionType.nequiWithdrawal;
    }
  }

  static TransactionStatus _parseTransactionStatus(String status) {
    switch (status) {
      case 'pending': return TransactionStatus.pending;
      case 'completed': return TransactionStatus.completed;
      case 'failed': return TransactionStatus.failed;
      case 'expired': return TransactionStatus.expired;
      default: return TransactionStatus.pending;
    }
  }

  static String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.nequiWithdrawal: return 'nequiWithdrawal';
      case TransactionType.savingsHandWithdrawal: return 'savingsHandWithdrawal';
      case TransactionType.savingsAccountWithdrawal: return 'savingsAccountWithdrawal';
    }
  }

  static String _transactionStatusToString(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending: return 'pending';
      case TransactionStatus.completed: return 'completed';
      case TransactionStatus.failed: return 'failed';
      case TransactionStatus.expired: return 'expired';
    }
  }

  static Map<int, int>? _parseBillBreakdown(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    Map<int, int> breakdown = {};
    data.forEach((key, value) {
      breakdown[int.parse(key)] = value.toInt();
    });
    return breakdown;
  }

  // MÉTODO CRÍTICO: Calcula el desglose de billetes usando metodología del acarreo
  static Map<int, int> calculateBillBreakdown(double amount) {
    Map<int, int> breakdown = {100000: 0, 50000: 0, 20000: 0, 10000: 0};
    int remaining = amount.toInt();
    
    // Metodología del acarreo - billetes de mayor a menor
    List<int> denominations = [100000, 50000, 20000, 10000];
    
    for (int denomination in denominations) {
      int count = remaining ~/ denomination;
      if (count > 0) {
        breakdown[denomination] = count;
        remaining -= (count * denomination);
      }
    }
    
    return breakdown;
  }

  // Valida si es un monto dispensable (sin billetes de 5000)
  static bool canDispense(double amount) {
    if (amount < 10000 || amount % 10000 != 0) return false;
    
    Map<int, int> breakdown = calculateBillBreakdown(amount);
    int total = 0;
    
    breakdown.forEach((denomination, count) {
      total += denomination * count;
    });
    
    return total == amount.toInt();
  }

  // Genera código de autorización de 6 dígitos para NEQUI
  static String generateAuthCode() {
    var random = DateTime.now().millisecondsSinceEpoch;
    return (random % 1000000).toString().padLeft(6, '0');
  }

  // Verifica si el código de autorización está vigente
  bool isAuthCodeValid() {
    if (authCodeExpires == null) return false;
    return DateTime.now().isBefore(authCodeExpires!);
  }

  // Para NEQUI: formatea el número para mostrar (agrega 0 al inicio)
  String getDisplayNumber() {
    if (type == TransactionType.nequiWithdrawal && phoneNumber != null) {
      return '0$phoneNumber'; // Convierte 10 dígitos a 11
    }
    return accountNumber ?? phoneNumber ?? '';
  }

  // Calcula retiros posibles restantes
  Map<String, dynamic> calculatePossibleWithdrawals(double availableBalance) {
    List<double> commonAmounts = [10000, 20000, 50000, 100000, 200000, 300000, 500000];
    List<double> possible = [];
    
    for (double amount in commonAmounts) {
      if (amount <= availableBalance && canDispense(amount)) {
        possible.add(amount);
      }
    }
    
    return {
      'amounts': possible,
      'maxAmount': availableBalance,
      'canDispenseMax': canDispense(availableBalance)
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': _transactionTypeToString(type),
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': _transactionStatusToString(status),
      'accountNumber': accountNumber,
      'phoneNumber': phoneNumber,
      'authCode': authCode,
      'authCodeExpires': authCodeExpires != null ? Timestamp.fromDate(authCodeExpires!) : null,
      'billBreakdown': billBreakdown?.map((key, value) => MapEntry(key.toString(), value)),
      'failureReason': failureReason,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    TransactionStatus? status,
    String? accountNumber,
    String? phoneNumber,
    String? authCode,
    DateTime? authCodeExpires,
    Map<int, int>? billBreakdown,
    String? failureReason,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      accountNumber: accountNumber ?? this.accountNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authCode: authCode ?? this.authCode,
      authCodeExpires: authCodeExpires ?? this.authCodeExpires,
      billBreakdown: billBreakdown ?? this.billBreakdown,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}