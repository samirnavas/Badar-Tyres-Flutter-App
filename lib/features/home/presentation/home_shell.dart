import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/session_store.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/workspace_header.dart';
import '../../auth/presentation/login_screen.dart';
import '../../job_card/presentation/create_job_card_screen.dart';
import 'shell_nav_config.dart';

/// The signed-in app shell. Owns M3 [NavigationBar] tab switching and the
/// admin "Create Job" FAB, swapping destinations via [IndexedStack].
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late ShellTab _selectedTab;
  int _jobsRefreshTick = 0;

  ShellNavConfig get _navConfig {
    final user = SessionStore.currentUser!;
    return ShellNavConfig.fromUser(
      user,
      onCreateJob: _openCreateJob,
      onViewJobs: _openJobsTab,
      onRefreshPermissions: _refreshPermissions,
      jobsRefreshTick: _jobsRefreshTick,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedTab = _tabForInitialIndex(widget.initialIndex);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  ShellTab _tabForInitialIndex(int index) {
    final items = _navConfig.items;
    if (items.isEmpty) return ShellTab.dashboard;
    if (index < 0 || index >= items.length) return items.first.tab;
    return items[index].tab;
  }

  void _reconcileSelectedTab() {
    final items = _navConfig.items;
    if (items.isEmpty) return;
    if (_navConfig.indexForTab(_selectedTab) == -1) {
      _selectedTab = items.first.tab;
    }
  }

  Future<void> _refreshPermissions() async {
    try {
      await SessionStore.instance.refreshPermissions();
    } catch (_) {
      // Keep the cached session if the network request fails.
    }
    if (!mounted) return;
    _reconcileSelectedTab();
    setState(() {});
  }

  void _openJobsTab() {
    if (_navConfig.indexForRoute(AppRoutes.jobs) == null) return;
    _onNavTap(ShellTab.jobs);
  }

  void _onNavTap(ShellTab tab) {
    if (tab == _selectedTab) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = tab);
  }

  Future<void> _openCreateJob() async {
    final user = SessionStore.currentUser;
    if (user == null || !user.canAccess(AppRoutes.jobs)) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobCardScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _jobsRefreshTick++;
        if (_navConfig.indexForRoute(AppRoutes.jobs) != null) {
          _selectedTab = ShellTab.jobs;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionStore.instance,
      builder: (context, _) {
        final user = SessionStore.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        final navConfig = _navConfig;
        if (navConfig.items.isEmpty) {
          return Scaffold(
            backgroundColor: context.colors.surface,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'No mobile access',
                      style: context.typography.titleSm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      'Your role does not have any routes assigned for the mobile app. '
                      'Contact an administrator.',
                      style: context.typography.bodyMd.copyWith(
                        color: context.colors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        var activeTab = _selectedTab;
        if (navConfig.indexForTab(activeTab) == -1) {
          activeTab = navConfig.items.first.tab;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedTab != activeTab) {
              setState(() => _selectedTab = activeTab);
            }
          });
        }

        final safeIndex =
            navConfig.indexForTab(activeTab).clamp(0, navConfig.items.length - 1);

        return PopScope(
          canPop: safeIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() => _selectedTab = navConfig.items.first.tab);
          },
          child: Scaffold(
            backgroundColor: context.colors.surface,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (navConfig.showWorkspaceHeader)
                  WorkspaceHeader(
                    userName: user.name,
                    onSyncTap: _refreshPermissions,
                  ),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: [
                      for (final item in navConfig.items) item.screen,
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) =>
                  _onNavTap(navConfig.items[index].tab),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final item in navConfig.items) item.destination,
              ],
            ),
            floatingActionButton: navConfig.showCreateJobFab
                ? FloatingActionButton(
                    onPressed: _openCreateJob,
                    tooltip: 'Create Job',
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
        );
      },
    );
  }
}
