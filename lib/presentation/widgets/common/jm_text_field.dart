import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class JmTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onVoiceTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? initialValue;

  const JmTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onVoiceTap,
    this.onChanged,
    this.onEditingComplete,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.autofocus = false,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    Widget? trailing = suffixIcon;

    // Voice mic icon appended to every field unless suffixIcon already provided
    if (trailing == null && onVoiceTap != null) {
      trailing = IconButton(
        icon: const Icon(Icons.mic_rounded, color: AppColors.primary),
        onPressed: onVoiceTap,
        tooltip: 'Voice input',
      );
    }

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      focusNode: focusNode,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: trailing,
        counterText: '',
      ),
    );
  }
}
