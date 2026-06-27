import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/workspace_header.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../job_card/presentation/create_job_card_screen.dart';
import '../../../core/auth/session_store.dart';
import '../../auth/presentation/login_screen.dart';
import 'dashboard_overview_screen.dart';
import 'more_screen.dart';
import 'technician_workspace_screen.dart';
import 'vehicles_screen.dart';
import '../../bays/presentation/bay_status_screen.dart';
import '../../settings/presentation/settings_screen.dart';

/// The signed-in app shell. Owns M3 [NavigationBar] tab switching and the
/// admin "Create Job" FAB, swapping destinations via [IndexedStack].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _navIndex = widget.initialIndex;
  int _jobsRefreshTick = 0;

  static const _adminNavOrder = [0, 1, 3, 4];
  static const _techNavOrder = [0, 1, 6, 5];

  List<int> get _navOrder {
    final isTech = SessionStore.currentUser?.role == 'Technician';
    return isTech ? _techNavOrder : _adminNavOrder;
  }

  int get _stackIndex {
    final index = _navOrder.indexOf(_navIndex);
    return index == -1 ? 0 : index;
  }

  void _onNavTap(int navIndex) {
    if (navIndex == _navIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _navIndex = navIndex);
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobCardScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _jobsRefreshTick++;
        _navIndex = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionStore.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    final isTech = user.role == 'Technician';

    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _navIndex = 0);
      },
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isTech) WorkspaceHeader(userName: user.name),
            Expanded(
              child: IndexedStack(
                index: _stackIndex,
                children: [
                  if (isTech)
                    const TechnicianWorkspaceScreen()
                  else
                    DashboardOverviewScreen(
                      onCreateJob: _openCreateJob,
                      onViewJobs: () => _onNavTap(1),
                    ),
                  DashboardScreen(refreshTick: _jobsRefreshTick),
                  if (!isTech) const VehiclesScreen(),
                  if (!isTech) const MoreScreen(),
                  if (isTech) const BayStatusScreen(),
                  if (isTech) const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _stackIndex,
          onDestinationSelected: (index) => _onNavTap(_navOrder[index]),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: isTech
              ? const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Workspace',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline),
                    selectedIcon: Icon(Icons.work_rounded),
                    label: 'Jobs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Bays',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ]
              : const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.work_outline),
                    selectedIcon: Icon(Icons.work_rounded),
                    label: 'Jobs',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.directions_car_outlined),
                    selectedIcon: Icon(Icons.directions_car_rounded),
                    label: 'Vehicles',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu),
                    selectedIcon: Icon(Icons.menu_open_rounded),
                    label: 'More',
                  ),
                ],
        ),
        floatingActionButton: isTech
            ? null
            : FloatingActionButton(
                onPressed: _openCreateJob,
                tooltip: 'Create Job',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
