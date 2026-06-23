import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/service_item.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/red_button.dart';

/// A predefined service the workshop offers, shown in the [ServicesCatalogScreen]
/// grid. Each entry maps to a representative icon and an optional default
/// description used to pre-fill the amount sheet.
class ServiceDefinition {
  const ServiceDefinition({
    required this.name,
    required this.icon,
    this.description = '',
  });

  final String name;
  final IconData icon;
  final String description;
}

/// The full workshop service menu, laid out to mirror the design reference
/// (three-column grid, grouped by tyre, mechanical, A/C, air, and misc work).
const List<ServiceDefinition> kServiceCatalog = [
  ServiceDefinition(name: 'Wheel Alignment', icon: Icons.straighten),
  ServiceDefinition(name: 'Wheel Balancing', icon: Icons.balance),
  ServiceDefinition(name: 'Tyre Rotation', icon: Icons.rotate_right),
  ServiceDefinition(name: 'Tyre Fitting', icon: Icons.build),
  ServiceDefinition(name: 'Tyre Change', icon: Icons.autorenew),
  ServiceDefinition(name: 'Tube Change', icon: Icons.donut_large),
  ServiceDefinition(name: 'Neck Change', icon: Icons.change_circle_outlined),
  ServiceDefinition(name: 'Puncher Work', icon: Icons.handyman),
  ServiceDefinition(name: 'Patch Work', icon: Icons.healing),
  ServiceDefinition(name: 'Alloy Wheel Fitting', icon: Icons.blur_circular),
  ServiceDefinition(name: 'A/C Gas Services', icon: Icons.ac_unit),
  ServiceDefinition(name: 'Other A/C Services', icon: Icons.air),
  ServiceDefinition(name: 'Nitrogen Air Fitting', icon: Icons.bubble_chart),
  ServiceDefinition(name: 'Air Filling', icon: Icons.compress),
  ServiceDefinition(name: 'Other Services', icon: Icons.miscellaneous_services),
  ServiceDefinition(name: 'Fast Tag', icon: Icons.bolt),
  ServiceDefinition(name: 'Pollution Test', icon: Icons.cloud_outlined),
  ServiceDefinition(name: 'Insurance', icon: Icons.verified_user_outlined),
];

/// A catalog of selectable services rendered as a tappable icon grid, matching
/// the design reference. Selecting a tile collects an amount and pops back with
/// the resulting [ServiceItem].
class ServicesCatalogScreen extends StatelessWidget {
  const ServicesCatalogScreen({super.key});

  Future<void> _select(BuildContext context, ServiceDefinition def) async {
    final item = await showModalBottomSheet<ServiceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceAmountSheet(definition: def),
    );
    if (item != null && context.mounted) Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Services'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.gutter,
          mainAxisSpacing: AppSpacing.gutter,
          childAspectRatio: 0.92,
        ),
        itemCount: kServiceCatalog.length,
        itemBuilder: (context, i) {
          final def = kServiceCatalog[i];
          return _ServiceTile(
            definition: def,
            onTap: () => _select(context, def),
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.definition, required this.onTap});

  final ServiceDefinition definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLow,
      borderRadius: AppRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brLg,
            border: Border.all(color: context.colors.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.gutter,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                definition.icon,
                size: 34,
                color: context.colors.primaryContainer,
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(
                definition.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.typography.bodyMd.copyWith(
                  fontSize: 12.5,
                  height: 1.2,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that captures the charge (and an editable description) for a
/// service picked from the catalog, returning a [ServiceItem].
class _ServiceAmountSheet extends StatefulWidget {
  const _ServiceAmountSheet({required this.definition});

  final ServiceDefinition definition;

  @override
  State<_ServiceAmountSheet> createState() => _ServiceAmountSheetState();
}

class _ServiceAmountSheetState extends State<_ServiceAmountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.definition.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ServiceItem(
        name: widget.definition.name,
        description: _descriptionController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Icon(
                    widget.definition.icon,
                    color: context.colors.primaryContainer,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Text(
                      widget.definition.name,
                      style: context.typography.headlineMd.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackMd),
              CustomTextField(
                label: 'Description',
                hint: 'Short description (optional)',
                controller: _descriptionController,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              CustomTextField(
                label: 'Amount (₹)',
                hint: '0.00',
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.stackLg),
              RedButton(label: 'Add Service', onPressed: _submit),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}