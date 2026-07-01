import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/models/user.dart';
import '../../bays/presentation/bay_status_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'dashboard_overview_screen.dart';
import 'more_screen.dart';
import 'technician_workspace_screen.dart';
import 'vehicles_screen.dart';
import '../../settings/presentation/settings_screen.dart';

enum ShellTab {
  dashboard,
  jobs,
  bays,
  vehicles,
  more,
  profile,
}

class ShellNavItem {
  const ShellNavItem({
    required this.tab,
    required this.route,
    required this.destination,
    required this.screen,
  });

  final ShellTab tab;
  final String route;
  final NavigationDestination destination;
  final Widget screen;
}

/// Builds bottom navigation from the signed-in user's route permissions.
class ShellNavConfig {
  const ShellNavConfig({
    required this.items,
    required this.overflowRoutes,
    required this.showWorkspaceHeader,
    required this.showCreateJobFab,
  });

  static const _maxNavItems = 4;

  final List<ShellNavItem> items;
  final List<String> overflowRoutes;
  final bool showWorkspaceHeader;
  final bool showCreateJobFab;

  int indexForTab(ShellTab tab) {
    return items.indexWhere((item) => item.tab == tab);
  }

  int? indexForRoute(String route) {
    final tab = _tabForRoute(route);
    if (tab == null) return null;
    final index = indexForTab(tab);
    return index == -1 ? null : index;
  }

  static ShellTab? _tabForRoute(String route) {
    return switch (route) {
      AppRoutes.dashboard => ShellTab.dashboard,
      AppRoutes.jobs => ShellTab.jobs,
      AppRoutes.bays => ShellTab.bays,
      AppRoutes.vehicles => ShellTab.vehicles,
      _ when AppRoutes.secondaryRoutes.contains(route) => ShellTab.more,
      _ => null,
    };
  }

  factory ShellNavConfig.fromUser(
    AuthUser user, {
    required VoidCallback onCreateJob,
    required VoidCallback onViewJobs,
    required Future<void> Function() onRefreshPermissions,
    required int jobsRefreshTick,
  }) {
    final permissions = user.permissions;
    final items = <ShellNavItem>[];
    final overflowRoutes = <String>[];

    final primaryRoutes = permissions.accessiblePrimaryRoutes;
    final navPrimaryRoutes = <String>[];
    for (final route in primaryRoutes) {
      if (navPrimaryRoutes.length < _maxNavItems - 1) {
        navPrimaryRoutes.add(route);
      } else {
        overflowRoutes.add(route);
      }
    }

    final useMoreTab = permissions.hasAnySecondaryRoute ||
        overflowRoutes.isNotEmpty ||
        navPrimaryRoutes.length >= _maxNavItems - 1;

    void addItem({
      required ShellTab tab,
      required String route,
      required NavigationDestination destination,
      required Widget screen,
    }) {
      items.add(
        ShellNavItem(
          tab: tab,
          route: route,
          destination: destination,
          screen: screen,
        ),
      );
    }

    for (final route in navPrimaryRoutes) {
      switch (route) {
        case AppRoutes.dashboard:
          addItem(
            tab: ShellTab.dashboard,
            route: route,
            destination: NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: user.isTechnician ? 'Workspace' : 'Dashboard',
            ),
            screen: user.isTechnician
                ? const TechnicianWorkspaceScreen()
                : DashboardOverviewScreen(
                    onCreateJob: onCreateJob,
                    onViewJobs: onViewJobs,
                    onRefresh: onRefreshPermissions,
                  ),
          );
        case AppRoutes.jobs:
          addItem(
            tab: ShellTab.jobs,
            route: route,
            destination: const NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'Jobs',
            ),
            screen: DashboardScreen(refreshTick: jobsRefreshTick),
          );
        case AppRoutes.bays:
          addItem(
            tab: ShellTab.bays,
            route: route,
            destination: const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Bays',
            ),
            screen: const BayStatusScreen(),
          );
        case AppRoutes.vehicles:
          addItem(
            tab: ShellTab.vehicles,
            route: route,
            destination: const NavigationDestination(
              icon: Icon(Icons.directions_car_outlined),
              selectedIcon: Icon(Icons.directions_car_rounded),
              label: 'Vehicles',
            ),
            screen: const VehiclesScreen(),
          );
      }
    }

    if (useMoreTab) {
      addItem(
        tab: ShellTab.more,
        route: AppRoutes.services,
        destination: const NavigationDestination(
          icon: Icon(Icons.menu),
          selectedIcon: Icon(Icons.menu_open_rounded),
          label: 'More',
        ),
        screen: MoreScreen(overflowRoutes: overflowRoutes),
      );
    } else {
      addItem(
        tab: ShellTab.profile,
        route: AppRoutes.dashboard,
        destination: const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
        screen: const SettingsScreen(),
      );
    }

    return ShellNavConfig(
      items: items,
      overflowRoutes: overflowRoutes,
      showWorkspaceHeader: user.isTechnician &&
          permissions.canAccess(AppRoutes.dashboard),
      showCreateJobFab:
          permissions.canAccess(AppRoutes.jobs) && !user.isTechnician,
    );
  }
}
