import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/withdrawal_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import 'withdrawal_result_screen.dart';

class AuthCodeScreen extends StatefulWidget {
  final UserModel user;
  final AccountType accountType;
  final double amount;

  const AuthCodeScreen({
    Key? key,
    required this.user,
    required this.accountType,
    required this.amount,
  }) : super(key: key);

  @override
  _AuthCodeScreenState createState() => _AuthCodeScreenState();
}

class _AuthCodeScreenState extends State<AuthCodeScreen> {
  final _authCodeController = TextEditingController();
  
  String? _currentAuthCode;
  DateTime? _codeExpiryTime;
  Timer? _countdownTimer;
  Timer? _codeGenerationTimer;
  int _timeRemaining = 60;
  bool _isLoading = false;
  bool _hasGeneratedCode = false;

  @override
  void initState() {
    super.initState();
    _generateNewAuthCode();
  }

  @override
  void dispose() {
    _authCodeController.dispose();
    _countdownTimer?.cancel();
    _codeGenerationTimer?.cancel();
    super.dispose();
  }

  void _generateNewAuthCode() {
    setState(() {
      var codeData = WithdrawalService.generateNequiAuthCode();
      _currentAuthCode = codeData['code'];
      _codeExpiryTime = codeData['expiresAt'];
      _timeRemaining = 60;
      _hasGeneratedCode = true;
    });

    // Cancelar timers anteriores
    _countdownTimer?.cancel();
    _codeGenerationTimer?.cancel();

    // Iniciar countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        _generateNewAuthCode(); // Auto-generar nuevo código
      }
    });
  }

  Future<void> _processWithdrawal() async {
    if (_currentAuthCode == null || _codeExpiryTime == null) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Error',
        'No hay código de autorización válido.',
      );
      return;
    }

    String enteredCode = _authCodeController.text.trim();
    
    if (enteredCode.isEmpty) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Código requerido',
        'Por favor, ingresa el código de autorización.',
      );
      return;
    }

    if (enteredCode.length != 6) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Código inválido',
        'El código debe tener exactamente 6 dígitos.',
      );
      return;
    }

    // Validar código
    bool isValidCode = WithdrawalService.validateNequiAuthCode(
      enteredCode, 
      _currentAuthCode!, 
      _codeExpiryTime!
    );

    if (!isValidCode) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Código incorrecto',
        'El código ingresado es incorrecto o ha expirado.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Procesar retiro
      var result = WithdrawalService.processWithdrawal(
        user: widget.user,
        accountType: widget.accountType,
        amount: widget.amount,
        authCode: _currentAuthCode,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorización NEQUI'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.purpleAccent],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildAuthCodeCard(),
                const SizedBox(height: 20),
                _buildInputSection(),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
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
          const Icon(
            Icons.phone_android,
            size: 48,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            'Retiro NEQUI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Número: 0${widget.user.nequiPhoneNumber}',
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

  Widget _buildAuthCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _timeRemaining <= 10 ? Colors.red : Colors.purple,
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
                color: _timeRemaining <= 10 ? Colors.red : Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Código de Autorización',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _timeRemaining <= 10 ? Colors.red : Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Código actual
          if (_hasGeneratedCode && _currentAuthCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _timeRemaining <= 10 ? Colors.red.shade50 : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _timeRemaining <= 10 ? Colors.red : Colors.purple,
                ),
              ),
              child: Text(
                _currentAuthCode!,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: _timeRemaining <= 10 ? Colors.red : Colors.purple,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contador regresivo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _timeRemaining <= 10 ? Colors.red.shade100 : Colors.purple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Expira en $_timeRemaining segundos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _timeRemaining <= 10 ? Colors.red.shade700 : Colors.purple.shade700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Text(
            'Ingresa este código en el campo de abajo para autorizar el retiro',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
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
            'Ingresa el código de autorización',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: '',
            hintText: '123456',
            controller: _authCodeController,
            isNumeric: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            prefixIcon: const Icon(Icons.security),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa el código de autorización';
              }
              if (value.length != 6) {
                return 'El código debe tener 6 dígitos';
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
                    'El código se regenera automáticamente cada 60 segundos por seguridad',
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
          text: 'Autorizar Retiro',
          onPressed: _processWithdrawal,
          isLoading: _isLoading,
          backgroundColor: Colors.purple,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _generateNewAuthCode,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text(
            'Generar Nuevo Código',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}