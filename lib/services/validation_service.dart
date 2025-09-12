import 'package:cajero_automatico/utils/constants.dart';

class ValidationService {
  // ========== VALIDACIONES DE FORMATO ==========
  
  // Validaciones para NEQUI (Tipo 1)
  static bool isValidNequiPhone(String phone) {
    return phone.length == 10 && 
           RegExp(r'^[0-9]+$').hasMatch(phone) &&
           !phone.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>]'));
  }

  // Validaciones para Ahorro a la Mano (Tipo 2)
  static bool isValidSavingsHandAccount(String account) {
    if (account.length != 11) return false;
    
    // Primer dígito debe ser 0 o 1
    String firstDigit = account[0];
    if (firstDigit != '0' && firstDigit != '1') return false;
    
    // Segundo dígito debe ser 3
    String secondDigit = account[1];
    if (secondDigit != '3') return false;
    
    // Solo números, sin caracteres especiales o alfabéticos
    return RegExp(r'^[01]3[0-9]{9}$').hasMatch(account);
  }

  // Validaciones para Cuenta de Ahorros (Tipo 3)
  static bool isValidSavingsAccount(String account) {
    return account.length == 11 && 
           RegExp(r'^[0-9]{11}$').hasMatch(account) &&
           !account.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>]'));
  }

  // Validación de PIN (4 dígitos)
  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(pin);
  }

  // Validación de email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validación de documento
  static bool isValidDocument(String document) {
    return document.isNotEmpty && 
           document.length >= 6 && 
           document.length <= 15 &&
           RegExp(r'^[0-9]+$').hasMatch(document);
  }

  // Validación de nombres (sin números ni caracteres especiales)
  static bool isValidName(String name) {
    return name.isNotEmpty && 
           name.length >= 2 &&
           RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(name);
  }

  // Validación de teléfono general (10 dígitos)
  static bool isValidPhone(String phone) {
    return phone.length == 10 && RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  // ========== VALIDACIONES DE REGLAS DE NEGOCIO ==========

  // Validar si el PIN es predecible o inseguro
  static bool isPinPredictable(String pin) {
    if (!isValidPin(pin)) return true; // Si no es válido, es considerado predecible
    
    // PINs obviamente inseguros
    if (pin == '1234' || pin == '0000' || pin == '1111' || pin == '2222' || 
        pin == '3333' || pin == '4444' || pin == '5555' || pin == '6666' || 
        pin == '7777' || pin == '8888' || pin == '9999') {
      return true;
    }

    // PIN secuencial ascendente o descendente
    if (isSequentialPin(pin)) {
      return true;
    }

    return false;
  }

  // Verificar si el PIN es secuencial
  static bool isSequentialPin(String pin) {
    if (pin.length != 4) return false;
    
    List<int> digits = pin.split('').map(int.parse).toList();
    
    // Verificar secuencia ascendente
    bool ascending = true;
    bool descending = true;
    
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] + 1) ascending = false;
      if (digits[i] != digits[i-1] - 1) descending = false;
    }
    
    return ascending || descending;
  }

  // ========== MENSAJES DE ERROR ==========

  static String getPhoneError(String phone) {
    if (phone.isEmpty) return 'El número de teléfono es requerido';
    if (phone.length != 10) return 'El número debe tener exactamente 10 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) return 'Solo se permiten números (0-9)';
    return '';
  }

  static String getSavingsHandError(String account) {
    if (account.isEmpty) return 'El número de cuenta es requerido';
    if (account.length != 11) return 'El número debe tener exactamente 11 dígitos';
    if (account[0] != '0' && account[0] != '1') return 'Debe iniciar con 0 o 1';
    if (account.length > 1 && account[1] != '3') return 'El segundo dígito debe ser 3';
    if (!RegExp(r'^[0-9]+$').hasMatch(account)) return 'Solo se permiten números (0-9)';
    return '';
  }

  static String getSavingsAccountError(String account) {
    if (account.isEmpty) return 'El número de cuenta es requerido';
    if (account.length != 11) return 'El número debe tener exactamente 11 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(account)) return 'Solo se permiten números (0-9)';
    return '';
  }

  static String getPinError(String pin) {
    if (pin.isEmpty) return 'El PIN es requerido';
    if (pin.length != 4) return 'El PIN debe tener exactamente 4 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) return 'El PIN solo puede contener números';
    if (isPinPredictable(pin)) return 'Por seguridad, elige un PIN menos predecible';
    return '';
  }

  static String getEmailError(String email) {
    if (email.isEmpty) return 'El correo electrónico es requerido';
    if (!isValidEmail(email)) return 'Ingrese un correo electrónico válido';
    return '';
  }

  static String getDocumentError(String document) {
    if (document.isEmpty) return 'El número de documento es requerido';
    if (document.length < 6) return 'El documento debe tener al menos 6 dígitos';
    if (document.length > 15) return 'El documento no puede tener más de 15 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(document)) return 'Solo se permiten números';
    return '';
  }

  static String getNameError(String name) {
    if (name.isEmpty) return 'Este campo es requerido';
    if (name.length < 2) return 'Debe tener al menos 2 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(name)) {
      return 'Solo se permiten letras y espacios';
    }
    return '';
  }

  // ========== VALIDADORES INTEGRADOS CON MENSAJES ==========

  // Validador completo para cualquier tipo de cuenta
  static String validateAccountIdentifier(AccountType accountType, String identifier) {
    switch (accountType) {
      case AccountType.nequi:
        return getPhoneError(identifier);
      case AccountType.savingsHand:
        return getSavingsHandError(identifier);
      case AccountType.savingsAccount:
        return getSavingsAccountError(identifier);
    }
  }

  // Validación completa de datos de registro
  static Map<String, String> validateRegistrationData({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String documentNumber,
    required String pin,
    required AccountType accountType,
    String? accountIdentifier,
  }) {
    Map<String, String> errors = {};

    // Validar campos básicos
    String emailError = getEmailError(email.trim());
    if (emailError.isNotEmpty) errors['email'] = emailError;

    String nameError = getNameError(fullName.trim());
    if (nameError.isNotEmpty) errors['fullName'] = nameError;

    String phoneError = getPhoneError(phoneNumber.trim());
    if (phoneError.isNotEmpty) errors['phoneNumber'] = phoneError;

    String documentError = getDocumentError(documentNumber.trim());
    if (documentError.isNotEmpty) errors['documentNumber'] = documentError;

    String pinError = getPinError(pin);
    if (pinError.isNotEmpty) errors['pin'] = pinError;

    // Validar identificador de cuenta según el tipo
    if (accountIdentifier != null) {
      String accountError = validateAccountIdentifier(accountType, accountIdentifier.trim());
      if (accountError.isNotEmpty) errors['accountIdentifier'] = accountError;
    }

    return errors;
  }

  // Validación de datos de login
  static Map<String, String> validateLoginData({
    required AccountType accountType,
    required String accountIdentifier,
    required String pin,
  }) {
    Map<String, String> errors = {};

    String accountError = validateAccountIdentifier(accountType, accountIdentifier.trim());
    if (accountError.isNotEmpty) errors['accountIdentifier'] = accountError;

    String pinError = getPinError(pin);
    if (pinError.isNotEmpty) errors['pin'] = pinError;

    return errors;
  }
}