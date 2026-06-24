import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';

/// Orchestrates job execution state: status transitions, elapsed timer, and
/// checklist updates with optimistic local updates via [JobRepository].
class JobStatusController extends ChangeNotifier {
  JobStatusController({
    required Job initialJob,
    required JobRepository repository,
  })  : _job = initialJob,
        _repository = repository {
    if (_job.status == JobStatus.inProgress) {
      _resumeTimerFromStartTime();
    }
  }

  final JobRepository _repository;
  Job _job;
  bool _isLoading = false;
  StreamSubscription<Duration>? _timerSubscription;
  Duration _elapsed = Duration.zero;

  Job get job => _job;
  bool get isLoading => _isLoading;
  Duration get elapsed => _elapsed;

  Stream<Duration> get elapsedStream => _elapsedController.stream;
  final _elapsedController = StreamController<Duration>.broadcast();

  static const pauseReasons = [
    'Waiting for parts',
    'Customer approval needed',
    'Bay unavailable',
    'Technical issue',
  ];

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _emitElapsed(Duration value) {
    _elapsed = value;
    _elapsedController.add(value);
    notifyListeners();
  }

  String _formatClock(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  void _resumeTimerFromStartTime() {
    final parsed = _parseStartTime(_job.startTime);
    _startTimer(parsed ?? DateTime.now());
  }

  DateTime? _parseStartTime(String value) {
    if (value == '-' || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  void _startTimer(DateTime startedAt) {
    _timerSubscription?.cancel();
    _emitElapsed(DateTime.now().difference(startedAt));
    _timerSubscription = Stream.periodic(const Duration(seconds: 1), (_) {
      return DateTime.now().difference(startedAt);
    }).listen(_emitElapsed);
  }

  void _stopTimer() {
    _timerSubscription?.cancel();
    _timerSubscription = null;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String get formattedElapsed => _formatDuration(_elapsed);

  Future<void> startJob() async {
    if (_job.status == JobStatus.inProgress) return;

    final now = DateTime.now();
    final historyEntry = JobHistoryEntry(
      action: 'started',
      timestamp: now,
    );

    _job = _job.copyWith(
      status: JobStatus.inProgress,
      startTime: _formatClock(now),
      history: [..._job.history, historyEntry],
    );
    _startTimer(now);
    notifyListeners();

    _setLoading(true);
    try {
      await _repository.updateJobStatus(
        _job.id,
        JobStatus.inProgress.apiName,
        historyEntry: historyEntry,
      );
    } catch (e) {
      _stopTimer();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeJob() async {
    if (_job.status == JobStatus.completed) return;

    final now = DateTime.now();
    _stopTimer();

    _job = _job.copyWith(
      status: JobStatus.completed,
      actualEnd: _formatClock(now),
      history: [
        ..._job.history,
        JobHistoryEntry(action: 'completed', timestamp: now),
      ],
    );
    notifyListeners();

    _setLoading(true);
    try {
      await _repository.completeJob(_job.id);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pauseJob(String reason) async {
    if (_job.status != JobStatus.inProgress) return;

    _stopTimer();
    final historyEntry = JobHistoryEntry(
      action: 'paused',
      timestamp: DateTime.now(),
      note: reason,
    );

    _job = _job.copyWith(
      status: JobStatus.onHold,
      history: [..._job.history, historyEntry],
    );
    notifyListeners();

    _setLoading(true);
    try {
      await _repository.pauseJob(
        _job.id,
        JobStatus.onHold,
        pauseReason: reason,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resumeJob() async {
    if (_job.status != JobStatus.onHold && _job.status != JobStatus.pending) {
      return;
    }
    await startJob();
  }

  Future<void> toggleStep(JobStep step, bool isCompleted) async {
    final completedAt = isCompleted ? DateTime.now() : null;
    final updatedSteps = _job.steps
        .map(
          (item) => item.id == step.id
              ? item.copyWith(
                  isCompleted: isCompleted,
                  completedAt: completedAt,
                  clearCompletedAt: !isCompleted,
                )
              : item,
        )
        .toList();

    _job = _job.copyWith(steps: updatedSteps);
    notifyListeners();

    _setLoading(true);
    try {
      await _repository.toggleJobStep(_job.id, step.id, isCompleted);
    } catch (e) {
      final revertedSteps = _job.steps
          .map(
            (item) => item.id == step.id
                ? item.copyWith(
                    isCompleted: !isCompleted,
                    clearCompletedAt: isCompleted,
                  )
                : item,
          )
          .toList();
      _job = _job.copyWith(steps: revertedSteps);
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _elapsedController.close();
    super.dispose();
  }
}
