class InspectionItem {
  final String system;
  final String condition;
  final String notes;
  final List<String> photoUrls;
  final bool isChecked;

  InspectionItem({
    required this.system,
    required this.condition,
    required this.notes,
    this.photoUrls = const [],
    this.isChecked = false,
  });

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      system: json['system'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Pending',
      notes: json['notes'] as String? ?? '',
      photoUrls: (json['photoUrls'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'system': system,
      'condition': condition,
      'notes': notes,
      'photoUrls': photoUrls,
      'isChecked': isChecked,
    };
  }

  InspectionItem copyWith({
    String? system,
    String? condition,
    String? notes,
    List<String>? photoUrls,
    bool? isChecked,
  }) {
    return InspectionItem(
      system: system ?? this.system,
      condition: condition ?? this.condition,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class InspectionReport {
  final String? id;
  final String jobId;
  final String technicianId;
  final String vehicleId;
  final String status;
  final List<InspectionItem> items;

  InspectionReport({
    this.id,
    required this.jobId,
    required this.technicianId,
    required this.vehicleId,
    required this.status,
    required this.items,
  });

  factory InspectionReport.fromJson(Map<String, dynamic> json) {
    return InspectionReport(
      id: json['id'] as String?,
      jobId: json['jobId'] as String? ?? '',
      technicianId: json['technicianId'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InspectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'jobId': jobId,
      'technicianId': technicianId,
      'vehicleId': vehicleId,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  /// Row payload for the Supabase `inspections` table.
  Map<String, dynamic> toSupabaseRow() {
    return {
      'job_id': jobId,
      'technician_id': technicianId,
      'vehicle_id': vehicleId,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory InspectionReport.fromSupabaseRow(Map<String, dynamic> json) {
    return InspectionReport(
      id: json['id'] as String?,
      jobId: json['job_id'] as String? ?? '',
      technicianId: json['technician_id'] as String? ?? '',
      vehicleId: json['vehicle_id'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InspectionItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
