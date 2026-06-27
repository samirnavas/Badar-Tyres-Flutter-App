import 'dart:convert';

import '../auth/session_store.dart';
import 'vehicle.dart';

/// Lifecycle state of a job card.
enum JobStatus { pending, inProgress, onHold, completed }

/// Parses an API status string into a [JobStatus].
JobStatus jobStatusFromName(String? name) => switch (name?.toLowerCase()) {
      'pending' || 'approved' || 'estimate' => JobStatus.pending,
      'in_progress' || 'in progress' || 'running' => JobStatus.inProgress,
      'on_hold' ||
      'on hold' ||
      'delayed' ||
      'awaiting_parts' ||
      'blocked' =>
        JobStatus.onHold,
      'completed' || 'closed' => JobStatus.completed,
      _ => JobStatus.pending,
    };

extension JobStatusApi on JobStatus {
  String get apiName => switch (this) {
        JobStatus.pending => 'pending',
        JobStatus.inProgress => 'in_progress',
        JobStatus.onHold => 'on_hold',
        JobStatus.completed => 'completed',
      };

  /// Values stored in the Supabase `jobs.status` column.
  String get supabaseName => switch (this) {
        JobStatus.pending => 'Approved',
        JobStatus.inProgress => 'In Progress',
        JobStatus.onHold => 'Approved',
        JobStatus.completed => 'Completed',
      };
}

/// A single checklist step on a job execution card.
class JobStep {
  const JobStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  factory JobStep.fromJson(Map<String, dynamic> json) => JobStep(
        id: json['id']?.toString() ?? json['step_id']?.toString() ?? '',
        title: json['title'] as String? ?? json['name'] as String? ?? '',
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      };

  JobStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return JobStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}

/// A timestamped event in the job's execution history.
class JobHistoryEntry {
  const JobHistoryEntry({
    required this.action,
    required this.timestamp,
    this.note,
  });

  final String action;
  final DateTime timestamp;
  final String? note;

  factory JobHistoryEntry.fromJson(Map<String, dynamic> json) => JobHistoryEntry(
        action: json['action'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'action': action,
        'timestamp': timestamp.toIso8601String(),
        if (note != null) 'note': note,
      };
}

/// A billable service / part on a job card.
class JobService {
  const JobService({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final String description;
  final double amount;
  final bool isCompleted;

  factory JobService.fromJson(Map<String, dynamic> json) => JobService(
        id: json['serviceId']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        amount: (json['unitPrice'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'amount': amount,
        'is_completed': isCompleted,
      };
}

/// A job card as returned by the API.
class Job {
  const Job({
    required this.id,
    this.technicianId,
    this.vehicleId,
    this.bayId,
    this.bayName,
    this.vehicle,
    required this.jobNumber,
    required this.customerName,
    required this.mobile,
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
    this.remarks = '',
    this.services = const [],
    this.steps = const [],
    this.history = const [],
    this.estimates = const [],
    this.technicianNotes = '',
    this.subTotal = 0,
    this.gst = 0,
    this.grandTotal = 0,
    this.createdAt,
  });

  final String id;
  final String? technicianId;
  final String? vehicleId;
  final String? bayId;
  final String? bayName;
  final Vehicle? vehicle;
  final String jobNumber;
  final String customerName;
  final String mobile;
  final String vehicleModel;
  final String vehicleNumber;
  final JobStatus status;
  final String time;
  final String date;
  final String technician;
  final String startTime;
  final String expectedEnd;
  final String? actualEnd;
  final String? delay;
  final String remarks;
  final List<JobService> services;
  final List<JobStep> steps;
  final List<JobHistoryEntry> history;
  final List<JobService> estimates;
  final String technicianNotes;
  final double subTotal;
  final double gst;
  final double grandTotal;
  final DateTime? createdAt;

  factory Job.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> lineItems = [];
    if (json['line_items'] is String) {
      try {
        final decoded = jsonDecode(json['line_items'] as String) as List;
        lineItems = List<Map<String, dynamic>>.from(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    } else if (json['line_items'] is List) {
      try {
        lineItems = List<Map<String, dynamic>>.from((json['line_items'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      } catch (_) {}
    }

    Map<String, dynamic>? meta;
    final List<JobService> parsedServices = [];

    for (var item in lineItems) {
      if (item['name'] == '__meta__') {
        meta = item['_meta'] is Map ? Map<String, dynamic>.from(item['_meta'] as Map) : null;
      } else {
        parsedServices.add(JobService.fromJson(item));
      }
    }

    final createdAtStr = json['created_at']?.toString() ?? '';
    final parsedDate = createdAtStr.length >= 10 ? createdAtStr.substring(0, 10) : '';
    final parsedTime = createdAtStr.length >= 16 ? createdAtStr.substring(11, 16) : '';
    final createdAtDate = createdAtStr.isNotEmpty ? DateTime.tryParse(createdAtStr) : null;

    final vehicle = json['vehicles'] != null
        ? Vehicle.fromJson(Map<String, dynamic>.from(json['vehicles'] as Map))
        : (json['vehicle'] != null ? Vehicle.fromJson(Map<String, dynamic>.from(json['vehicle'] as Map)) : null);

    final jobMake = json['vehicle_make'] as String? ?? '';
    final jobModel = json['vehicle_model'] as String? ?? '';
    final denormalizedModel = [jobMake, jobModel]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    final statusStr = json['status']?.toString() ?? 'pending';

    final parsedSteps = _parseSteps(json, parsedServices, meta);
    final parsedHistory = _parseHistory(json);
    
    String rawJobNumber = json['idx']?.toString() ?? json['job_number']?.toString() ?? json['jobNumber']?.toString() ?? json['id']?.toString() ?? '';
    if (rawJobNumber.length >= 36 && rawJobNumber.contains('-')) {
      rawJobNumber = '#${rawJobNumber.substring(0, 8).toUpperCase()}';
    }

    String parsedTechnician = json['technician'] as String? ?? json['technician_name'] as String? ?? json['technician_id'] as String? ?? json['technicianId'] as String? ?? '';
    if (parsedTechnician.length >= 36 && parsedTechnician == SessionStore.currentUser?.id) {
      parsedTechnician = SessionStore.currentUser?.name ?? parsedTechnician;
    }

    final bays = json['bays'];
    final parsedBayName = bays is Map
        ? bays['name'] as String?
        : json['bay_name'] as String? ?? json['bayName'] as String?;

    return Job(
      id: json['id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString() ?? json['technicianId']?.toString(),
      vehicleId: json['vehicle_id']?.toString() ?? json['vehicleId']?.toString() ?? '',
      bayId: json['bay_id']?.toString() ?? json['bayId']?.toString(),
      bayName: parsedBayName,
      vehicle: vehicle,
      createdAt: createdAtDate,
      jobNumber: rawJobNumber,
      customerName: json['customer_name'] as String? ??
          json['customerName'] as String? ??
          vehicle?.customerName ??
          'Customer',
      mobile: json['customer_phone'] as String? ??
          json['mobile'] as String? ??
          json['contact'] as String? ??
          vehicle?.mobile ??
          '',
      vehicleModel: denormalizedModel.isNotEmpty
          ? denormalizedModel
          : (json['vehicle_model'] as String? ??
              json['model'] as String? ??
              vehicle?.vehicleModel ??
              'Unknown Vehicle'),
      vehicleNumber: json['plate_number'] as String? ??
          json['vehicle_number'] as String? ??
          json['vehicleReg'] as String? ??
          vehicle?.vehicleNumber ??
          'N/A',
      status: jobStatusFromName(statusStr),
      time: parsedTime.isNotEmpty ? parsedTime : (json['time'] as String? ?? json['startingTime'] as String? ?? ''),
      date: parsedDate.isNotEmpty ? parsedDate : (json['date'] as String? ?? ''),
      technician: parsedTechnician,
      startTime: json['start_time'] as String? ?? json['startingTime'] as String? ?? '-',
      expectedEnd: json['expected_end'] as String? ?? json['expectedEnd'] as String? ?? '-',
      actualEnd: json['actual_end'] as String? ?? json['actualEnd'] as String? ?? '-',
      delay: json['delay'] as String? ?? '-',
      remarks: json['remarks'] as String? ?? '',
      services: parsedServices.isNotEmpty ? parsedServices : ((json['services'] as List<dynamic>? ?? [])
          .map((e) => JobService.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList()),
      steps: parsedSteps,
      history: parsedHistory,
      estimates: (json['estimates'] as List<dynamic>? ?? [])
          .map((e) => JobService.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      technicianNotes: json['technician_notes'] as String? ??
          json['technicianNotes'] as String? ??
          '',
      subTotal: (meta?['subtotal'] as num?)?.toDouble() ?? (json['sub_total'] as num?)?.toDouble() ?? (json['subTotal'] as num?)?.toDouble() ?? 0,
      gst: (meta?['total_tax'] as num?)?.toDouble() ?? (json['gst'] as num?)?.toDouble() ?? 0,
      grandTotal: (meta?['total_amount'] as num?)?.toDouble() ?? (json['grand_total'] as num?)?.toDouble() ?? (json['grandTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Job copyWith({
    String? id,
    String? technicianId,
    String? vehicleId,
    String? bayId,
    String? bayName,
    Vehicle? vehicle,
    String? jobNumber,
    String? customerName,
    String? mobile,
    String? vehicleModel,
    String? vehicleNumber,
    JobStatus? status,
    String? time,
    String? date,
    String? technician,
    String? startTime,
    String? expectedEnd,
    String? actualEnd,
    String? delay,
    String? remarks,
    List<JobService>? services,
    List<JobStep>? steps,
    List<JobHistoryEntry>? history,
    List<JobService>? estimates,
    String? technicianNotes,
    double? subTotal,
    double? gst,
    double? grandTotal,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      technicianId: technicianId ?? this.technicianId,
      vehicleId: vehicleId ?? this.vehicleId,
      bayId: bayId ?? this.bayId,
      bayName: bayName ?? this.bayName,
      vehicle: vehicle ?? this.vehicle,
      jobNumber: jobNumber ?? this.jobNumber,
      customerName: customerName ?? this.customerName,
      mobile: mobile ?? this.mobile,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      time: time ?? this.time,
      date: date ?? this.date,
      technician: technician ?? this.technician,
      startTime: startTime ?? this.startTime,
      expectedEnd: expectedEnd ?? this.expectedEnd,
      actualEnd: actualEnd ?? this.actualEnd,
      delay: delay ?? this.delay,
      remarks: remarks ?? this.remarks,
      services: services ?? this.services,
      steps: steps ?? this.steps,
      history: history ?? this.history,
      estimates: estimates ?? this.estimates,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      subTotal: subTotal ?? this.subTotal,
      gst: gst ?? this.gst,
      grandTotal: grandTotal ?? this.grandTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'job_number': jobNumber,
        'customer_name': customerName,
        'mobile': mobile,
        'vehicle_model': vehicleModel,
        'vehicle_number': vehicleNumber,
        'status': status.apiName,
        'time': time,
        'date': date,
        'technician': technician,
        'start_time': startTime,
        'expected_end': expectedEnd,
        'actual_end': actualEnd,
        'delay': delay,
        'remarks': remarks,
        'services': services.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        'history': history.map((e) => e.toJson()).toList(),
        'estimates': estimates.map((e) => e.toJson()).toList(),
        'technician_notes': technicianNotes,
        'sub_total': subTotal,
        'gst': gst,
        'grand_total': grandTotal,
      };
}

List<JobStep> _parseSteps(
  Map<String, dynamic> json,
  List<JobService> services,
  Map<String, dynamic>? meta,
) {
  final metaChecklist = meta?['checklist'];
  if (metaChecklist is List && metaChecklist.isNotEmpty) {
    return metaChecklist
        .map((e) => JobStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  final raw = json['steps'];
  if (raw is List && raw.isNotEmpty) {
    return raw
        .map((e) => JobStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  if (services.isNotEmpty) {
    return services
        .map(
          (service) => JobStep(
            id: service.id.isNotEmpty ? service.id : service.name,
            title: service.name.isNotEmpty ? service.name : service.description,
            isCompleted: service.isCompleted,
          ),
        )
        .toList();
  }

  return const [
    JobStep(id: 'inspect', title: 'Vehicle inspection'),
    JobStep(id: 'service', title: 'Perform service work'),
    JobStep(id: 'quality', title: 'Quality check'),
    JobStep(id: 'handover', title: 'Customer handover'),
  ];
}

List<JobHistoryEntry> _parseHistory(Map<String, dynamic> json) {
  final raw = json['history'] ?? json['job_history'];
  if (raw is! List) return const [];

  return raw
      .map(
        (e) => JobHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      )
      .toList();
}
