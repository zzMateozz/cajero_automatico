import 'package:cajero_automatico/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_alert_dialog.dart';
import '../../widgets/common/custom_back_button.dart';

class RegisterScreen extends StatefulWidget {
  final AccountType accountType;

  const RegisterScreen({super.key, required this.accountType});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  
  // Controladores para campos básicos
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  // Controladores específicos por tipo de cuenta
  final _accountNumberController = TextEditingController();
  final _nequiPhoneController = TextEditingController();
  
  String _selectedDocumentType = 'CC';
  bool _isLoading = false;
  bool _acceptTerms = false;
  int _currentPage = 0;

  // Lista de páginas del formulario
  final List<Widget> _formPages = [];

  @override
  void initState() {
    super.initState();
    _initializeFormPages();
  }

  void _initializeFormPages() {
    _formPages.addAll([
      _buildPersonalInfoPage(),
      _buildAccountInfoPage(),
      _buildSecurityPage(),
    ]);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _accountNumberController.dispose();
    _nequiPhoneController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
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
              // Header con botón de regreso
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                      text: 'Volver al login',
                    ),
                  ],
                ),
              ),

              // Indicador de progreso
              _buildProgressIndicator(),

              // Contenido principal
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Título
                        _buildTitleSection(),

                        // Formulario de páginas
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            children: _formPages,
                          ),
                        ),

                        // Botones de navegación
                        _buildNavigationButtons(),
                      ],
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

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / _formPages.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 8),
          Text(
            'Paso ${_currentPage + 1} de ${_formPages.length}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Crear Nueva Cuenta',
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
              _getAccountIcon(),
              const SizedBox(width: 8),
              Text(
                widget.accountType.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Atrás
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Atrás'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          // Botón Siguiente/Registrar
          Expanded(
            child: CustomButton(
              text: _currentPage < _formPages.length - 1 ? 'Siguiente' : 'Crear Cuenta',
              onPressed: () => _handleNavigation(),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Personal'),
          const SizedBox(height: 16),

          CustomTextField(
            label: 'Correo electrónico',
            hintText: 'ejemplo@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              String error = ValidationService.getEmailError(value ?? '');
              return error.isEmpty ? null : error;
            },
            prefixIcon: const Icon(Icons.email),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Nombre',
                  hintText: 'Tu nombre',
                  controller: _firstNameController,
                  validator: (value){
                    String error = ValidationService.getNameError(value ?? '');
                    return error.isEmpty ? null : error;
                  },
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Apellido',
                  hintText: 'Tu apellido',
                  controller: _lastNameController,
                  validator: (value){
                    String error = ValidationService.getNameError(value ?? '');
                    return error.isEmpty ? null : error;
                  },
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: 'Teléfono personal',
            hintText: '3001234567',
            controller: _phoneController,
            isNumeric: true,
            maxLength: 10,
            validator: (value){
              String error = ValidationService.getPhoneError(value ?? '');
              return error.isEmpty ? null : error;
            },
            prefixIcon: const Icon(Icons.phone),
          ),
          const SizedBox(height: 20),

          // Documento
          Text(
            'Documento de identidad',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: AppConstants.documentTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                      // Limpiar el campo cuando cambia el tipo
                      _documentController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  key: ValueKey('document_$_selectedDocumentType'), // Clave única para recrear el widget
                  label: '',
                  hintText: _getDocumentHint(),
                  controller: _documentController,
                  isNumeric: _isDocumentNumeric(),
                  maxLength: _getDocumentMaxLength(),
                  documentType: _selectedDocumentType,
                  validator: (value) {
                    String error = ValidationService.getDocumentError(value ?? '', _selectedDocumentType);
                    return error.isEmpty ? null : error;
                  },
                  prefixIcon: const Icon(Icons.badge),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información de ${widget.accountType.title}'),
          const SizedBox(height: 16),

          ..._buildAccountSpecificFields(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSecurityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Seguridad'),
          const SizedBox(height: 16),

          CustomTextField(
            label: widget.accountType == AccountType.nequi 
                ? 'PIN de seguridad (4 dígitos)' 
                : 'PIN (4 dígitos)',
            hintText: '••••',
            controller: _pinController,
            isPassword: true,
            isNumeric: true,
            maxLength: 4,
            validator: (value) {
              String error = ValidationService.getPinError(value ?? '');
              return error.isEmpty ? null : error;
            },
            prefixIcon: const Icon(Icons.lock),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: 'Confirmar PIN',
            hintText: '••••',
            controller: _confirmPinController,
            isPassword: true,
            isNumeric: true,
            maxLength: 4,
            validator: (value) {
              String error = ValidationService.getPinError(value ?? '');
              return error.isEmpty ? null : error;
            },
            prefixIcon: const Icon(Icons.lock_outline),
          ),

          const SizedBox(height: 32),

          // Términos y condiciones
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() => _acceptTerms = value!);
                },
                activeColor: const Color(0xFF4CAF50),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _acceptTerms = !_acceptTerms);
                  },
                  child: Text(
                    'Acepto los términos y condiciones del servicio de cajero automático y autorizo el procesamiento de mis datos personales.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleNavigation() {
    if (_currentPage < _formPages.length - 1) {
      // Aquí forzamos la validación para que los errores aparezcan en rojo
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        CustomAlertDialog.showErrorDialog(
          context,
          'Campos inválidos',
          'Por favor, revisa los campos en rojo y corrige la información antes de continuar.',
        );
      }
    } else {
      _register();
    }
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
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

  List<Widget> _buildAccountSpecificFields() {
    switch (widget.accountType) {
      case AccountType.nequi:
        return [
          CustomTextField(
            label: 'Número de celular NEQUI',
            hintText: '3001234567',
            controller: _nequiPhoneController,
            isNumeric: true,
            maxLength: 10,
            validator: _validateNequiPhone,
            prefixIcon: const Icon(Icons.phone_android),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se mostrará como 11 dígitos agregando 0 al inicio',
                    style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                  ),
                ),
              ],
            ),
          ),
        ];

      case AccountType.savingsHand:
        return [
          CustomTextField(
            label: 'Número de cuenta Ahorro a la Mano',
            hintText: '03123456789',
            controller: _accountNumberController,
            isNumeric: true,
            maxLength: 11,
            validator: _validateSavingsHandAccount,
            prefixIcon: const Icon(Icons.handshake),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debe iniciar con 0 o 1, segundo dígito debe ser 3',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        ];

      case AccountType.savingsAccount:
        return [
          CustomTextField(
            label: 'Número de cuenta de ahorros',
            hintText: '12345678901',
            controller: _accountNumberController,
            isNumeric: true,
            maxLength: 11,
            validator: _validateSavingsAccount,
            prefixIcon: const Icon(Icons.account_balance),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Número de cuenta tradicional de 11 dígitos',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }



  String? _validateNequiPhone(String? value) {
    final error = ValidationService.getPhoneError(value ?? '');
    return error.isEmpty ? null : error;
  }

  String? _validateSavingsHandAccount(String? value) {
    final error = ValidationService.getSavingsHandError(value ?? '');
    return error.isEmpty ? null : error;
  }

  String? _validateSavingsAccount(String? value) {
    final error = ValidationService.getSavingsAccountError(value ?? '');
    return error.isEmpty ? null : error;
  }

  String? _validatePin(String? value) {
    final error = ValidationService.getPinError(value ?? '');
    return error.isEmpty ? null : error;
  }


  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Datos incompletos',
        'Por favor, corrige todos los campos marcados en rojo antes de continuar.',
      );
      return;
    }

    if (!_acceptTerms) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Términos requeridos',
        'Debes aceptar los términos y condiciones para continuar.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Llamar al servicio de autenticación
      final userModel = await _authService.registerUser(
        email: _emailController.text,
        fullName: _getFullName(),
        phoneNumber: _phoneController.text,
        documentType: _selectedDocumentType,
        documentNumber: _documentController.text,
        pin: _pinController.text,
        accountType: widget.accountType,
        nequiPhoneNumber: widget.accountType == AccountType.nequi ? _nequiPhoneController.text : null,
        savingsHandAccountNumber: widget.accountType == AccountType.savingsHand ? _accountNumberController.text : null,
        savingsAccountNumber: widget.accountType == AccountType.savingsAccount ? _accountNumberController.text : null,
      );

      await CustomAlertDialog.showSuccessDialog(
        context,
        '¡Cuenta creada exitosamente!',
        'Tu cuenta ${widget.accountType.title} ha sido creada. Ya puedes iniciar sesión.',
      );

      // Regresar al login
      Navigator.pop(context);
      
    } catch (e) {
      await CustomAlertDialog.showErrorDialog(
        context,
        'Error en el registro',
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

    int _getDocumentMaxLength() {
    switch (_selectedDocumentType) {
      case 'CC': // Cédula
      case 'TI': // Tarjeta de Identidad
        return 10;
      case 'CE': // Cédula de Extranjería
      case 'PP': // Pasaporte
        return 12;
      default:
        return 12;
    }
  }
  String _getDocumentHint() {
  switch (_selectedDocumentType) {
    case 'CC':
      return 'Ej: 12345678';
    case 'TI':
      return 'Ej: 98765432';
    case 'CE':
      return 'Ej: CE123456';
    case 'PP':
      return 'Ej: AB123456';
    default:
      return 'Número de documento';
  }
}

bool _isDocumentNumeric() {
  switch (_selectedDocumentType) {
    case 'CC':
    case 'TI':
      return true;
    case 'CE':
    case 'PP':
      return false; // Pueden tener letras
    default:
      return true;
  }
}

  String _getFullName() {
    return '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
  }
}