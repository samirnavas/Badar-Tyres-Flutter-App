class Vehicle {
  const Vehicle({
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleType,
    required this.customerName,
    required this.mobile,
    required this.lastJobDate,
    required this.lastJobId,
  });

  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleType;
  final String customerName;
  final String mobile;
  final String lastJobDate;
  final String lastJobId;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final manufacturer = json['manufacturer'] as String?;
    final model = json['model'] as String?;
    final computedModel = [manufacturer, model].where((e) => e != null && e.trim().isNotEmpty).join(' ');

    return Vehicle(
      vehicleNumber: json['registration_number'] as String? ?? json['vehicleNumber'] as String? ?? 'N/A',
      vehicleModel: computedModel.isNotEmpty ? computedModel : (json['vehicleModel'] as String? ?? 'Unknown Vehicle'),
      vehicleType: json['type'] as String? ?? json['vehicleType'] as String? ?? 'Car',
      customerName: json['customerName'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      lastJobDate: json['lastJobDate'] as String? ?? '',
      lastJobId: json['lastJobId'] as String? ?? '',
    );
  }
}
