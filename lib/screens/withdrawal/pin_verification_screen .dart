import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/withdrawal_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import 'withdrawal_result_screen.dart';

class PinVerificationScreen extends StatefulWidget {
  final UserModel user;
  final AccountType accountType;
  final double amount;

  const PinVerificationScreen({
    Key? key,
    required this.user,
    required this.accountType,
    required this.amount,
  }) : super(key: key);

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _attemptCount = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String _hashPin(String pin) {
    var bytes = utf8.encode(pin + "PIN_SALT_2024");
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _verifyPinAndProcess() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String enteredPin = _pinController.text.trim();
    
    // Verificar PIN
    String hashedEnteredPin = _hashPin(enteredPin);
    
    if (hashedEnteredPin != widget.user.hashedPin) {
      _attemptCount++;
      
      if (_attemptCount >= 3) {
        await CustomAlertDialog.showErrorDialog(
          context,
          'Cuenta bloqueada',
          'Has excedido el número máximo de intentos. Tu cuenta ha sido bloqueada temporalmente.',
        );
        Navigator.pop(context);
        return;
      }
      
      await CustomAlertDialog.showErrorDialog(
        context,
        'PIN incorrecto',
        'El PIN ingresado es incorrecto. Intentos restantes: ${3 - _attemptCount}',
      );
      
      _pinController.clear();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Procesar retiro
      var result = WithdrawalService.processWithdrawal(
        user: widget.user,
        accountType: widget.accountType,
        amount: widget.amount,
        pin: enteredPin,
      );

      if (result['success']) {
        // Navegar a pantalla de resultado
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WithdrawalResultScreen(
              user: widget.user,
              accountType: widget.accountType,
              transaction: result['transaction'],
              billBreakdown: Map<int, int>.from(result['billBreakdown']),
              remainingBalance: result['remainingBalance'],
              possibleWithdrawals: List<double>.from(result['possibleWithdrawals']),
              displayNumber: result['displayNumber'],
            ),
          ),
        );
      } else {
        await CustomAlertDialog.showErrorDialog(
          context,
          'Error en el retiro',
          result['message'],
        );
      }
    } catch (e) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Error inesperado',
        'Ocurrió un error procesando el retiro: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = _getAccountColor();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificación ${widget.accountType.title}'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.7)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildSecurityCard(),
                  const SizedBox(height: 20),
                  _buildPinInputSection(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _getAccountIcon(),
          const SizedBox(height: 16),
          Text(
            widget.accountType.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getAccountColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuenta: ${_getDisplayAccountNumber()}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monto: \$${_formatCurrency(widget.amount)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _attemptCount > 0 ? Colors.orange : _getAccountColor(),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                color: _attemptCount > 0 ? Colors.orange : _getAccountColor(),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Verificación de Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _attemptCount > 0 ? Colors.orange : _getAccountColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Ingresa tu PIN de 4 dígitos para autorizar el retiro',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_attemptCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Intentos fallidos: $_attemptCount/3',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinInputSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIN de seguridad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: '',
            hintText: '••••',
            controller: _pinController,
            isPassword: true,
            isNumeric: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(Icons.lock),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa tu PIN de seguridad';
              }
              if (value.length != 4) {
                return 'El PIN debe tener exactamente 4 dígitos';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este es el mismo PIN que usas para iniciar sesión en tu cuenta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Verificar y Retirar',
          onPressed: _verifyPinAndProcess,
          isLoading: _isLoading,
          backgroundColor: _getAccountColor(),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  Color _getAccountColor() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return Colors.purple;
      case AccountType.savingsHand:
        return Colors.orange;
      case AccountType.savingsAccount:
        return Colors.blue;
    }
  }

  Widget _getAccountIcon() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.phone_android, size: 48, color: Colors.purple),
        );
      case AccountType.savingsHand:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.handshake, size: 48, color: Colors.orange),
        );
      case AccountType.savingsAccount:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance, size: 48, color: Colors.blue),
        );
    }
  }

  String _getDisplayAccountNumber() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return '0${widget.user.nequiPhoneNumber}';
      case AccountType.savingsHand:
        return widget.user.savingsHandAccountNumber ?? '';
      case AccountType.savingsAccount:
        return widget.user.savingsAccountNumber ?? '';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

}