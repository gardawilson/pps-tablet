// lib/features/shared/hot_stamp_production/widgets/packing_production_dropdown.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/hot_stamp_production_model.dart';
import '../../../../common/widgets/dropdown_field.dart';
import '../view_model/hot_stamp_production_view_model.dart';

class HotStampProductionDropdown extends StatefulWidget {
  final String? preselectNoProduksi;
  final String? preselectNamaMesin;
  final ValueChanged<HotStampProduction?>? onChanged;

  final String label;
  final IconData icon;
  final String? hintText;
  final DateTime? date;
  final int? shiftFilter;
  final bool enabled;

  const HotStampProductionDropdown({
    super.key,
    this.preselectNoProduksi,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Hot Stamping',
    this.icon = Icons.local_fire_department_outlined,
    this.hintText,
    this.date,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<HotStampProductionDropdown> createState() =>
      _HotStampProductionDropdownState();
}

class _HotStampProductionDropdownState
    extends State<HotStampProductionDropdown> {
  HotStampProduction? _value;
  bool _usePreselectedOnly = false;
  List<HotStampProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant HotStampProductionDropdown oldWidget) {
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
    final pre = (widget.preselectNoProduksi ?? '').trim();

    if (pre.isNotEmpty) {
      // EDIT MODE → synthetic single item
      final item = HotStampProduction(
        noProduksi: pre,
        tglProduksi: DateTime.now().toUtc(), // ✅ renamed from tanggal
        idMesin: 0,
        idOperator: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        namaOperator: '',
        shift: widget.shiftFilter ?? 0,
        createBy: '', // ✅ required field, beri empty string
        jamKerja: 0,
        hourMeter: null,
        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        hourStart: null, // ✅ added
        hourEnd: null,   // ✅ added
        lastClosedDate: null, // ✅ added
        isLocked: false,      // ✅ added (default false untuk edit mode)
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
    final vm = context.read<HotStampProductionViewModel>();

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
      vm.items.any((e) => e.noProduksi == _value?.noProduksi);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data Hot Stamp';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HotStampProductionViewModel>(
      builder: (context, vm, _) {
        List<HotStampProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        if (widget.shiftFilter != null) {
          base = base.where((e) => e.shift == widget.shiftFilter).toList();
        }

        final hasMatch =
        base.any((e) => e.noProduksi == _value?.noProduksi);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<HotStampProduction>(
          label: widget.label,
          prefixIcon: widget.icon,
          fieldHeight: 40,
          value: safeValue,
          items: base,
          itemAsString: (e) =>
          '${e.noProduksi} | ${e.namaMesin} (SHIFT ${e.shift})',
          compareFn: (a, b) => a.noProduksi == b.noProduksi,
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
