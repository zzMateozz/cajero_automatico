import 'dart:math';
import 'package:cajero_automatico/services/validation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isLoggedIn => currentUser != null;

  // ========== UTILIDADES PRIVADAS ==========

  String _hashPin(String pin) {
    var bytes = utf8.encode(pin + "PIN_SALT_2024");
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generar contraseña más segura y consistente
  String _generateSecurePassword(String email) {
    var bytes = utf8.encode(email.toLowerCase().trim() + "SECURE_CAJERO_2024");
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 20); // 20 caracteres para mayor seguridad
  }

  // ========== REGISTRO CON VALIDACIONES MEJORADAS ==========

  Future<UserModel> registerUser({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String documentType,
    required String documentNumber,
    required String pin,
    required AccountType accountType,
    String? nequiPhoneNumber,
    String? savingsHandAccountNumber,
    String? savingsAccountNumber,
  }) async {
    try {
      // 1. Limpiar y normalizar datos de entrada
      email = email.trim().toLowerCase();
      fullName = fullName.trim();
      phoneNumber = phoneNumber.trim();
      documentNumber = documentNumber.trim();

      // 2. Validaciones básicas
      String? accountIdentifier;
      switch (accountType) {
        case AccountType.nequi:
          accountIdentifier = nequiPhoneNumber?.trim();
          break;
        case AccountType.savingsHand:
          accountIdentifier = savingsHandAccountNumber?.trim();
          break;
        case AccountType.savingsAccount:
          accountIdentifier = savingsAccountNumber?.trim();
          break;
      }

      final validationErrors = ValidationService.validateRegistrationData(
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        documentNumber: documentNumber,
        pin: pin,
        accountType: accountType,
        accountIdentifier: accountIdentifier,
      );

      if (validationErrors.isNotEmpty) {
        String firstError = validationErrors.values.first;
        throw Exception(firstError);
      }

      // 3. Verificaciones de existencia
      if (await checkEmailExists(email)) {
        throw Exception('Este correo electrónico ya está registrado.');
      }
      if (await checkDocumentExists(documentNumber)) {
        throw Exception('Este documento ya está registrado en el sistema.');
      }

      // Verificar identificador específico según tipo de cuenta
      if (accountIdentifier != null && await checkAccountIdentifierExists(accountType, accountIdentifier)) {
        String accountTypeName;
        switch (accountType) {
          case AccountType.nequi:
            accountTypeName = 'número NEQUI';
            break;
          case AccountType.savingsHand:
            accountTypeName = 'número de cuenta Ahorro a la Mano';
            break;
          case AccountType.savingsAccount:
            accountTypeName = 'número de cuenta de ahorros';
            break;
        }
        throw Exception('Este $accountTypeName ya está registrado.');
      }

      // 4. Generar contraseña segura
      final password = _generateSecurePassword(email);
      
      // 5. Crear usuario en Firebase Auth con reintentos
      UserCredential? userCredential;
      int retries = 0;
      const maxRetries = 3;
      
      while (retries < maxRetries) {
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          break; // Si es exitoso, salir del bucle
        } on FirebaseAuthException catch (e) {
          retries++;
          if (retries >= maxRetries) {
            throw Exception(_handleAuthException(e));
          }
          // Esperar antes de reintentar
          await Future.delayed(Duration(seconds: retries));
        }
      }

      if (userCredential == null) {
        throw Exception('No se pudo crear la cuenta después de varios intentos.');
      }

      final user = userCredential.user!;
      
      // 6. Actualizar perfil del usuario
      try {
        await user.updateDisplayName(fullName);
        await user.reload();
      } catch (e) {
        print('Warning: No se pudo actualizar el nombre del usuario: $e');
      }
      
      // 7. Crear modelo de usuario con balances iniciales
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        documentType: documentType,
        documentNumber: documentNumber,
        hashedPin: _hashPin(pin),
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        
        // Configuración específica por tipo de cuenta
        nequiPhoneNumber: accountType == AccountType.nequi ? nequiPhoneNumber?.trim() : null,
        nequiEnabled: accountType == AccountType.nequi,
        nequiBalance: accountType == AccountType.nequi ? 50000.0 : 0.0,
        
        savingsHandAccountNumber: accountType == AccountType.savingsHand ? savingsHandAccountNumber?.trim() : null,
        savingsHandEnabled: accountType == AccountType.savingsHand,
        savingsHandBalance: accountType == AccountType.savingsHand ? 100000.0 : 0.0,
        
        savingsAccountNumber: accountType == AccountType.savingsAccount ? savingsAccountNumber?.trim() : null,
        savingsAccountEnabled: accountType == AccountType.savingsAccount,
        savingsAccountBalance: accountType == AccountType.savingsAccount ? 200000.0 : 0.0,

        // Campos de seguridad
        failedLoginAttempts: 0,
        isBlocked: false,
        blockedUntil: null,
      );

      // 8. Guardar en Firestore con reintentos
      retries = 0;
      while (retries < maxRetries) {
        try {
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          break;
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            // Si falla el guardado, eliminar el usuario de Auth
            try {
              await user.delete();
            } catch (deleteError) {
              print('Error eliminando usuario después de fallo en Firestore: $deleteError');
            }
            throw Exception('No se pudieron guardar los datos del usuario.');
          }
          await Future.delayed(Duration(seconds: retries));
        }
      }

      return userModel;
      
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception('Error inesperado durante el registro: ${e.toString()}');
    }
  }

  // ========== LOGIN MEJORADO ==========

  Future<UserModel> loginUser({
    required AccountType accountType,
    required String accountIdentifier,
    required String pin,
  }) async {
    try {
      // 1. Normalizar datos de entrada
      accountIdentifier = accountIdentifier.trim();
      pin = pin.trim();

      // 2. Validaciones básicas
      final validationErrors = ValidationService.validateLoginData(
        accountType: accountType,
        accountIdentifier: accountIdentifier,
        pin: pin,
      );

      if (validationErrors.isNotEmpty) {
        String firstError = validationErrors.values.first;
        throw Exception(firstError);
      }

      // 3. Buscar usuario por identificador de cuenta
      UserModel? userModel = await _findUserByAccountIdentifier(accountType, accountIdentifier);
      
      if (userModel == null) {
        throw Exception('No se encontró una cuenta con estos datos.');
      }

      // 4. Verificar estado de la cuenta
      if (userModel.isBlocked) {
        if (userModel.blockedUntil != null && DateTime.now().isBefore(userModel.blockedUntil!)) {
          final remaining = userModel.blockedUntil!.difference(DateTime.now()).inMinutes + 1;
          throw Exception('Cuenta bloqueada. Intenta de nuevo en $remaining minutos.');
        } else {
          // Desbloquear si ya pasó el tiempo
          await _unblockUser(userModel.uid);
          userModel = await getUserData(userModel.uid);
        }
      }

      // 5. Verificar PIN
      if (userModel.hashedPin != _hashPin(pin)) {
        await _incrementFailedAttempts(userModel.uid);
        throw Exception('PIN incorrecto.');
      }

      // 6. Verificar que el tipo de cuenta esté habilitado
      if (!_isAccountTypeEnabled(userModel, accountType)) {
        throw Exception('Este tipo de cuenta no está habilitado para tu usuario.');
      }

      // 7. Autenticar en Firebase
      final password = _generateSecurePassword(userModel.email);
      
      try {
        await _auth.signInWithEmailAndPassword(
          email: userModel.email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'user-not-found') {
          throw Exception('Error de autenticación. Contacta al soporte técnico.');
        }
        throw Exception(_handleAuthException(e));
      }

      // 8. Actualizar datos de login exitoso
      await _resetFailedAttempts(userModel.uid);
      await _firestore.collection('users').doc(userModel.uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      return await getUserData(userModel.uid);
      
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (e.toString().startsWith('Exception:')) {
        rethrow;
      }
      throw Exception('Error inesperado durante el login: ${e.toString()}');
    }
  }

  // ========== MÉTODOS DE VERIFICACIÓN ==========
  
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  Future<bool> checkDocumentExists(String documentNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('documentNumber', isEqualTo: documentNumber.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking document existence: $e');
      return false;
    }
  }

  Future<bool> checkAccountIdentifierExists(AccountType accountType, String identifier) async {
    try {
      String fieldName;
      switch (accountType) {
        case AccountType.nequi:
          fieldName = 'nequiPhoneNumber';
          break;
        case AccountType.savingsHand:
          fieldName = 'savingsHandAccountNumber';
          break;
        case AccountType.savingsAccount:
          fieldName = 'savingsAccountNumber';
          break;
      }
      
      final query = await _firestore
          .collection('users')
          .where(fieldName, isEqualTo: identifier.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking account identifier existence: $e');
      return false;
    }
  }

  Future<UserModel?> _findUserByAccountIdentifier(AccountType accountType, String identifier) async {
    try {
      QuerySnapshot querySnapshot;
      
      switch (accountType) {
        case AccountType.nequi:
          querySnapshot = await _firestore
              .collection('users')
              .where('nequiPhoneNumber', isEqualTo: identifier.trim())
              .where('nequiEnabled', isEqualTo: true)
              .limit(1)
              .get();
          break;
        case AccountType.savingsHand:
          querySnapshot = await _firestore
              .collection('users')
              .where('savingsHandAccountNumber', isEqualTo: identifier.trim())
              .where('savingsHandEnabled', isEqualTo: true)
              .limit(1)
              .get();
          break;
        case AccountType.savingsAccount:
          querySnapshot = await _firestore
              .collection('users')
              .where('savingsAccountNumber', isEqualTo: identifier.trim())
              .where('savingsAccountEnabled', isEqualTo: true)
              .limit(1)
              .get();
          break;
      }

      if (querySnapshot.docs.isEmpty) return null;

      return UserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error finding user by account identifier: $e');
      return null;
    }
  }

  bool _isAccountTypeEnabled(UserModel userModel, AccountType accountType) {
    switch (accountType) {
      case AccountType.nequi:
        return userModel.nequiEnabled;
      case AccountType.savingsHand:
        return userModel.savingsHandEnabled;
      case AccountType.savingsAccount:
        return userModel.savingsAccountEnabled;
    }
  }

  Future<UserModel> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) throw Exception('Usuario no encontrado.');
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  // ========== MANEJO DE INTENTOS FALLIDOS ==========

  Future<void> _incrementFailedAttempts(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return;
      
      UserModel user = UserModel.fromFirestore(doc);
      int newAttempts = user.failedLoginAttempts + 1;
      
      Map<String, dynamic> updateData = {
        'failedLoginAttempts': newAttempts,
      };

      if (newAttempts >= 3) {
        updateData['isBlocked'] = true;
        updateData['blockedUntil'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 15))
        );
      }

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      print('Error incrementing failed attempts: $e');
    }
  }

  Future<void> _resetFailedAttempts(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'failedLoginAttempts': 0,
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error resetting failed attempts: $e');
    }
  }

  Future<void> _unblockUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isBlocked': false,
        'blockedUntil': null,
        'failedLoginAttempts': 0,
      });
    } catch (e) {
      print('Error unblocking user: $e');
    }
  }

  // ========== LOGOUT ==========

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // ========== MANEJO DE ERRORES ==========

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña generada es muy débil.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'user-not-found':
        return 'No se encontró usuario con estos datos.';
      case 'wrong-password':
        return 'Credenciales de acceso incorrectas.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada por el administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta nuevamente en unos minutos.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al soporte técnico.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet.';
      case 'invalid-credential':
        return 'Las credenciales de autenticación han expirado o son inválidas.';
      default:
        print('Firebase Auth Error: ${e.code} - ${e.message}');
        return 'Error de autenticación. Intenta nuevamente o contacta al soporte.';
    }
  }
}