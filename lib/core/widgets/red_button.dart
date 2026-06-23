import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The primary call-to-action button: a solid industrial-red bar with
/// near-white uppercase text (e.g. "CREATE", "LOGIN"). Uses the design's
/// `primary-container` red (#C94242) — the high-contrast brand red — rather
/// than the lighter Material `primary` tone.
///
/// Use [RedButton.outlined] for the paired secondary action ("ADD SERVICE"):
/// a 1.5px red stroke on a transparent fill with red text.
///
/// Sizing is fixed to the spec: 52px tall, 8px radius, 24px horizontal padding.
///
/// ```dart
/// RedButton(label: 'Create', onPressed: _submit);
/// RedButton.outlined(label: 'Add Service', icon: Icons.add, onPressed: _add);
/// RedButton(label: 'Saving', onPressed: _submit, isLoading: true);
/// ```
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

  /// Optional leading icon (e.g. a plus for "Add Service").
  final IconData? icon;

  /// Replaces the content with a spinner and blocks taps.
  final bool isLoading;

  /// Stretch to the parent's full width (default true).
  final bool expand;

  /// Render [label] in upper case (default true).
  final bool uppercase;

  final bool _outlined;

  static const double _height = 52;
  static const _shape =
      RoundedRectangleBorder(borderRadius: AppRadius.brBase);

  @override
  Widget build(BuildContext context) {
    final Color fg =
        _outlined ? context.colors.primaryContainer : context.colors.onPrimaryContainer;

    final textStyle = context.typography.labelSm.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: fg,
    );

    final Widget content = isLoading
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
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: AppSpacing.base),
              ],
              Flexible(
                child: Text(
                  uppercase ? label.toUpperCase() : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ],
          );

    final VoidCallback? handler = isLoading ? null : onPressed;
    final button = _outlined ? _buildOutlined(context, handler, content) : _buildFilled(context, handler, content);

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildFilled(BuildContext context, VoidCallback? handler, Widget content) {
    return ElevatedButton(
      onPressed: handler,
      style: ElevatedButton.styleFrom(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        disabledBackgroundColor:
            context.colors.primaryContainer.withValues(alpha: 0.45),
        disabledForegroundColor:
            context.colors.onPrimaryContainer.withValues(alpha: 0.8),
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, _height),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: _shape,
      ),
      child: content,
    );
  }

  Widget _buildOutlined(BuildContext context, VoidCallback? handler, Widget content) {
    return OutlinedButton(
      onPressed: handler,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.primaryContainer,
        backgroundColor: Colors.transparent,
        disabledForegroundColor:
            context.colors.primaryContainer.withValues(alpha: 0.45),
        side: BorderSide(
          color: handler == null
              ? context.colors.primaryContainer.withValues(alpha: 0.45)
              : context.colors.primaryContainer,
          width: 1.5,
        ),
        minimumSize: const Size(0, _height),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: _shape,
      ),
      child: content,
    );
  }
}
