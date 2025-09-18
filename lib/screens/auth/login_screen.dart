import 'package:cajero_automatico/screens/home/home_screen.dart';
import 'package:cajero_automatico/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import '../../widgets/common/custom_back_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AccountType accountType;

  const LoginScreen({super.key, required this.accountType});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _pinController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón de regreso - MEJORADO
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                        text: 'Cambiar cuenta',
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal - SOLUCIONADO EL OVERFLOW
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            
                            // Título del tipo de cuenta
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _getAccountImagen(),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          widget.accountType.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4CAF50),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.accountType.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Campo de cuenta/teléfono
                            CustomTextField(
                              label: _getAccountLabel(),
                              hintText: _getAccountHint(),
                              controller: _accountController,
                              isNumeric: true,
                              maxLength: _getMaxLength(),
                              validator: _validateAccount,
                              prefixIcon: Icon(_getAccountIcon().icon),
                            ),

                            const SizedBox(height: 20),

                            // Campo PIN - SIEMPRE ES DE 4 DÍGITOS PARA LOGIN
                            CustomTextField(
                              label: 'PIN (4 dígitos)',
                              hintText: 'Ingresa tu PIN de 4 dígitos',
                              controller: _pinController,
                              isPassword: true,
                              isNumeric: true,
                              maxLength: 4,
                              validator: _validatePin,
                              prefixIcon: const Icon(Icons.lock),
                            ),

                            const SizedBox(height: 28),

                            // Botón de login
                            CustomButton(
                              text: 'Iniciar Sesión',
                              onPressed: _login,
                              isLoading: _isLoading,
                            ),

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'o',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Botón de registro
                            OutlinedButton(
                              onPressed: () => _navigateToRegister(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF4CAF50)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: const Text(
                                'Crear Nueva Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Nota informativa
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getInfoText(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  Icon _getAccountIcon() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return const Icon(Icons.phone_android, color: Colors.purple);
      case AccountType.savingsHand:
        return const Icon(Icons.handshake, color: Colors.orange);
      case AccountType.savingsAccount:
        return const Icon(Icons.account_balance, color: Colors.blue);
    }
  }
  Widget _getAccountImagen({double size = 40}) {
  return Image.asset(
    widget.accountType.imagePath,
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
  }

  String _getAccountLabel() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return 'Número de celular';
      case AccountType.savingsHand:
        return 'Número de cuenta Ahorro a la Mano';
      case AccountType.savingsAccount:
        return 'Número de cuenta de ahorros';
    }
  }

  String _getAccountHint() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return 'Ej: 3001234567';
      case AccountType.savingsHand:
        return 'Ej: 03123456789';
      case AccountType.savingsAccount:
        return 'Ej: 12345678901';
    }
  }

  int _getMaxLength() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return 10;
      case AccountType.savingsHand:
      case AccountType.savingsAccount:
        return 11;
    }
  }

  String _getInfoText() {
  switch (widget.accountType) {
    case AccountType.nequi:
      return 'Tu PIN de 4 dígitos es para iniciar sesión.\nEl código de 6 dígitos solo se usa en retiros.';
    case AccountType.savingsHand:
      return 'Cuenta debe iniciar con 0 o 1, segundo dígito debe ser 3';
    case AccountType.savingsAccount:
      return 'Ingresa tu número de cuenta de ahorros de 11 dígitos';
  }
}

  String? _validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    // Limpiar el valor antes de validar
    final cleanedValue = ValidationService.cleanNumber(value);

    switch (widget.accountType) {
      case AccountType.nequi:
        final error = ValidationService.getPhoneError(cleanedValue);
        return error.isEmpty ? null : error;
      case AccountType.savingsHand:
        final error = ValidationService.getSavingsHandError(cleanedValue);
        return error.isEmpty ? null : error;
      case AccountType.savingsAccount:
        final error = ValidationService.getSavingsAccountError(cleanedValue);
        return error.isEmpty ? null : error;
    }
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es requerido';
    }

    // Siempre validar como PIN de 4 dígitos
    final error = ValidationService.getPinError(value);
    if (error.isNotEmpty) return error;

    return null;
  }

  Future<void> _login() async {
      try {
    // Limpiar los valores antes de enviarlos
    final cleanedAccount = ValidationService.cleanNumber(_accountController.text);
    final cleanedPin = _pinController.text;

    // Llamar al servicio de autenticación y ALMACENAR el resultado
    final userModel = await _authService.loginUser(
      accountType: widget.accountType,
      accountIdentifier: cleanedAccount,
      pin: cleanedPin,
    );

    // Login exitoso
    await CustomAlertDialog.showSuccessDialog(
      context,
      'Login exitoso',
      'Bienvenido a tu ${widget.accountType.title}',
    );

    // Navegar al HomeScreen (ahora userModel SÍ está definido)
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          user: userModel,
          accountType: widget.accountType,
        ),
      ),
    );
    
  } catch (e) {
    await CustomAlertDialog.showErrorDialog(
      context,
      'Error de autenticación',
      e.toString(),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(accountType: widget.accountType),
      ),
    );
  }
}