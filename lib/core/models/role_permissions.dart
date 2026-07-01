import 'dart:convert';

import '../constants/app_routes.dart';

/// Parsed `permissions.routes` payload for a single role.
class RolePermissions {
  const RolePermissions(this.routes);

  final Set<String> routes;

  static const empty = RolePermissions(<String>{});

  bool get isAdmin => routes.contains('*');

  bool canAccess(String route) {
    if (isAdmin) return true;
    return routes.contains(route);
  }

  bool get canApplyDiscount => canAccess(AppRoutes.applyDiscount);

  bool get hasAnySecondaryRoute =>
      AppRoutes.secondaryRoutes.any(canAccess);

  List<String> get accessiblePrimaryRoutes =>
      AppRoutes.primaryNavRoutes.where(canAccess).toList(growable: false);

  List<String> get accessibleSecondaryRoutes =>
      AppRoutes.secondaryRoutes.where(canAccess).toList(growable: false);

  factory RolePermissions.fromDbValue(dynamic value) {
    if (value == null) return RolePermissions.empty;

    if (value is List) {
      return RolePermissions(value.map((e) => e.toString()).toSet());
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return RolePermissions.empty;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return RolePermissions(decoded.map((e) => e.toString()).toSet());
        }
      } catch (_) {
        return RolePermissions({trimmed});
      }
    }

    return RolePermissions.empty;
  }

  List<String> toJsonList() => routes.toList()..sort();

  factory RolePermissions.fromJsonList(List<dynamic> json) {
    return RolePermissions(json.map((e) => e.toString()).toSet());
  }
}
