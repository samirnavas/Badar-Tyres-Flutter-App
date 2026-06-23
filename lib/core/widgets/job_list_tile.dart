import 'package:flutter/material.dart';

import '../models/job_status.dart';
import '../theme/theme.dart';

export '../models/job_status.dart';

extension JobStatusVisuals on JobStatus {
  String get label => switch (this) {
        JobStatus.running => 'Running',
        JobStatus.completed => 'Completed',
        JobStatus.delayed => 'Delayed',
        JobStatus.pending => 'Pending',
        JobStatus.awaitingParts => 'Awaiting Parts',
        JobStatus.blocked => 'Blocked',
      };

  Color get color => switch (this) {
        JobStatus.running => AppStatusColors.running,
        JobStatus.completed => AppStatusColors.completed,
        JobStatus.delayed => AppStatusColors.delayed,
        JobStatus.pending => AppStatusColors.pending,
        JobStatus.awaitingParts => AppStatusColors.pending, // Or another color
        JobStatus.blocked => AppStatusColors.delayed, // Blocked uses red
      };

  IconData get icon => switch (this) {
        JobStatus.running => Icons.play_circle_outline,
        JobStatus.completed => Icons.check_circle_outline,
        JobStatus.delayed => Icons.schedule,
        JobStatus.pending => Icons.hourglass_empty,
        JobStatus.awaitingParts => Icons.inventory_2_outlined,
        JobStatus.blocked => Icons.error_outline,
      };
}

/// A rich job-card row for the Jobs list. Shows the job number, customer and
/// vehicle, status pill, scheduled time, assigned technician, and a timing
/// breakdown (Start / Exp. End / Actual End / Delay) separated by tonal
/// dividers.
///
/// Pass `null` for [actualEnd] / [delay] to render a "-" placeholder.
class JobListTile extends StatelessWidget {
  const JobListTile({
    super.key,
    required this.jobNumber,
    required this.customerName,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.status,
    required this.time,
    required this.date,
    required this.technician,
    required this.startTime,
    required this.expectedEnd,
    this.actualEnd,
    this.delay,
    this.onTap,
  });

  final String jobNumber;
  final String customerName;
  final String vehicleModel;
  final String vehicleNumber;
  final JobStatus status;

  /// Scheduled time, e.g. "11:30 AM".
  final String time;

  /// Display date, e.g. "15 MAY 2024".
  final String date;

  final String technician;
  final String startTime;
  final String expectedEnd;

  /// Actual end time; `null` renders as "-".
  final String? actualEnd;

  /// Delay readout, e.g. "45 Min" / "0 Min"; `null` renders as "-".
  final String? delay;

  final VoidCallback? onTap;



  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: context.colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const _TileDivider(),
              _buildTechnicianRow(context),
              const _TileDivider(),
              _buildTimingRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final muted = context.colors.secondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppStatusColors.tint(status.color),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(status.icon, color: status.color, size: 20),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.labelSm.copyWith(
                  letterSpacing: 0,
                  color: muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.titleSm,
              ),
              const SizedBox(height: 2),
              Text(
                '$vehicleModel • $vehicleNumber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typography.bodyMd.copyWith(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatusPill(status: status),
            const SizedBox(height: AppSpacing.base),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 13, color: muted),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: context.typography.bodyMd.copyWith(
                    fontSize: 13,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: context.typography.labelSm.copyWith(
                letterSpacing: 0,
                color: muted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicianRow(BuildContext context) {
    final muted = context.colors.secondary;
    return Row(
      children: [
        Text(
          'Technician',
          style: context.typography.bodyMd.copyWith(fontSize: 13, color: muted),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            technician,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.typography.bodyMd.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingRow(BuildContext context) {
    final muted = context.colors.secondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TimingCell(label: 'Start', value: startTime)),
        Expanded(child: _TimingCell(label: 'Exp. End', value: expectedEnd)),
        Expanded(child: _TimingCell(label: 'Actual End', value: actualEnd ?? '-')),
        Expanded(
          child: _TimingCell(
            label: 'Delay',
            value: delay ?? '-',
            valueColor: delay == null ? muted : status.color,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppStatusColors.tint(status.color),
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        status.label,
        style: context.typography.labelSm.copyWith(
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

class _TimingCell extends StatelessWidget {
  const _TimingCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.typography.labelSm.copyWith(
            letterSpacing: 0,
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.typography.bodyMd.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.gutter),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.colors.surfaceBright,
      ),
    );
  }
}