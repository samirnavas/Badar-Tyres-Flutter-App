import 'dart:convert';
import 'job_status.dart';

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
  });

  final String id;
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

  factory Job.fromJson(Map<String, dynamic> json) {
    List<dynamic> lineItems = [];
    if (json['line_items'] is String) {
      try {
        lineItems = jsonDecode(json['line_items'] as String) as List<dynamic>;
      } catch (_) {}
    } else if (json['line_items'] is List) {
      lineItems = json['line_items'] as List<dynamic>;
    }

    Map<String, dynamic>? meta;
    final List<JobService> parsedServices = [];

    for (var item in lineItems) {
      if (item is Map<String, dynamic>) {
        if (item['name'] == '__meta__') {
          meta = item['_meta'] as Map<String, dynamic>?;
        } else {
          parsedServices.add(JobService.fromJson(item));
        }
      }
    }

    final createdAt = json['created_at']?.toString() ?? '';
    final parsedDate = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';
    final parsedTime = createdAt.length >= 16 ? createdAt.substring(11, 16) : '';

    return Job(
      id: json['id']?.toString() ?? '',
      jobNumber: json['idx']?.toString() ?? json['job_number']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customer_name'] as String? ?? 'Customer',
      mobile: json['mobile'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? 'Vehicle',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      status: jobStatusFromName(json['status'] as String?),
      time: parsedTime.isNotEmpty ? parsedTime : (json['time'] as String? ?? ''),
      date: parsedDate.isNotEmpty ? parsedDate : (json['date'] as String? ?? ''),
      technician: json['technician'] as String? ?? json['technician_id'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '-',
      expectedEnd: json['expected_end'] as String? ?? '-',
      actualEnd: json['actual_end'] as String?,
      delay: json['delay'] as String?,
      remarks: json['remarks'] as String? ?? '',
      services: parsedServices.isNotEmpty ? parsedServices : ((json['services'] as List<dynamic>? ?? [])
          .map((e) => JobService.fromJson(e as Map<String, dynamic>))
          .toList()),
      subTotal: (meta?['subtotal'] as num?)?.toDouble() ?? (json['sub_total'] as num?)?.toDouble() ?? 0,
      gst: (meta?['total_tax'] as num?)?.toDouble() ?? (json['gst'] as num?)?.toDouble() ?? 0,
      grandTotal: (meta?['total_amount'] as num?)?.toDouble() ?? (json['grand_total'] as num?)?.toDouble() ?? 0,
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
