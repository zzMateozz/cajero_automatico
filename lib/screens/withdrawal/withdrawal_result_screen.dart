import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../utils/constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import '../home/home_screen.dart';

class WithdrawalResultScreen extends StatefulWidget {
  final UserModel user;
  final AccountType accountType;
  final TransactionModel transaction;
  final Map<int, int> billBreakdown;
  final double remainingBalance;
  final List<double> possibleWithdrawals;
  final String displayNumber;

  const WithdrawalResultScreen({
    Key? key,
    required this.user,
    required this.accountType,
    required this.transaction,
    required this.billBreakdown,
    required this.remainingBalance,
    required this.possibleWithdrawals,
    required this.displayNumber,
  }) : super(key: key);

  @override
  _WithdrawalResultScreenState createState() => _WithdrawalResultScreenState();
}

class _WithdrawalResultScreenState extends State<WithdrawalResultScreen> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isUpdatingBalance = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _updateUserBalance();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  Future<void> _updateUserBalance() async {
    setState(() => _isUpdatingBalance = true);
    
    try {
      // Actualizar el saldo en Firestore según el tipo de cuenta
      String balanceField;
      switch (widget.accountType) {
        case AccountType.nequi:
          balanceField = 'nequiBalance';
          break;
        case AccountType.savingsHand:
          balanceField = 'savingsHandBalance';
          break;
        case AccountType.savingsAccount:
          balanceField = 'savingsAccountBalance';
          break;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        balanceField: widget.remainingBalance,
        'todayWithdrawnAmount': FieldValue.increment(widget.transaction.amount),
        'todayTransactionCount': FieldValue.increment(1),
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      // Guardar la transacción
      await FirebaseFirestore.instance
          .collection('transactions')
          .add(widget.transaction.toMap());
          
    } catch (e) {
      print('Error actualizando balance: $e');
      await CustomAlertDialog.showErrorDialog(
        context,
        'Advertencia',
        'El retiro fue exitoso pero hubo un error actualizando tu saldo. Contacta al soporte si es necesario.',
      );
    } finally {
      setState(() => _isUpdatingBalance = false);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retiro Exitoso'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goToHome,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Color(0xFFF5F5F5)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSuccessHeader(),
                  const SizedBox(height: 20),
                  _buildTransactionSummary(),
                  const SizedBox(height: 20),
                  _buildBillBreakdown(),
                  const SizedBox(height: 20),
                  _buildBalanceInfo(),
                  const SizedBox(height: 20),
                  _buildPossibleWithdrawals(),
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

  Widget _buildSuccessHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'RETIRO EXITOSO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transacción completada',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                _formatDateTime(widget.transaction.date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
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
                      widget.accountType.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getAccountColor(),
                      ),
                    ),
                    Text(
                      'Número mostrado: ${widget.displayNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildSummaryRow('Monto retirado:', '\$${_formatCurrency(widget.transaction.amount)}', true),
          if (widget.accountType == AccountType.nequi && widget.transaction.authCode != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Código usado:', widget.transaction.authCode!, false),
          ],
        ],
      ),
    );
  }

  Widget _buildBillBreakdown() {
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
              const Icon(Icons.receipt_long, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Billetes dispensados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mostrar cada denominación con cantidad
          ...widget.billBreakdown.entries
              .where((entry) => entry.value > 0)
              .map((entry) => _buildBillRow(entry.key, entry.value))
              .toList(),
              
          if (widget.billBreakdown.isEmpty || 
              widget.billBreakdown.values.every((v) => v == 0)) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No se dispensaron billetes',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillRow(int denomination, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getBillColor(denomination),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '\$${_formatCurrency(denomination.toDouble())}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Billetes de \$${_formatCurrency(denomination.toDouble())}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x$quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
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
              const Icon(Icons.account_balance_wallet, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Información de saldo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow('Saldo anterior:', '\$${_formatCurrency(_getPreviousBalance())}', false),
          const SizedBox(height: 8),
          _buildSummaryRow('Monto retirado:', '-\$${_formatCurrency(widget.transaction.amount)}', false),
          const Divider(height: 24),
          _buildSummaryRow('Saldo actual:', '\$${_formatCurrency(widget.remainingBalance)}', true),
        ],
      ),
    );
  }

  Widget _buildPossibleWithdrawals() {
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
              const Icon(Icons.analytics, color: Color(0xFF2E7D32), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Próximos retiros posibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.possibleWithdrawals.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No hay retiros posibles con el saldo restante',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.possibleWithdrawals.take(8).map((amount) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '\$${_formatCurrency(amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            if (widget.possibleWithdrawals.length > 8) ...[
              const SizedBox(height: 8),
              Text(
                'Y ${widget.possibleWithdrawals.length - 8} montos más disponibles...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Realizar Otro Retiro',
          onPressed: () => Navigator.pop(context),
          backgroundColor: _getAccountColor(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _goToHome,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _getAccountColor()),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: Text(
            'Ir al Inicio',
            style: TextStyle(
              color: _getAccountColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 16 : 14,
            color: Colors.grey[600],
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: highlight ? const Color(0xFF2E7D32) : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  double _getPreviousBalance() {
    return widget.remainingBalance + widget.transaction.amount;
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
          child: const Icon(Icons.phone_android, color: Colors.purple, size: 24),
        );
      case AccountType.savingsHand:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.handshake, color: Colors.orange, size: 24),
        );
      case AccountType.savingsAccount:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.account_balance, color: Colors.blue, size: 24),
        );
    }
  }

  Color _getBillColor(int denomination) {
    switch (denomination) {
      case 100000:
        return Colors.red;
      case 50000:
        return Colors.pink;
      case 20000:
        return Colors.blue;
      case 10000:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          user: widget.user,
          accountType: widget.accountType,
        ),
      ),
      (route) => false,
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}