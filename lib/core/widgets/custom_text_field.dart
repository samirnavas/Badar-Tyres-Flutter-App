import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// The canonical Badar Tyres input field: an optional label sitting above a
/// rounded, filled text box with a muted placeholder and a 2px red focus
/// "glow". Supports prefix/suffix icons (e.g. a clock on the "Starting Time"
/// field), validation, multi-line, and read-only/tap-to-pick usage.
///
/// Padding is fixed to the design spec: 16px field padding, 8px label gap.
///
/// ```dart
/// CustomTextField(
///   label: 'Customer Name',
///   hint: 'Enter Full Name',
///   controller: nameController,
/// );
///
/// CustomTextField(
///   label: 'Starting Time',
///   hint: 'Time',
///   readOnly: true,
///   suffixIcon: Icons.schedule,
///   onTap: _pickTime,
/// );
/// ```
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.isRequired = false,
    this.autovalidateMode,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  /// Leading data-type cue icon (drawn at 2px-feeling weight via outlined set).
  final IconData? prefixIcon;

  /// Trailing icon, e.g. a clock for time pickers or an eye for passwords.
  final IconData? suffixIcon;

  /// Tap handler for [suffixIcon]. If null the icon is decorative.
  final VoidCallback? onSuffixTap;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  /// Tap on the whole field — handy with [readOnly] for pickers.
  final VoidCallback? onTap;

  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Appends a red asterisk to the label.
  final bool isRequired;

  final AutovalidateMode? autovalidateMode;

  static const _radius = AppRadius.brBase;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      cursorColor: context.colors.primary,
      style: context.typography.bodyMd.copyWith(color: context.colors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.typography.bodyMd.copyWith(color: context.colors.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: enabled
            ? context.colors.surfaceContainerHigh
            : context.colors.surfaceContainer,
        isDense: false,
        // Pixel-perfect: 16px internal padding all round.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterText: '',
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: context.colors.onSurfaceVariant),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                icon: Icon(suffixIcon, size: 20),
                color: context.colors.onSurfaceVariant,
                splashRadius: 20,
                onPressed: onSuffixTap,
              ),
        border: _border(context.colors.outlineVariant, 1),
        enabledBorder: _border(context.colors.outlineVariant, 1),
        disabledBorder: _border(context.colors.outlineVariant, 1),
        focusedBorder: _border(context.colors.primary, 2),
        errorBorder: _border(context.colors.error, 1.5),
        focusedErrorBorder: _border(context.colors.error, 2),
        errorStyle: context.typography.labelSm.copyWith(
          letterSpacing: 0,
          color: context.colors.error,
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(text: label!, isRequired: isRequired),
        const SizedBox(height: AppSpacing.base), // 8px label gap.
        field,
      ],
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: color, width: width),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.isRequired});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        style: context.typography.bodyMd.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.colors.onSurface,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: context.typography.bodyMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}
