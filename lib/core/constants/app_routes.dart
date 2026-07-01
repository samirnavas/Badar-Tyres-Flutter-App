/// Route and action identifiers stored in the admin `permissions` table.
abstract final class AppRoutes {
  static const dashboard = '/dashboard';
  static const jobs = '/jobs';
  static const services = '/services';
  static const inventory = '/inventory';
  static const customers = '/customers';
  static const bays = '/bays';
  static const billing = '/billing';
  static const vehicles = '/vehicles';
  static const applyDiscount = 'action:apply_discount';

  /// Bottom-nav destinations shown when the matching route is granted.
  static const primaryNavRoutes = [
    dashboard,
    jobs,
    bays,
    vehicles,
  ];

  /// Secondary routes surfaced inside the More menu.
  static const secondaryRoutes = [
    services,
    inventory,
    customers,
    billing,
  ];
}
