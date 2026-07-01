import 'package:flutter/material.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({
    super.key,
    required this.onCreateJob,
    required this.onViewJobs,
    required this.onRefresh,
  });

  final VoidCallback onCreateJob;
  final VoidCallback onViewJobs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Admin Metrics and Revenue Charts')),
            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
