enum AccountType {
  nequi,
  savingsHand,
  savingsAccount,
}

class AppConstants {
  // Tipos de cuenta
  static const String nequiTitle = 'NEQUI';
  static const String savingsHandTitle = 'Ahorro a la Mano';
  static const String savingsAccountTitle = 'Cuenta de Ahorros';

  // Descripciones
  static const String nequiDescription = 'Retiros con número de celular (10 dígitos)';
  static const String savingsHandDescription = 'Cuenta que inicia con 0 o 1, segundo dígito 3';
  static const String savingsAccountDescription = 'Cuenta de ahorros tradicional (11 dígitos)';

  // Tipos de documento
  static const List<String> documentTypes = ['CC', 'TI', 'CE', 'PP'];
  
  // Límites
  static const double maxDailyWithdrawal = 2000000.0;
  static const int maxDailyTransactions = 10;
  static const double minWithdrawal = 10000.0;
  
  // Billetes disponibles (sin 5000)
  static const List<int> availableBills = [100000, 50000, 20000, 10000];
  
  // Montos de retiro fijos
  static const List<double> fixedWithdrawalAmounts = [
    10000, 20000, 50000, 100000, 200000, 300000, 500000
  ];

  // Tiempo de expiración para código NEQUI (60 segundos)
  static const int authCodeExpirationSeconds = 60;

  // Colores
  static const int primaryColor = 0xFF2E7D32;
  static const int secondaryColor = 0xFF4CAF50;
  static const int errorColor = 0xFFD32F2F;
  static const int warningColor = 0xFFFF9800;
}

extension AccountTypeExtension on AccountType {
  String get title {
    switch (this) {
      case AccountType.nequi:
        return AppConstants.nequiTitle;
      case AccountType.savingsHand:
        return AppConstants.savingsHandTitle;
      case AccountType.savingsAccount:
        return AppConstants.savingsAccountTitle;
    }
  }

  String get description {
    switch (this) {
      case AccountType.nequi:
        return AppConstants.nequiDescription;
      case AccountType.savingsHand:
        return AppConstants.savingsHandDescription;
      case AccountType.savingsAccount:
        return AppConstants.savingsAccountDescription;
    }
  }

  String get icon {
    switch (this) {
      case AccountType.nequi:
        return '📱';
      case AccountType.savingsHand:
        return '🤝';
      case AccountType.savingsAccount:
        return '🏦';
    }
  }
}