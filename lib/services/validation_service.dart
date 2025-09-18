import 'package:cajero_automatico/utils/constants.dart';

class ValidationService {
  
  // Validaciones para NEQUI (Tipo 1)
  static bool isValidNequiPhone(String phone) {
    return phone.length == 10 && 
           RegExp(r'^[0-9]+$').hasMatch(phone) &&
           !phone.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'));
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
           !account.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'));
  }

  // Validación de PIN (4 dígitos)
  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(pin);
  }

  // Validación de email
  static bool isValidEmail(String email) {
  // Regex más flexible que permite caracteres especiales válidos
  return RegExp(
    r'^[a-zA-Z0-9.!#$%&\*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$'
  ).hasMatch(email.trim());
}

  // Validación de documento según tipo
  static bool isValidDocument(String document, String documentType) {
    document = document.trim();
    
    switch (documentType) {
      case 'CC': // Cédula de Ciudadanía
        return document.length >= 8 && 
               document.length <= 10 && 
               RegExp(r'^[0-9]+$').hasMatch(document);
      case 'TI': // Tarjeta de Identidad
        return document.length >= 8 && 
               document.length <= 10 && 
               RegExp(r'^[0-9]+$').hasMatch(document);
      case 'CE': // Cédula de Extranjería (puede ser alfanumérico)
        return document.length >= 6 && 
               document.length <= 12 && 
               RegExp(r'^[a-zA-Z0-9]+$').hasMatch(document);
      case 'PP': // Pasaporte (alfanumérico)
        return document.length >= 6 && 
               document.length <= 12 && 
               RegExp(r'^[a-zA-Z0-9]+$').hasMatch(document);
      default:
        return false;
    }
  }

  // Validación de nombres (sin números ni caracteres especiales)
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && 
           name.trim().length >= 2 &&
           RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(name.trim());
  }

  // Validación de teléfono general (10 dígitos)
  static bool isValidPhone(String phone) {
    return phone.length == 10 && 
           RegExp(r'^[0-9]{10}$').hasMatch(phone) &&
           !phone.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'));
  }

  // Estandarizar nombre a mayúsculas
  static String standardizeName(String name) {
    return name.trim().toUpperCase();
  }



  // Limpiar y estandarizar números (eliminar espacios, guiones, etc.)
  static String cleanNumber(String number) {
    return number.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Validar si el PIN es predecible o inseguro
  static bool isPinPredictable(String pin) {
    if (!isValidPin(pin)) return true;
    
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

  static String getPhoneError(String phone) {
    if (phone.isEmpty) return 'El número de teléfono es requerido';
    if (phone.length != 10) return 'El número debe tener exactamente 10 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) return 'Solo se permiten números (0-9)';
    if (phone.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'))) {
      return 'No se permiten caracteres especiales, letras o espacios';
    }
    return '';
  }

  static String getSavingsHandError(String account) {
    if (account.isEmpty) return 'El número de cuenta es requerido';
    if (account.length != 11) return 'El número debe tener exactamente 11 dígitos';
    if (account[0] != '0' && account[0] != '1') return 'Debe iniciar con 0 o 1';
    if (account.length > 1 && account[1] != '3') return 'El segundo dígito debe ser 3';
    if (!RegExp(r'^[0-9]+$').hasMatch(account)) return 'Solo se permiten números (0-9)';
    if (account.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'))) {
      return 'No se permiten caracteres especiales, letras o espacios';
    }
    return '';
  }

  static String getSavingsAccountError(String account) {
    if (account.isEmpty) return 'El número de cuenta es requerido';
    if (account.length != 11) return 'El número debe tener exactamente 11 dígitos';
    if (!RegExp(r'^[0-9]+$').hasMatch(account)) return 'Solo se permiten números (0-9)';
    if (account.contains(RegExp(r'[a-zA-Z!@#$%^&*(),.?":{}|<>_\-\s]'))) {
      return 'No se permiten caracteres especiales, letras o espacios';
    }
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

  static String getDocumentError(String document, String documentType) {
    if (document.isEmpty) return 'El número de documento es requerido';
    
    // Limpiar el documento de espacios y caracteres especiales no permitidos
    String cleanedDocument = document.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    
    switch (documentType) {
      case 'CC':
        if (cleanedDocument.length < 8) return 'La cédula debe tener al menos 8 dígitos';
        if (cleanedDocument.length > 10) return 'La cédula no puede tener más de 10 dígitos';
        if (!RegExp(r'^[0-9]+$').hasMatch(cleanedDocument)) return 'Solo se permiten números';
        break;
      case 'TI':
        if (cleanedDocument.length < 8) return 'La tarjeta de identidad debe tener al menos 8 dígitos';
        if (cleanedDocument.length > 10) return 'La tarjeta de identidad no puede tener más de 10 dígitos';
        if (!RegExp(r'^[0-9]+$').hasMatch(cleanedDocument)) return 'Solo se permiten números';
        break;
      case 'CE':
        if (cleanedDocument.length < 6) return 'La cédula de extranjería debe tener al menos 6 caracteres';
        if (cleanedDocument.length > 12) return 'La cédula de extranjería no puede tener más de 12 caracteres';
        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(cleanedDocument)) return 'Solo se permiten letras y números';
        break;
      case 'PP':
        if (cleanedDocument.length < 6) return 'El pasaporte debe tener al menos 6 caracteres';
        if (cleanedDocument.length > 12) return 'El pasaporte no puede tener más de 12 caracteres';
        if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(cleanedDocument)) return 'Solo se permiten letras y números';
        break;
    }
    
    return '';
  }

  static String getNameError(String name) {
    if (name.isEmpty) return 'Este campo es requerido';
    if (name.trim().length < 2) return 'Debe tener al menos 2 caracteres';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$').hasMatch(name.trim())) {
      return 'Solo se permiten letras y espacios';
    }
    return '';
  }

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
    required String documentType,
    required String documentNumber,
    required String pin,
    required AccountType accountType,
    String? accountIdentifier,
  }) {
    Map<String, String> errors = {};

    // Validar campos básicos
    String emailError = getEmailError(email);
    if (emailError.isNotEmpty) errors['email'] = emailError;

    String nameError = getNameError(fullName);
    if (nameError.isNotEmpty) errors['fullName'] = nameError;

    String phoneError = getPhoneError(phoneNumber);
    if (phoneError.isNotEmpty) errors['phoneNumber'] = phoneError;

    String documentError = getDocumentError(documentNumber, documentType);
    if (documentError.isNotEmpty) errors['documentNumber'] = documentError;

    String pinError = getPinError(pin);
    if (pinError.isNotEmpty) errors['pin'] = pinError;

    // Validar identificador de cuenta según el tipo
    if (accountIdentifier != null) {
      String accountError = validateAccountIdentifier(accountType, accountIdentifier);
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

    String accountError = validateAccountIdentifier(accountType, accountIdentifier);
    if (accountError.isNotEmpty) errors['accountIdentifier'] = accountError;

    String pinError = getPinError(pin);
    if (pinError.isNotEmpty) errors['pin'] = pinError;

    return errors;
  }
}