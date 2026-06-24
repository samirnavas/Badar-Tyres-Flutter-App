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
    final manufacturer = json['manufacturer'] as String? ?? json['make'] as String?;
    final model = json['model'] as String?;
    final computedModel = [manufacturer, model].where((e) => e != null && e.trim().isNotEmpty).join(' ');

    final nestedCustomer = json['customers'];
    final customerMap = nestedCustomer is Map
        ? Map<String, dynamic>.from(nestedCustomer)
        : null;

    return Vehicle(
      vehicleNumber: json['plate_number'] as String? ??
          json['registration_number'] as String? ??
          json['vehicleNumber'] as String? ??
          'N/A',
      vehicleModel: computedModel.isNotEmpty
          ? computedModel
          : (json['vehicleModel'] as String? ?? 'Unknown Vehicle'),
      vehicleType: json['type'] as String? ?? json['vehicleType'] as String? ?? 'Car',
      customerName: json['customerName'] as String? ??
          json['customer_name'] as String? ??
          _customerNameFromJoin(customerMap ?? json) ??
          '',
      mobile: json['phone'] as String? ??
          json['mobile'] as String? ??
          json['customer_phone'] as String? ??
          (customerMap?['phone'] as String?) ??
          '',
      lastJobDate: json['lastJobDate'] as String? ?? '',
      lastJobId: json['lastJobId'] as String? ?? '',
    );
  }

  static String? _customerNameFromJoin(Map<String, dynamic> json) {
    final customers = json['customers'];
    if (customers is Map) {
      final first = customers['first_name'] as String? ?? '';
      final last = customers['last_name'] as String? ?? '';
      final name = [first, last].where((part) => part.trim().isNotEmpty && part != '-').join(' ');
      if (name.isNotEmpty) return name;
    }
    return null;
  }
}
