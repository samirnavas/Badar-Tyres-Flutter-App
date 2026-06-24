import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/theme/theme.dart';

/// Compact queue row for pending jobs on the technician workspace.
class PendingJobTile extends StatelessWidget {
  const PendingJobTile({
    super.key,
    required this.job,
    required this.position,
    this.onTap,
    this.onStart,
  });

  final Job job;
  final int position;
  final VoidCallback? onTap;
  final VoidCallback? onStart;

  String _formatRegistration(String vehicleNumber) {
    final regNum = vehicleNumber.trim();
    if (regNum.toUpperCase() == 'N/A' || regNum.isEmpty) {
      return 'Unregistered';
    }
    return regNum;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSurfaceVariant;
    final registration = _formatRegistration(job.vehicleNumber);
    final dueLabel = job.expectedEnd != '-'
        ? 'Due ${job.expectedEnd}'
        : 'No due time';

    return Material(
      elevation: 0,
      color: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.stackMd,
            vertical: AppSpacing.gutter,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppStatusColors.tint(AppBrand.badarRed),
                child: Text(
                  '$position',
                  style: context.typography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.bodyMd.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.vehicleModel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.labelSm.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dueLabel,
                    style: context.typography.labelSm.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onStart != null) ...[
                    const SizedBox(height: 4),
                    IconButton(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: 'Start job',
                      style: IconButton.styleFrom(
                        backgroundColor: AppStatusColors.tint(
                          AppBrand.badarRed,
                        ),
                        foregroundColor: AppBrand.badarRed,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
