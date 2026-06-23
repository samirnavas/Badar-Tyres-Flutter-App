/// Aggregate job counts shown on the dashboard metric cards.
class JobMetrics {
  const JobMetrics({
    required this.totalJobs,
    required this.running,
    required this.completed,
    required this.delayed,
    this.pending = 0,
  });

  final int totalJobs;
  final int running;
  final int completed;
  final int delayed;
  final int pending;

  static const empty = JobMetrics(
    totalJobs: 0,
    running: 0,
    completed: 0,
    delayed: 0,
  );

  factory JobMetrics.fromJson(Map<String, dynamic> json) => JobMetrics(
        totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
        running: (json['running'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        delayed: (json['delayed'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
      );
}
