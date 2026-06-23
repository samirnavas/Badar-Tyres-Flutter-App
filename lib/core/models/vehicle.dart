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

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        vehicleNumber: json['vehicleNumber'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        vehicleType: json['vehicleType'] as String? ?? 'Car',
        customerName: json['customerName'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        lastJobDate: json['lastJobDate'] as String? ?? '',
        lastJobId: json['lastJobId'] as String? ?? '',
      );
}
