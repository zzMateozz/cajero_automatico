import 'dart:async';
import 'package:cajero_automatico/screens/withdrawal/auth_code_screen%20.dart';
import 'package:cajero_automatico/screens/withdrawal/pin_verification_screen%20.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../../services/withdrawal_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import '../auth/account_type_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final AccountType accountType;

  const HomeScreen({
    super.key,
    required this.user,
    required this.accountType,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final _customAmountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Para código NEQUI
  String? _authCode;
  DateTime? _authCodeExpiry;
  Timer? _codeTimer;
  
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _startUserListener();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _codeTimer?.cancel();
    _userSubscription?.cancel();
    _userSubscription = null;
    super.dispose();
  }

  // Iniciar escucha de cambios en tiempo real del usuario
  void _startUserListener() {
    _userSubscription = _firestore
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUser = UserModel.fromFirestore(snapshot);
        });
      }
    }, onError: (error) {
      // Solo registrar errores si el widget todavía está montado
      if (mounted) {
        print("Error escuchando cambios del usuario: $error");
      }
    }, cancelOnError: true);
  }

  // Obtener el usuario efectivo (actualizado o inicial)
  UserModel get _effectiveUser {
    return _currentUser ?? widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAccountTitle()),
        backgroundColor: _getAccountColor(),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_getAccountColor(), const Color(0xFFF5F5F5)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 20),
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildWithdrawalOptions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
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
          Row(
            children: [
              _getAccountIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _effectiveUser.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getAccountColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getDisplayAccountNumber(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getAccountColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    double balance = _getCurrentBalance();
    
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
          Text(
            'Saldo disponible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_formatCurrency(balance)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Límite diario: \$${_formatCurrency(_effectiveUser.dailyWithdrawalLimit)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalOptions() {
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
            'Selecciona el monto a retirar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          
          // Montos fijos
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: AppConstants.fixedWithdrawalAmounts.map((amount) {
              bool canWithdraw = WithdrawalService.canDispenseAmount(amount) && 
                               amount <= _getCurrentBalance();
              return _buildAmountButton(amount, canWithdraw);
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // Monto personalizado
          const Text(
            'Otro monto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: '',
                  hintText: 'Monto (múltiplo de 10,000)',
                  controller: _customAmountController,
                  isNumeric: true,
                  prefixIcon: const Icon(Icons.attach_money),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // Limitar a 7 dígitos (máximo 9,999,999)
                      if (newValue.text.length > 7) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Retirar',
                width: 100,
                onPressed: () => _processWithdrawal(_getCustomAmount()),
                isLoading: _isLoading,
                backgroundColor: _getAccountColor(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          // Información importante
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Información importante:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '• Solo se dispensan billetes de \$10,000, \$20,000, \$50,000 y \$100,000\n'
                  '• El monto debe ser múltiplo de \$10,000\n'
                  '• Los montos que no sean dispensables aparecerán deshabilitados',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountButton(double amount, bool enabled) {
    return OutlinedButton(
      onPressed: enabled ? () => _processWithdrawal(amount) : null,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: enabled ? _getAccountColor() : Colors.grey.shade300,
        ),
        backgroundColor: enabled ? Colors.transparent : Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        '\$${_formatCurrency(amount)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled ? _getAccountColor() : Colors.grey.shade500,
        ),
      ),
    );
  }

  // Métodos principales
  void _generateAuthCode() {
    var codeData = WithdrawalService.generateNequiAuthCode();
    setState(() {
      _authCode = codeData['code'];
      _authCodeExpiry = codeData['expiresAt'];
    });
  }

  Future<void> _processWithdrawal(double amount) async {
    if (amount <= 0) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Monto inválido',
        'Por favor, ingresa un monto válido.',
      );
      return;
    }

    // Validar el monto
    var validation = WithdrawalService.validateWithdrawalAmount(
      amount, 
      _getCurrentBalance(), 
      _effectiveUser
    );

    if (!validation['isValid']) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Error en el monto',
        validation['message'],
      );
      return;
    }

    // Navegar al flujo correspondiente según el tipo de cuenta
    if (widget.accountType == AccountType.nequi) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthCodeScreen(
            user: _effectiveUser,
            accountType: widget.accountType,
            amount: amount,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinVerificationScreen(
            user: _effectiveUser,
            accountType: widget.accountType,
            amount: amount,
          ),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await CustomAlertDialog.showConfirmDialog(
      context,
      'Cerrar sesión',
      '¿Estás seguro de que deseas cerrar sesión?',
    );

    if (confirmed) {
      try {
        await _userSubscription?.cancel();
        await _authService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AccountTypeSelectionScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          await CustomAlertDialog.showErrorDialog(
            context,
            'Error',
            'No se pudo cerrar la sesión: ${e.toString()}',
          );
        }
      }
    }
  }

  // Métodos auxiliares
  String _getAccountTitle() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return 'NEQUI';
      case AccountType.savingsHand:
        return 'Ahorro a la Mano';
      case AccountType.savingsAccount:
        return 'Cuenta de Ahorros';
    }
  }

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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.phone_android, color: Colors.purple),
        );
      case AccountType.savingsHand:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.handshake, color: Colors.orange),
        );
      case AccountType.savingsAccount:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance, color: Colors.blue),
        );
    }
  }

  String _getDisplayAccountNumber() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return '0${_effectiveUser.nequiPhoneNumber}'; // Mostrar con 0 al inicio (11 dígitos)
      case AccountType.savingsHand:
        return _effectiveUser.savingsHandAccountNumber ?? '';
      case AccountType.savingsAccount:
        return _effectiveUser.savingsAccountNumber ?? '';
    }
  }

  double _getCurrentBalance() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return _effectiveUser.nequiBalance;
      case AccountType.savingsHand:
        return _effectiveUser.savingsHandBalance;
      case AccountType.savingsAccount:
        return _effectiveUser.savingsAccountBalance;
    }
  }

  double _getCustomAmount() {
    try {
      return double.parse(_customAmountController.text);
    } catch (e) {
      return 0;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}