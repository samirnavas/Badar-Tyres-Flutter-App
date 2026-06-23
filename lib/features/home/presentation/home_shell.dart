import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../job_card/presentation/create_job_card_screen.dart';
import 'dashboard_overview_screen.dart';
import 'more_screen.dart';
import 'vehicles_screen.dart';

/// The signed-in app shell. Owns the bottom navigation bar and the central
/// "Create Job" action, swapping between the four primary destinations
/// (Dashboard, Jobs, Vehicles, More) via an [IndexedStack] so each tab keeps
/// its scroll position and state.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _navIndex = widget.initialIndex;
  int _jobsRefreshTick = 0;

  /// The four navigable destinations, in bottom-bar order. The central
  /// "Create Job" button (nav index 2) is an action, not a destination.
  static const _navOrder = [0, 1, 3, 4];

  int get _stackIndex => _navOrder.indexOf(_navIndex);

  void _onNavTap(int navIndex) {
    if (navIndex == _navIndex) return;
    setState(() => _navIndex = navIndex);
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobCardScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _jobsRefreshTick++;
        _navIndex = 1; // Jump to the Jobs tab to show the new card.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _navIndex = 0);
      },
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: IndexedStack(
          index: _stackIndex,
          children: [
            DashboardOverviewScreen(
              onCreateJob: _openCreateJob,
              onViewJobs: () => _onNavTap(1),
            ),
            DashboardScreen(refreshTick: _jobsRefreshTick),
            const VehiclesScreen(),
            const MoreScreen(),
          ],
        ),
        bottomNavigationBar: _AppBottomBar(
          currentIndex: _navIndex,
          onTap: _onNavTap,
          onCreateJob: _openCreateJob,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar with the central promoted "Create Job" button.
// ---------------------------------------------------------------------------

class _AppBottomBar extends StatelessWidget {
  const _AppBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onCreateJob,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCreateJob;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: context.colors.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Dashboard',
                    selected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.work_outline,
                    activeIcon: Icons.work_rounded,
                    label: 'Jobs',
                    selected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  const Spacer(),
                  _NavItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car_rounded,
                    label: 'Vehicles',
                    selected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _NavItem(
                    icon: Icons.menu,
                    activeIcon: Icons.menu_open_rounded,
                    label: 'More',
                    selected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
              Positioned(
                top: -18,
                left: 0,
                right: 0,
                child: Center(child: _CreateJobButton(onTap: onCreateJob)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.primaryContainer : context.colors.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.typography.labelSm.copyWith(
                letterSpacing: 0,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateJobButton extends StatelessWidget {
  const _CreateJobButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: context.colors.primaryContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add,
                  color: context.colors.onPrimaryContainer, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Create Job',
          style: context.typography.labelSm.copyWith(
            letterSpacing: 0,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}