import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/models/vehicle.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../job_card/presentation/job_card_preview_screen.dart';

/// The "Vehicles" tab — a registry of customer vehicles.
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _repository = JobRepository();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Vehicle> _vehicles = [];
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final vehicles = await _repository.fetchVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openJob(String jobId) async {
    if (jobId.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final job = await _repository.fetchJob(jobId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JobExecutionScreen(job: job)),
      );
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      // Ignore or log error
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _repository.dispose();
    super.dispose();
  }

  List<Vehicle> get _filteredVehicles {
    if (_query.isEmpty) return _vehicles;
    final q = _query.toLowerCase();
    return _vehicles
        .where((v) =>
            v.vehicleNumber.toLowerCase().contains(q) ||
            v.customerName.toLowerCase().contains(q) ||
            v.vehicleModel.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          title: const Text('Vehicles'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: context.colors.error),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Failed to load vehicles',
                style: context.typography.titleSm.copyWith(color: context.colors.error),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.typography.bodyMd,
              ),
              const SizedBox(height: AppSpacing.stackLg),
              ElevatedButton(
                onPressed: _loadVehicles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.containerPadding, AppSpacing.stackMd, AppSpacing.containerPadding, 0),
              child: CustomTextField(
                controller: _searchController,
                prefixIcon: Icons.search,
                hint: 'Search vehicles...',
                onChanged: (val) => setState(() => _query = val),
              ),
            ),
          ),
          if (_vehicles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppStatusColors.tint(context.colors.primaryContainer),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 44,
                          color: context.colors.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        'No vehicles yet',
                        style: context.typography.titleSm.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        'Customer vehicles will appear here once job cards are created.',
                        textAlign: TextAlign.center,
                        style: context.typography.bodyMd.copyWith(
                          fontSize: 14,
                          color: context.colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_filteredVehicles.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No vehicles match your search.',
                  style: context.typography.bodyMd.copyWith(color: context.colors.secondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final vehicle = _filteredVehicles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                      child: _VehicleCard(
                        vehicle: vehicle,
                        onTap: () => _openJob(vehicle.lastJobId),
                      ),
                    );
                  },
                  childCount: _filteredVehicles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: context.colors.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHigh,
                  borderRadius: AppRadius.brBase,
                ),
                alignment: Alignment.center,
                child: Icon(
                  vehicle.vehicleType.toLowerCase() == 'bike'
                      ? Icons.two_wheeler_rounded
                      : Icons.directions_car_rounded,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.vehicleNumber.isNotEmpty ? vehicle.vehicleNumber : 'Unknown Reg',
                      style: context.typography.titleSm,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (vehicle.vehicleModel.isNotEmpty) vehicle.vehicleModel,
                        if (vehicle.customerName.isNotEmpty) vehicle.customerName,
                      ].join(' • '),
                      style: context.typography.bodyMd.copyWith(
                        color: context.colors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}