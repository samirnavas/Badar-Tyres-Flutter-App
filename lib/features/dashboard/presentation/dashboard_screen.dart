import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/session_store.dart';
import '../../../core/models/job.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/job_directory_list_tile.dart';
import '../../job_card/presentation/job_card_preview_screen.dart';

const _jobsStickyHeaderHeight = 120.0;

/// The Jobs directory: shop-wide search and status filters with assignment
/// visibility on each row. Hosted inside the app's `HomeShell`.
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

  List<Job> _jobs = const [];
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
    _loadJobs();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) _loadJobs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _loadingJobs = true;
      _error = null;
    });
    try {
      final jobs = await _repository.fetchAllJobs(
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

  Future<void> _handleStatusChange(Job job, JobStatus newStatus) async {
    setState(() {
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index == -1) return;

      var newStartTime = job.startTime;
      var newActualEnd = job.actualEnd;
      final now =
          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

      if (newStatus == JobStatus.inProgress &&
          job.status != JobStatus.inProgress) {
        if (job.startTime == '-') newStartTime = now;
      } else if (newStatus == JobStatus.completed) {
        newActualEnd = now;
      }

      final updated = [..._jobs];
      updated[index] = job.copyWith(
        status: newStatus,
        startTime: newStartTime,
        actualEnd: newActualEnd,
      );
      _jobs = updated;
    });

    try {
      if (newStatus == JobStatus.inProgress) {
        await _repository.startJob(job.id);
      } else if (newStatus == JobStatus.completed) {
        await _repository.completeJob(job.id);
      } else {
        await _repository.updateJobStatus(job.id, newStatus);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update job: $e')));
      await _loadJobs();
    }
  }

  void _onSearchChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadJobs);
  }

  void _onFilterTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    // Reserved for advanced job filter sheet.
  }

  TabBar _buildTabBar(BuildContext context) {
    final colors = context.colors;

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: AppBrand.badarRed,
        borderRadius: AppRadius.brBase,
      ),
      dividerColor: colors.outlineVariant,
      dividerHeight: 0,
      labelColor: Colors.white,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: context.typography.bodyMd.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: context.typography.bodyMd,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      tabs: [
        for (final t in _tabs)
          Tab(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Text(t),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTech = SessionStore.currentUser?.isTechnician ?? false;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: isTech ? _buildTechnicianBody(colors) : _buildAdminBody(colors),
      ),
    );
  }

  Widget _buildTechnicianBody(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JobsFilterHeader(
          tabBar: _buildTabBar(context),
          searchController: _searchController,
          onSearchChanged: _onSearchChanged,
          onFilterTap: _onFilterTap,
          compactTop: true,
        ),
        Expanded(
          child: RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.surfaceContainerHigh,
            onRefresh: _loadJobs,
            child: _buildJobsListView(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBody(ColorScheme colors) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            forceElevated: innerBoxIsScrolled,
            backgroundColor: colors.surface,
            surfaceTintColor: colors.surfaceTint,
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
            toolbarHeight: kToolbarHeight,
            collapsedHeight: kToolbarHeight,
            bottom: _JobsStickyHeader(
              tabBar: _buildTabBar(context),
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              onFilterTap: _onFilterTap,
            ),
          ),
        ),
      ],
      body: Builder(
        builder: (context) {
          return RefreshIndicator(
            color: colors.primary,
            backgroundColor: colors.surfaceContainerHigh,
            onRefresh: _loadJobs,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                ),
                _buildContent(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobsListView() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: _ErrorState(message: _error!, onRetry: _loadJobs),
          ),
        ],
      );
    }
    if (_loadingJobs) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            ),
          ),
        ],
      );
    }
    if (_jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 320, child: _EmptyState()),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.stackLg,
      ),
      itemCount: _jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutter),
      itemBuilder: (context, i) => _buildJobTile(_jobs[i]),
    );
  }

  Widget _buildJobTile(Job j) {
    return JobDirectoryListTile(
      key: ValueKey(j.id),
      jobNumber: j.jobNumber,
      customerName: j.customerName,
      vehicleModel: j.vehicleModel,
      vehicleNumber: j.vehicleNumber,
      status: j.status,
      time: j.time,
      date: j.date,
      technician: j.technician,
      bayName: j.bayName,
      startTime: j.startTime,
      expectedEnd: j.expectedEnd,
      actualEnd: j.actualEnd,
      delay: j.delay,
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => JobExecutionScreen(job: j)),
        );
        if (context.mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          _loadJobs();
        }
      },
      onStatusChange: (newStatus) => _handleStatusChange(j, newStatus),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(message: _error!, onRetry: _loadJobs),
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
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.stackLg,
      ),
      sliver: SliverList.separated(
        itemCount: _jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gutter),
        itemBuilder: (context, i) => _buildJobTile(_jobs[i]),
      ),
    );
  }
}

/// Search field and status tabs pinned at the top of the Jobs directory.
class _JobsStickyHeader extends StatelessWidget implements PreferredSizeWidget {
  const _JobsStickyHeader({
    required this.tabBar,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  final TabBar tabBar;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  @override
  Size get preferredSize => const Size.fromHeight(_jobsStickyHeaderHeight);

  @override
  Widget build(BuildContext context) {
    return _JobsFilterHeader(
      tabBar: tabBar,
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      onFilterTap: onFilterTap,
    );
  }
}

class _JobsFilterHeader extends StatelessWidget {
  const _JobsFilterHeader({
    required this.tabBar,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.compactTop = false,
  });

  final TabBar tabBar;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool compactTop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              compactTop ? 0 : AppSpacing.base,
              AppSpacing.containerPadding,
              AppSpacing.base,
            ),
            child: CustomTextField(
              controller: searchController,
              hint: 'Search vehicle, mobile, or job number',
              prefixIcon: Icons.search,
              suffixIcon: Icons.tune_rounded,
              onSuffixTap: onFilterTap,
              keyboardType: TextInputType.text,
              onChanged: onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerPadding,
              0,
              AppSpacing.containerPadding,
              AppSpacing.base,
            ),
            child: tabBar,
          ),
        ],
      ),
    );
  }
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
          Icon(Icons.inbox_outlined, size: 48, color: context.colors.secondary),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'No jobs found',
            style: context.typography.titleSm.copyWith(
              color: context.colors.secondary,
            ),
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
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: context.colors.secondary,
          ),
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
