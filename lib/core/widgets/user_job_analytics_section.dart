import 'package:flutter/material.dart';

import '../models/job_metrics.dart';
import '../repositories/job_repository.dart';
import '../theme/theme.dart';
import 'metric_card.dart';

/// Personal job metrics for the signed-in user, shown as a 2x2 grid.
class UserJobAnalyticsSection extends StatefulWidget {
  const UserJobAnalyticsSection({super.key});

  @override
  State<UserJobAnalyticsSection> createState() =>
      _UserJobAnalyticsSectionState();
}

class _UserJobAnalyticsSectionState extends State<UserJobAnalyticsSection> {
  final JobRepository _repository = JobRepository();
  JobMetrics _metrics = JobMetrics.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loading = true);
    try {
      final metrics = await _repository.fetchMetrics(global: false);
      if (!mounted) return;
      setState(() => _metrics = metrics);
    } catch (_) {
      // Keep last-known or empty metrics.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _metric(int value) =>
      (_loading && _metrics.totalJobs == 0) ? '—' : '$value';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Job Analytics',
          style: context.typography.titleSm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.gutter,
          mainAxisSpacing: AppSpacing.gutter,
          childAspectRatio: 2.15,
          children: [
            MetricCard.totalJobs(value: _metric(_metrics.totalJobs)),
            MetricCard.running(value: _metric(_metrics.running)),
            MetricCard.completed(value: _metric(_metrics.completed)),
            MetricCard.delayed(value: _metric(_metrics.delayed)),
          ],
        ),
      ],
    );
  }
}
