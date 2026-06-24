import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/models/job.dart';
import '../../../core/models/job_metrics.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/job_list_tile.dart';
import '../../../core/widgets/metric_card.dart';
import '../../job_card/presentation/job_card_preview_screen.dart';

/// The Jobs dashboard: summary metric cards, a sticky filter tab bar
/// (All Jobs / Running / Completed / Delayed), a search field, and the
/// filtered list of job cards — all backed by the mock REST API.
///
/// Hosted inside the app's `HomeShell`, which owns the bottom navigation and
/// the central "Create Job" action. Bumping [refreshTick] (e.g. after a job is
/// created elsewhere) triggers a reload of the metrics and job list.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.refreshTick = 0});

  final int refreshTick;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['All Jobs', 'In Progress', 'Completed', 'On Hold'];
  static const _statusParams = ['all', 'in_progress', 'completed', 'on_hold'];

  final JobRepository _repository = JobRepository();
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;

  JobMetrics _metrics = JobMetrics.empty;
  List<Job> _jobs = const [];
  bool _loadingMetrics = true;
  bool _loadingJobs = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadJobs();
    });
    _loadMetrics();
    _loadJobs();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _refreshAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() => _loadingMetrics = true);
    try {
      final metrics = await _repository.fetchMetrics();
      if (!mounted) return;
      setState(() => _metrics = metrics);
    } on ApiException {
      // Surfaced via the jobs error state; keep last-known metrics.
    } finally {
      if (mounted) setState(() => _loadingMetrics = false);
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loadingJobs = true;
      _error = null;
    });
    try {
      final jobs = await _repository.fetchJobs(
        status: _statusParams[_tabController.index],
        search: _query,
      );
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadMetrics(), _loadJobs()]);
  }

  void _onSearchChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadJobs);
  }

  String _metric(int value) =>
      (_loadingMetrics && _metrics.totalJobs == 0) ? '—' : '$value';

  @override
  Widget build(BuildContext context) {
    final isTech = SessionStore.currentUser?.role == 'Technician';

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: isTech
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
              title: const Text('Jobs'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.base),
              ],
            ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: RefreshIndicator(
          color: context.colors.primary,
          backgroundColor: context.colors.surfaceContainerHigh,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            slivers: [
            SliverToBoxAdapter(child: _buildMetrics()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorColor: context.colors.primaryContainer,
                  indicatorWeight: 2.5,
                  dividerColor: Colors.transparent,
                  labelColor: context.colors.primaryContainer,
                  unselectedLabelColor: context.colors.secondary,
                  labelStyle: context.typography.bodyMd
                      .copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: context.typography.bodyMd,
                  labelPadding:
                      const EdgeInsets.only(right: AppSpacing.stackLg),
                  tabs: [for (final t in _tabs) Tab(text: t)],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSearch()),
            _buildContent(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(message: _error!, onRetry: _refreshAll),
      );
    }
    if (_loadingJobs) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
        ),
      );
    }
    if (_jobs.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        0,
        AppSpacing.containerPadding,
        AppSpacing.stackLg,
      ),
      sliver: SliverList.separated(
        itemCount: _jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutter),
        itemBuilder: (context, i) {
          final j = _jobs[i];
          return JobListTile(
            jobNumber: j.jobNumber,
            customerName: j.customerName,
            vehicleModel: j.vehicleModel,
            vehicleNumber: j.vehicleNumber,
            status: j.status,
            time: j.time,
            date: j.date,
            technician: j.technician,
            startTime: j.startTime,
            expectedEnd: j.expectedEnd,
            actualEnd: j.actualEnd,
            delay: j.delay,
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobExecutionScreen(job: j),
                ),
              );
              if (context.mounted) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.base,
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.gutter,
        mainAxisSpacing: AppSpacing.gutter,
        childAspectRatio: 2.2,
        children: [
          MetricCard.totalJobs(value: _metric(_metrics.totalJobs)),
          MetricCard.running(value: _metric(_metrics.running)),
          MetricCard.completed(value: _metric(_metrics.completed)),
          MetricCard.delayed(value: _metric(_metrics.delayed)),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
      ),
      child: CustomTextField(
        controller: _searchController,
        hint: 'Enter Mobile Number or Vehicle Number',
        prefixIcon: Icons.search,
        keyboardType: TextInputType.text,
        onChanged: _onSearchChanged,
      ),
    );
  }
}

/// Pins the filter [TabBar] below the metric cards while the list scrolls.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate(this.tabBar);

  final TabBar tabBar;
  static const double _height = 50;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: tabBar),
          Divider(
            height: 1,
            thickness: 1,
            color: context.colors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: context.colors.secondary),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'No jobs found',
            style: context.typography.titleSm.copyWith(color: context.colors.secondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: context.colors.secondary),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'Unable to load jobs',
            style: context.typography.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            message,
            style: context.typography.bodyMd.copyWith(
              fontSize: 13,
              color: context.colors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
