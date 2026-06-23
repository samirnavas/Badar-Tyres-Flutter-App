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
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
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

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as String? ?? '',
        jobNumber: json['jobNumber'] as String? ?? json['id'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        vehicleNumber: json['vehicleNumber'] as String? ?? '',
        status: jobStatusFromName(json['status'] as String?),
        time: json['time'] as String? ?? '',
        date: json['date'] as String? ?? '',
        technician: json['technician'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '-',
        expectedEnd: json['expectedEnd'] as String? ?? '-',
        actualEnd: json['actualEnd'] as String?,
        delay: json['delay'] as String?,
        remarks: json['remarks'] as String? ?? '',
        services: (json['services'] as List<dynamic>? ?? [])
            .map((e) => JobService.fromJson(e as Map<String, dynamic>))
            .toList(),
        subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
        gst: (json['gst'] as num?)?.toDouble() ?? 0,
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      );
}
