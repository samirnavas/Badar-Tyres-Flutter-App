import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/service_item.dart';
import '../../../core/repositories/job_repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/red_button.dart';
import '../../services/presentation/services_catalog_screen.dart';

/// The Create Job Card form. Customer, vehicle, and job details are grouped
/// into distinct tonal sections, followed by the service line-item table with
/// running totals and the Create / Add Service actions.
class CreateJobCardScreen extends StatefulWidget {
  const CreateJobCardScreen({super.key});

  @override
  State<CreateJobCardScreen> createState() => _CreateJobCardScreenState();
}

class _CreateJobCardScreenState extends State<CreateJobCardScreen> {
  static const double _gstRate = 0.18;

  final JobRepository _repository = JobRepository();
  List<String> _technicians = const [];
  Map<String, List<String>> _manufacturersMap = const {};
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _modelController = TextEditingController();
  final _wheelSizeController = TextEditingController();
  final _remarksController = TextEditingController();
  final _startingTimeController = TextEditingController();

  String _vehicleType = 'Car';
  String? _manufacturer;
  String? _wheelType;
  String? _tyreType;
  TimeOfDay? _startingTime;
  String? _technician;

  final List<ServiceItem> _services = [];

  double get _subTotal =>
      _services.fold(0, (sum, item) => sum + item.amount);
  double get _gst => _subTotal * _gstRate;
  double get _grandTotal => _subTotal + _gst;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
    _loadManufacturers();
  }

  Future<void> _loadTechnicians() async {
    try {
      final technicians = await _repository.fetchTechnicians();
      if (!mounted) return;
      setState(() => _technicians = technicians);
    } on ApiException {
      // Leave the dropdown empty if the server is unreachable.
    }
  }

  Future<void> _loadManufacturers() async {
    try {
      final manufacturers = await _repository.fetchManufacturers();
      if (!mounted) return;
      setState(() => _manufacturersMap = manufacturers);
    } on ApiException {
      // Leave the dropdown empty if the server is unreachable.
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    _customerNameController.dispose();
    _contactController.dispose();
    _vehicleRegController.dispose();
    _modelController.dispose();
    _wheelSizeController.dispose();
    _remarksController.dispose();
    _startingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickStartingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startingTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startingTime = picked;
        _startingTimeController.text = picked.format(context);
      });
    }
  }

  Future<void> _addService() async {
    final result = await Navigator.of(context).push<ServiceItem>(
      MaterialPageRoute(builder: (_) => const ServicesCatalogScreen()),
    );
    if (result != null) setState(() => _services.add(result));
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one service')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final model = [
      _manufacturer?.trim() ?? '',
      _modelController.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    final payload = <String, dynamic>{
      'customerName': _customerNameController.text.trim(),
      'contact': _contactController.text.trim(),
      'vehicleReg': _vehicleRegController.text.trim(),
      'manufacturer': _manufacturer,
      'model': model,
      'vehicleType': _vehicleType,
      'wheelType': _wheelType,
      'tyreType': _tyreType,
      'wheelSize': _wheelSizeController.text.trim(),
      'startingTime': _startingTimeController.text.trim(),
      'remarks': _remarksController.text.trim(),
      'technician': _technician,
      'services': _services.map((s) => s.toMap()).toList(),
    };

    try {
      await _repository.createJob(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job card created')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
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
        title: const Text('Create Job Card'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerPadding,
            AppSpacing.stackMd,
            AppSpacing.containerPadding,
            AppSpacing.stackLg,
          ),
          children: [
            _FormSection(
              title: 'Customer Details',
              children: [
                CustomTextField(
                  label: 'Customer Name',
                  hint: 'Enter Full Name',
                  controller: _customerNameController,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  label: 'Contact Number',
                  hint: 'Enter Contact Number',
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: _required,
                ),
              ],
            ),
            _FormSection(
              title: 'Vehicle Details',
              children: [
                _RadioGroup(
                  label: 'Vehicle Type',
                  options: const ['Car', 'Bike', 'Others'],
                  value: _vehicleType,
                  onChanged: (v) {
                    setState(() {
                      _vehicleType = v;
                      _manufacturer = null; // Reset when type changes
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  label: 'Vehicle Reg.No.',
                  hint: 'Enter Vehicle Reg.No.',
                  controller: _vehicleRegController,
                  inputFormatters: [_UpperCaseFormatter()],
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _LabeledDropdown(
                  label: 'Manufacturer',
                  hint: 'Select Manufacturer',
                  value: _manufacturer,
                  options: _manufacturersMap[_vehicleType] ?? [],
                  onChanged: (v) => setState(() => _manufacturer = v),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  label: 'Model',
                  hint: 'e.g. Corolla, Civic, Actros',
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RadioGroup(
                        label: 'Wheel Type',
                        options: const ['Alloy', 'Steel'],
                        value: _wheelType,
                        onChanged: (v) => setState(() => _wheelType = v),
                      ),
                    ),
                    Expanded(
                      child: _RadioGroup(
                        label: 'Tyre Type',
                        options: const ['TL', 'TT'],
                        value: _tyreType,
                        onChanged: (v) => setState(() => _tyreType = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  label: 'Wheel Size',
                  hint: 'Enter Wheel Size',
                  controller: _wheelSizeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            _FormSection(
              title: 'Job Details',
              children: [
                CustomTextField(
                  label: 'Starting Time',
                  hint: 'Time',
                  readOnly: true,
                  onTap: _pickStartingTime,
                  suffixIcon: Icons.schedule,
                  onSuffixTap: _pickStartingTime,
                  controller: _startingTimeController,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                CustomTextField(
                  label: 'Remarks',
                  hint: 'Enter Remarks',
                  controller: _remarksController,
                  minLines: 2,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _LabeledDropdown(
                  label: 'Assign Technician',
                  hint: 'Technician',
                  value: _technician,
                  options: _technicians,
                  onChanged: (v) => setState(() => _technician = v),
                ),
              ],
            ),
            _FormSection(
              title: 'Services & Charges',
              children: [
                _ServiceTable(
                  services: _services,
                  onRemove: (i) => setState(() => _services.removeAt(i)),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _TotalRow(label: 'Sub Total', value: _money(_subTotal)),
                const SizedBox(height: AppSpacing.base),
                _TotalRow(label: 'GST (18%)', value: _money(_gst)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.gutter),
                  child: Divider(
                    height: 1,
                    color: context.colors.surfaceContainerHighest,
                  ),
                ),
                _TotalRow(
                  label: 'GRAND TOTAL',
                  value: _money(_grandTotal),
                  emphasized: true,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(
        onCreate: _create,
        onAddService: _addService,
        isSubmitting: _isSubmitting,
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}

// ---------------------------------------------------------------------------
// Section wrapper
// ---------------------------------------------------------------------------

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Text(
                title,
                style: context.typography.titleSm.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom radio group
// ---------------------------------------------------------------------------

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.bodyMd.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.stackMd,
          runSpacing: AppSpacing.base,
          children: [
            for (final option in options)
              _RadioOption(
                label: option,
                selected: value == option,
                onTap: () => onChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? context.colors.primaryContainer : context.colors.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brFull,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.primaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.base),
            Text(
              label,
              style: context.typography.bodyMd.copyWith(
                color: context.colors.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Labeled dropdown (styled to match CustomTextField)
// ---------------------------------------------------------------------------

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Guard against a stale selection that is no longer in the options list.
    final selected = (value != null && options.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.typography.bodyMd.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          dropdownColor: context.colors.surfaceContainerHigh,
          borderRadius: AppRadius.brBase,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          iconEnabledColor: context.colors.onSurfaceVariant,
          style: context.typography.bodyMd.copyWith(color: context.colors.onSurface),
          hint: Text(
            hint,
            style:
                context.typography.bodyMd.copyWith(color: context.colors.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _border(context.colors.outlineVariant, 1),
            enabledBorder: _border(context.colors.outlineVariant, 1),
            focusedBorder: _border(context.colors.primary, 2),
          ),
          items: [
            for (final t in options)
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: AppRadius.brBase,
        borderSide: BorderSide(color: color, width: width),
      );
}

// ---------------------------------------------------------------------------
// Service line-item table
// ---------------------------------------------------------------------------

class _ServiceTable extends StatelessWidget {
  const _ServiceTable({required this.services, required this.onRemove});

  final List<ServiceItem> services;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brBase,
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _ServiceHeaderRow(),
          if (services.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
              child: Text(
                'No services added',
                style: context.typography.bodyMd.copyWith(
                  fontSize: 13,
                  color: context.colors.secondary,
                ),
              ),
            )
          else
            for (int i = 0; i < services.length; i++)
              Dismissible(
                key: ValueKey('${services[i].name}-$i'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onRemove(i),
                background: Container(
                  color: AppStatusColors.delayed.withValues(alpha: 0.85),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 20),
                ),
                child: _ServiceDataRow(index: i + 1, item: services[i]),
              ),
        ],
      ),
    );
  }
}

class _ServiceHeaderRow extends StatelessWidget {
  const _ServiceHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = context.typography.labelSm.copyWith(
      letterSpacing: 0,
      fontWeight: FontWeight.w600,
      color: context.colors.onSurface,
    );
    return Container(
      color: context.colors.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: style)),
          Expanded(flex: 4, child: Text('Service / Part', style: style)),
          Expanded(flex: 5, child: Text('Description', style: style)),
          Expanded(
            flex: 3,
            child: Text('Amt (₹)', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _ServiceDataRow extends StatelessWidget {
  const _ServiceDataRow({required this.index, required this.item});

  final int index;
  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final cell = context.typography.bodyMd.copyWith(
      fontSize: 13,
      color: context.colors.onSurface,
    );
    final muted = cell.copyWith(color: context.colors.secondary);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: context.colors.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Text('$index', style: muted)),
          Expanded(flex: 4, child: Text(item.name, style: cell)),
          Expanded(flex: 5, child: Text(item.description, style: muted)),
          Expanded(
            flex: 3,
            child: Text(
              _money(item.amount, symbol: false),
              style: cell,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasized
        ? context.typography.titleSm.copyWith(fontSize: 15)
        : context.typography.bodyMd.copyWith(
            fontSize: 14, color: context.colors.secondary);
    final valueStyle = emphasized
        ? context.typography.titleSm.copyWith(
            fontSize: 17, color: context.colors.primaryContainer)
        : context.typography.bodyMd.copyWith(
            fontSize: 14, fontWeight: FontWeight.w600);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pinned action bar
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onCreate,
    required this.onAddService,
    this.isSubmitting = false,
  });

  final VoidCallback onCreate;
  final VoidCallback onAddService;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.surfaceContainerHigh, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackMd),
          child: Row(
            children: [
              Expanded(
                child: RedButton(
                  label: 'Create',
                  onPressed: onCreate,
                  isLoading: isSubmitting,
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: RedButton.outlined(
                  label: 'Add Service',
                  onPressed: isSubmitting ? null : onAddService,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forces input to upper case (e.g. vehicle registration numbers).
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

/// Formats a value as currency, optionally with the rupee symbol.
String _money(double v, {bool symbol = true}) {
  final negative = v < 0;
  final str = v.abs().toStringAsFixed(2);
  final dot = str.indexOf('.');
  final intPart = str.substring(0, dot);
  final decimals = str.substring(dot + 1);
  final buffer = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
  }
  final prefix = negative ? '-' : '';
  final sym = symbol ? '₹ ' : '';
  return '$prefix$sym${buffer.toString()}.$decimals';
}