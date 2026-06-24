import 'package:flutter/material.dart';

import '../models/job_status.dart';
import '../theme/theme.dart';

export '../models/job_status.dart';

extension JobStatusVisuals on JobStatus {
  String get label => switch (this) {
        JobStatus.pending => 'Pending',
        JobStatus.inProgress => 'In Progress',
        JobStatus.onHold => 'On Hold',
        JobStatus.completed => 'Completed',
      };

  Color get color => switch (this) {
        JobStatus.pending => AppStatusColors.pending,
        JobStatus.inProgress => AppStatusColors.running,
        JobStatus.onHold => AppStatusColors.delayed,
        JobStatus.completed => AppStatusColors.completed,
      };

  IconData get icon => switch (this) {
        JobStatus.pending => Icons.hourglass_empty,
        JobStatus.inProgress => Icons.play_circle_outline,
        JobStatus.onHold => Icons.pause_circle_outline,
        JobStatus.completed => Icons.check_circle_outline,
      };
}

/// A rich job-card row for the Jobs list. Shows the job number, customer and
/// vehicle, status pill, scheduled time, and assigned technician.
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
    this.onStatusChange,
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
  final void Function(JobStatus)? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final muted = colors.onSurfaceVariant;
    final String regNum = vehicleNumber.trim();
    final String formattedVehicleNumber =
        (regNum.toUpperCase() == 'N/A' || regNum.isEmpty)
            ? 'Unregistered'
            : regNum;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    jobNumber,
                    style: context.typography.labelSm.copyWith(
                      letterSpacing: 0,
                      color: muted,
                    ),
                  ),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                '$vehicleModel • $formattedVehicleNumber',
                style: context.typography.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (customerName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  customerName,
                  style: context.typography.bodyMd.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technician',
                          style: context.typography.labelSm.copyWith(
                            letterSpacing: 0,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          technician,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: context.typography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
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
              ),
            ],
          ),
        ),
      ),
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