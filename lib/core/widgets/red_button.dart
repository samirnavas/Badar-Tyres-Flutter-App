import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Primary call-to-action wrapping Material 3 [FilledButton] / [OutlinedButton].
/// Colors come from the global theme's [ColorScheme.primary].
class RedButton extends StatelessWidget {
  const RedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.uppercase = true,
  }) : _outlined = false;

  const RedButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.uppercase = true,
  }) : _outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final bool uppercase;
  final bool _outlined;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = _outlined ? colors.primary : colors.onPrimary;

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.base),
              ],
              Flexible(
                child: Text(
                  uppercase ? label.toUpperCase() : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final handler = isLoading ? null : onPressed;
    final button = _outlined
        ? OutlinedButton(
            onPressed: handler,
            child: content,
          )
        : FilledButton(
            onPressed: handler,
            child: content,
          );

    if (!expand) return button;
    return SizedBox(
      width: double.infinity,
      height: _height,
      child: button,
    );
  }
}
