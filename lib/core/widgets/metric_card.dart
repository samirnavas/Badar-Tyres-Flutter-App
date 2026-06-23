import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A compact dashboard summary card showing a single metric: an accent icon,
/// a muted label, and a large colored value (e.g. "Total Jobs — 45").
///
/// Designed to tile in a 2-column grid. Use the general constructor for custom
/// metrics, or the named constructors for the standard Badar Tyres metrics.
///
/// ```dart
/// GridView.count(
///   crossAxisCount: 2,
///   childAspectRatio: 2.4,
///   crossAxisSpacing: AppSpacing.gutter,
///   mainAxisSpacing: AppSpacing.gutter,
///   children: const [
///     MetricCard.totalJobs(value: '45'),
///     MetricCard.running(value: '18'),
///     MetricCard.completed(value: '20'),
///     MetricCard.delayed(value: '7'),
///   ],
/// );
/// ```
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  /// Total jobs — violet accent, clipboard icon.
  const MetricCard.totalJobs({
    super.key,
    required this.value,
    this.label = 'Total Jobs',
    this.onTap,
  })  : icon = Icons.assignment_outlined,
        accentColor = AppStatusColors.total;

  /// Running jobs — green accent, play icon.
  const MetricCard.running({
    super.key,
    required this.value,
    this.label = 'Running',
    this.onTap,
  })  : icon = Icons.play_circle_outline,
        accentColor = AppStatusColors.running;

  /// Completed jobs — blue accent, check icon.
  const MetricCard.completed({
    super.key,
    required this.value,
    this.label = 'Completed',
    this.onTap,
  })  : icon = Icons.check_circle_outline,
        accentColor = AppStatusColors.completed;

  /// Delayed jobs — red accent, clock icon.
  const MetricCard.delayed({
    super.key,
    required this.value,
    this.label = 'Delayed',
    this.onTap,
  })  : icon = Icons.schedule,
        accentColor = AppStatusColors.delayed;

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHigh,
      borderRadius: AppRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppStatusColors.tint(accentColor),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.bodyMd.copyWith(
                        fontSize: 13,
                        height: 1.1,
                        color: context.colors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.headlineMd.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
