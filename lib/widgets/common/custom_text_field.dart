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
  final String? documentType; // NUEVO: Para manejar el tipo de documento

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
    this.documentType, // NUEVO
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
          // CLAVE ÚNICA QUE INCLUYE EL TIPO DE DOCUMENTO PARA FORZAR REBUILD
          key: ValueKey('${widget.label}_${widget.maxLength}_${widget.documentType}'), 
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPassword ? _obscureText : false,
          enabled: widget.enabled,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType ?? 
            (widget.isNumeric ? TextInputType.number : TextInputType.text),
          inputFormatters: widget.inputFormatters ?? _getInputFormatters(),
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
          ),
        ),
      ],
    );
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (widget.isNumeric) {
      return [
        FilteringTextInputFormatter.digitsOnly,
        FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
      ];
    }
    
    if (widget.keyboardType == TextInputType.emailAddress) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+-]')),
        TextInputFormatter.withFunction(
          (oldValue, newValue) {
            return newValue.copyWith(
              text: newValue.text.toLowerCase(),
            );
          },
        ),
      ];
    }

    // Para campos de documento que pueden ser alfanuméricos
    if (widget.documentType != null && 
        (widget.documentType == 'CE' || widget.documentType == 'PP')) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        TextInputFormatter.withFunction(
          (oldValue, newValue) {
            return newValue.copyWith(
              text: newValue.text.toUpperCase(),
            );
          },
        ),
      ];
    }

    // Para campos de texto normales
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]')),
      TextInputFormatter.withFunction(
        (oldValue, newValue) {
          return newValue.copyWith(
            text: newValue.text.toUpperCase(),
          );
        },
      ),
    ];
  }
}