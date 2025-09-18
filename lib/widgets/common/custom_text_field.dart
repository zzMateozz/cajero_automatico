import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool isNumeric;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final Function(String)? onChanged;
  final String? documentType;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    this.validator,
    this.isPassword = false,
    this.isNumeric = false,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.documentType,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          // Clave única que fuerza la reconstrucción cuando cambia el tipo de documento
          key: ValueKey('${widget.label}_${widget.documentType}_${widget.maxLength}_${widget.isNumeric}'),
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword ? _obscureText : false,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          keyboardType: _getKeyboardType(),
          inputFormatters: _getInputFormatters(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  )
                : widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            errorMaxLines: 2,
            counterText: widget.maxLength != null ? null : '', // Oculta contador si no hay maxLength
          ),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    // Si se especifica un keyboardType personalizado, lo usa
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }
    
    // Para documentos específicos
    if (widget.documentType != null) {
      switch (widget.documentType) {
        case 'CC':
        case 'TI':
          return TextInputType.number;
        case 'CE':
        case 'PP':
          return TextInputType.text; // Alfanumérico
        default:
          return widget.isNumeric ? TextInputType.number : TextInputType.text;
      }
    }
    
    // Comportamiento por defecto
    return widget.isNumeric ? TextInputType.number : TextInputType.text;
  }

  List<TextInputFormatter> _getInputFormatters() {
    // Si hay formatters personalizados, los usa
    if (widget.inputFormatters != null) {
      return widget.inputFormatters!;
    }

    // Para campos de documento específicos
    if (widget.documentType != null) {
      switch (widget.documentType) {
        case 'CC':
        case 'TI':
          return [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxLength ?? 10),
          ];
        
        case 'CE':
          return [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toUpperCase(),
              );
            }),
            LengthLimitingTextInputFormatter(widget.maxLength ?? 12),
          ];
        
        case 'PP':
          return [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(
                text: newValue.text.toUpperCase(),
              );
            }),
            LengthLimitingTextInputFormatter(widget.maxLength ?? 12),
          ];
      }
    }

    // Para campos numéricos generales
    if (widget.isNumeric) {
      return [
        FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
        if (widget.maxLength != null) 
          LengthLimitingTextInputFormatter(widget.maxLength!),
      ];
    }
    
    // Para campos de email
    if (widget.keyboardType == TextInputType.emailAddress) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+-]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return newValue.copyWith(
            text: newValue.text.toLowerCase(),
          );
        }),
      ];
    }

    // Para campos de texto normales (nombres, apellidos)
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
      TextInputFormatter.withFunction((oldValue, newValue) {
        // Capitalizar primera letra de cada palabra
        String text = newValue.text;
        if (text.isNotEmpty) {
          text = text.split(' ').map((word) {
            if (word.isNotEmpty) {
              return word[0].toUpperCase() + word.substring(1).toLowerCase();
            }
            return word;
          }).join(' ');
        }
        return newValue.copyWith(text: text);
      }),
    ];
  }
}