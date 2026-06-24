import 'dart:convert';
import '../auth/session_store.dart';
import 'job_status.dart';
import 'vehicle.dart';

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
    this.subTotal = 0,
    this.gst = 0,
    this.grandTotal = 0,
    this.createdAt,
  });

  final String id;
  final String? technicianId;
  final String? vehicleId;
  final String? bayId;
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

    final statusStr = json['status']?.toString() ?? 'Estimate';
    
    String rawJobNumber = json['idx']?.toString() ?? json['job_number']?.toString() ?? json['jobNumber']?.toString() ?? json['id']?.toString() ?? '';
    if (rawJobNumber.length >= 36 && rawJobNumber.contains('-')) {
      rawJobNumber = '#${rawJobNumber.substring(0, 8).toUpperCase()}';
    }

    String parsedTechnician = json['technician'] as String? ?? json['technician_name'] as String? ?? json['technician_id'] as String? ?? json['technicianId'] as String? ?? '';
    if (parsedTechnician.length >= 36 && parsedTechnician == SessionStore.currentUser?.id) {
      parsedTechnician = SessionStore.currentUser?.name ?? parsedTechnician;
    }

    return Job(
      id: json['id']?.toString() ?? '',
      technicianId: json['technician_id']?.toString() ?? json['technicianId']?.toString(),
      vehicleId: json['vehicle_id']?.toString() ?? json['vehicleId']?.toString() ?? '',
      bayId: json['bay_id']?.toString() ?? json['bayId']?.toString(),
      vehicle: vehicle,
      createdAt: createdAtDate,
      jobNumber: rawJobNumber,
      customerName: json['customer_name'] as String? ?? json['customerName'] as String? ?? vehicle?.customerName ?? 'Customer',
      mobile: json['mobile'] as String? ?? json['contact'] as String? ?? vehicle?.mobile ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? json['model'] as String? ?? vehicle?.vehicleModel ?? 'Unknown Vehicle',
      vehicleNumber: json['vehicle_number'] as String? ?? json['vehicleReg'] as String? ?? vehicle?.vehicleNumber ?? 'N/A',
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
        'status': status.name,
        'time': time,
        'date': date,
        'technician': technician,
        'start_time': startTime,
        'expected_end': expectedEnd,
        'actual_end': actualEnd,
        'delay': delay,
        'remarks': remarks,
        'services': services.map((e) => e.toJson()).toList(),
        'sub_total': subTotal,
        'gst': gst,
        'grand_total': grandTotal,
      };
}
