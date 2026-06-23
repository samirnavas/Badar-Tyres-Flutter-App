class InspectionItem {
  final String system;
  final String condition;
  final String notes;
  final String? photoUrl;

  InspectionItem({
    required this.system,
    required this.condition,
    required this.notes,
    this.photoUrl,
  });

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      system: json['system'] as String? ?? '',
      condition: json['condition'] as String? ?? 'Green',
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'system': system,
      'condition': condition,
      'notes': notes,
      'photoUrl': photoUrl,
    };
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
}
