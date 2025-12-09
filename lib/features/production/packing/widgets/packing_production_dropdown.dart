// lib/features/shared/packing_production/widgets/packing_production_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../model/packing_production_model.dart';
import '../../../../common/widgets/dropdown_field.dart';
import '../view_model/packing_production_view_model.dart';

class PackingProductionDropdown extends StatefulWidget {
  final String? preselectNoPacking;
  final String? preselectNamaMesin;
  final ValueChanged<PackingProduction?>? onChanged;

  final String label;
  final IconData? icon;
  final String? hintText;
  final DateTime? date;
  final int? shiftFilter;
  final bool enabled;

  const PackingProductionDropdown({
    super.key,
    this.preselectNoPacking,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Packing',
    this.icon,
    this.hintText,
    this.date,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<PackingProductionDropdown> createState() =>
      _PackingProductionDropdownState();
}

class _PackingProductionDropdownState
    extends State<PackingProductionDropdown> {
  PackingProduction? _value;
  bool _usePreselectedOnly = false;
  List<PackingProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant PackingProductionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_usePreselectedOnly) return;

    if (oldWidget.date != widget.date) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentDate();
      });
    }
  }

  Future<void> _primeOrFetch() async {
    final pre = (widget.preselectNoPacking ?? '').trim();

    if (pre.isNotEmpty) {
      // EDIT MODE → synthetic single item
      final item = PackingProduction(
        noPacking: pre,
        tanggal: DateTime.now().toUtc(),
        idMesin: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        idOperator: 0,
        namaOperator: '',
        shift: widget.shiftFilter ?? 0,
        jamKerja: 0,
        createBy: null,
        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        hourMeter: null,
        hourStart: null,
        hourEnd: null,
      );

      setState(() {
        _usePreselectedOnly = true;
        _localItems = [item];
        _value = item;
      });
      widget.onChanged?.call(item);
      return;
    }

    await _fetchForCurrentDate();
  }

  Future<void> _fetchForCurrentDate() async {
    final vm = context.read<PackingProductionViewModel>();

    if (widget.date == null) {
      vm.items = [];
      vm.error = '';
      vm.isLoading = false;
      vm.notifyListeners();
      setState(() => _value = null);
      return;
    }

    vm.isLoading = true;
    vm.error = '';
    vm.notifyListeners();

    try {
      await vm.fetchByDate(widget.date!);
      if (!mounted) return;

      final hasMatch =
      vm.items.any((e) => e.noPacking == _value?.noPacking);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data Packing';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingProductionViewModel>(
      builder: (context, vm, _) {
        List<PackingProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        if (widget.shiftFilter != null) {
          base = base.where((e) => e.shift == widget.shiftFilter).toList();
        }

        final hasMatch =
        base.any((e) => e.noPacking == _value?.noPacking);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<PackingProduction>(
          label: widget.label,
          prefixIcon: widget.icon ?? MaterialCommunityIcons.package_variant_closed,
          fieldHeight: 40,
          value: safeValue,
          items: base,
          itemAsString: (e) =>
          '${e.noPacking} | ${e.namaMesin} (SHIFT ${e.shift})',
          compareFn: (a, b) => a.noPacking == b.noPacking,
          onChanged: widget.enabled
              ? (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          }
              : null,
          enabled: widget.enabled,
          isLoading: isLoading,
          fetchError: hasError,
          fetchErrorText: errorText,
          onRetry: _usePreselectedOnly ? null : _fetchForCurrentDate,
          hint: isLoading
              ? 'Memuat...'
              : (hasError
              ? 'Terjadi error'
              : (base.isEmpty
              ? (widget.hintText ?? 'Tidak ada data')
              : 'PILIH')),
        );
      },
    );
  }
}
