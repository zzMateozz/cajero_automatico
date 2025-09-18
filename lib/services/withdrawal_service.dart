import 'dart:math';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class WithdrawalService {
  // Billetes disponibles en orden ascendente
  static const List<int> availableBills = [10000, 20000, 50000, 100000];

  /// Implementación de la metodología del acarreo
  static Map<String, dynamic> calculateBillsWithCarryMethod(double amount) {
    int targetAmount = amount.toInt();
    
    // Llamar al nuevo algoritmo
    Map<int, int>? billBreakdown = _calcularBilletes(targetAmount);
    
    bool success = billBreakdown != null;
    
    return {
      'success': success,
      'billBreakdown': billBreakdown ?? {},
      'totalDispensed': targetAmount,
      'remaining': 0,
      'message': success 
        ? 'Retiro calculado exitosamente' 
        : 'No se puede dispensar el monto exacto con billetes de 10,000, 20,000, 50,000 y 100,000'
    };
  }
  
  /// Nuevo algoritmo para calcular billetes
  static Map<int, int>? _calcularBilletes(int targetAmount) {
  if (targetAmount % 10000 != 0) return null;

  // Denominaciones en orden ascendente (índices: 0->10k, 1->20k, 2->50k, 3->100k)
  List<int> denominations = [10000, 20000, 50000, 100000];

  Map<int, int> billBreakdown = {
    10000: 0,
    20000: 0,
    50000: 0,
    100000: 0
  };

  int current = 0;
  int maxCycles = 10000; // límite de seguridad (puedes bajar si quieres)
  int cycles = 0;

  // Cada "ciclo" recorre las 4 filas (r = 0..3)
  while (current < targetAmount && cycles < maxCycles) {
    cycles++;
    bool addedInFullCycle = false;

    for (int r = 0; r < 4; r++) {
      bool addedInRow = false;

      // En la fila r sólo consideramos denominaciones con índice >= r
      for (int dIndex = 0; dIndex < denominations.length; dIndex++) {
        if (dIndex < r) continue; // celda '0' en la matriz
        int denom = denominations[dIndex];

        if (current + denom <= targetAmount) {
          // Aceptamos este billete (marcar 1 en la matriz)
          current += denom;
          billBreakdown[denom] = billBreakdown[denom]! + 1;
          addedInRow = true;
          addedInFullCycle = true;

          // Si ya alcanzamos el target, devolvemos el resultado inmediatamente
          if (current == targetAmount) {
            return billBreakdown;
          }
        }
      }

      // Si fila no agregó nada no reiniciamos el acumulado,
      // simplemente seguimos a la siguiente fila (como la matriz que mostraste).
    }

    // Si después de recorrer las 4 filas NO se añadió ningún billete,
    // entonces no hay combinación factible con esta estrategia.
    if (!addedInFullCycle) {
      return null;
    }
    // Si aún no llegamos al target, el while hará otra iteración (reinicia filas).
  }

  return current == targetAmount ? billBreakdown : null;
}
  
  /// Validar si un monto es dispensable
  static bool canDispenseAmount(double amount) {
    if (amount < 10000 || amount % 10000 != 0) return false;
    
    var result = calculateBillsWithCarryMethod(amount);
    return result['success'];
  }
  
  /// Calcular retiros posibles con saldo restante
  static List<double> calculatePossibleWithdrawals(double remainingBalance) {
    List<double> possible = [];
    List<double> testAmounts = [10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000, 110000, 120000, 130000, 140000, 150000, 160000, 170000, 180000, 190000, 200000, 250000, 300000, 350000, 400000, 450000, 500000, 600000, 700000, 800000, 900000, 1000000];
    
    for (double amount in testAmounts) {
      if (amount <= remainingBalance && canDispenseAmount(amount)) {
        possible.add(amount);
      }
    }
    
    return possible;
  }
  
  /// Validar monto de retiro
  static Map<String, dynamic> validateWithdrawalAmount(double amount, double currentBalance, UserModel user) {
    Map<String, dynamic> result = {
      'isValid': false,
      'message': '',
      'canProceed': false,
    };
    
    // Validar monto mínimo
    if (amount < 10000) {
      result['message'] = 'El monto mínimo de retiro es \$10,000';
      return result;
    }
    
    // Validar múltiplo de 10,000
    if (amount % 10000 != 0) {
      result['message'] = 'El monto debe ser múltiplo de \$10,000';
      return result;
    }
    
    // Validar saldo disponible
    if (amount > currentBalance) {
      result['message'] = 'Saldo insuficiente. Disponible: \$${_formatCurrency(currentBalance)}';
      return result;
    }
    
    // Validar si es dispensable
    if (!canDispenseAmount(amount)) {
      result['message'] = 'No se puede dispensar este monto con billetes de 10,000, 20,000, 50,000 y 100,000';
      return result;
    }
    
    // Validar límites del usuario
    var userValidation = user.validateWithdrawal(amount);
    if (!userValidation['isValid']) {
      result['message'] = userValidation['message'];
      return result;
    }
    
    result['isValid'] = true;
    result['canProceed'] = true;
    result['message'] = 'Monto válido para retiro';
    
    return result;
  }
  
  /// Procesar retiro completo
  static Map<String, dynamic> processWithdrawal({
    required UserModel user,
    required AccountType accountType,
    required double amount,
    String? authCode, // Para NEQUI
    String? pin, // Para Ahorro a la Mano y Cuenta de Ahorros
  }) {
    try {
      // 1. Obtener saldo actual según tipo de cuenta
      double currentBalance = _getCurrentBalance(user, accountType);
      
      // 2. Validar monto
      var validation = validateWithdrawalAmount(amount, currentBalance, user);
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
          'transaction': null,
        };
      }
      
      // 3. Calcular billetes
      var billCalculation = calculateBillsWithCarryMethod(amount);
      if (!billCalculation['success']) {
        return {
          'success': false,
          'message': billCalculation['message'],
          'transaction': null,
        };
      }
      
      // 4. Crear transacción
      TransactionModel transaction = TransactionModel(
        id: _generateTransactionId(),
        userId: user.uid,
        type: _getTransactionType(accountType),
        amount: amount,
        date: DateTime.now(),
        status: TransactionStatus.completed,
        accountNumber: _getAccountNumber(user, accountType),
        phoneNumber: accountType == AccountType.nequi ? user.nequiPhoneNumber : null,
        authCode: authCode,
        billBreakdown: Map<int, int>.from(billCalculation['billBreakdown']),
      );
      
      // 5. Calcular retiros posibles con saldo restante
      double remainingBalance = currentBalance - amount;
      List<double> possibleWithdrawals = calculatePossibleWithdrawals(remainingBalance);
      
      return {
        'success': true,
        'message': 'Retiro procesado exitosamente',
        'transaction': transaction,
        'billBreakdown': billCalculation['billBreakdown'],
        'remainingBalance': remainingBalance,
        'possibleWithdrawals': possibleWithdrawals,
        'displayNumber': _getDisplayNumber(user, accountType),
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error procesando el retiro: $e',
        'transaction': null,
      };
    }
  }
  
  /// Generar código NEQUI temporal
  static Map<String, dynamic> generateNequiAuthCode() {
    Random random = Random();
    String code = (random.nextInt(900000) + 100000).toString();
    DateTime expiresAt = DateTime.now().add(const Duration(seconds: 60));
    
    return {
      'code': code,
      'expiresAt': expiresAt,
      'isValid': true,
    };
  }
  
  /// Validar código NEQUI
  static bool validateNequiAuthCode(String enteredCode, String validCode, DateTime expiryTime) {
    if (DateTime.now().isAfter(expiryTime)) {
      return false; // Código expirado
    }
    return enteredCode == validCode;
  }
  
  // ========== MÉTODOS PRIVADOS DE UTILIDAD ==========
  
  static double _getCurrentBalance(UserModel user, AccountType accountType) {
    switch (accountType) {
      case AccountType.nequi:
        return user.nequiBalance;
      case AccountType.savingsHand:
        return user.savingsHandBalance;
      case AccountType.savingsAccount:
        return user.savingsAccountBalance;
    }
  }
  
  static TransactionType _getTransactionType(AccountType accountType) {
    switch (accountType) {
      case AccountType.nequi:
        return TransactionType.nequiWithdrawal;
      case AccountType.savingsHand:
        return TransactionType.savingsHandWithdrawal;
      case AccountType.savingsAccount:
        return TransactionType.savingsAccountWithdrawal;
    }
  }
  
  static String? _getAccountNumber(UserModel user, AccountType accountType) {
    switch (accountType) {
      case AccountType.nequi:
        return null;
      case AccountType.savingsHand:
        return user.savingsHandAccountNumber;
      case AccountType.savingsAccount:
        return user.savingsAccountNumber;
    }
  }
  
  static String _getDisplayNumber(UserModel user, AccountType accountType) {
    switch (accountType) {
      case AccountType.nequi:
        return '0${user.nequiPhoneNumber}'; // Mostrar con 0 al inicio (11 dígitos)
      case AccountType.savingsHand:
        return user.savingsHandAccountNumber ?? '';
      case AccountType.savingsAccount:
        return user.savingsAccountNumber ?? '';
    }
  }
  
  static String _generateTransactionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}