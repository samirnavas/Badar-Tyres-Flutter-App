/// A single billable service / part line item on a job card.
class ServiceItem {
  const ServiceItem({
    required this.name,
    required this.description,
    required this.amount,
  });

  final String name;
  final String description;
  final double amount;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'amount': amount,
      };
}
