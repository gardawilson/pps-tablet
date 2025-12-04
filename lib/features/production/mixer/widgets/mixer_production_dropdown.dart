// lib/features/shared/mixer_production/widgets/hot_stamp_production_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/mixer_production_view_model.dart';
import '../model/mixer_production_model.dart';
import '../../../../common/widgets/dropdown_field.dart';

class MixerProductionDropdown extends StatefulWidget {
  final String? preselectNoProduksi;
  final String? preselectNamaMesin;
  final ValueChanged<MixerProduction?>? onChanged;
  final String label;
  final IconData icon;
  final String? hintText;
  final DateTime? date;
  final int? shiftFilter;
  final bool enabled;

  const MixerProductionDropdown({
    super.key,
    this.preselectNoProduksi,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Proses Mixer',
    this.icon = Icons.blender_outlined,
    this.hintText,
    this.date,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<MixerProductionDropdown> createState() =>
      _MixerProductionDropdownState();
}

class _MixerProductionDropdownState extends State<MixerProductionDropdown> {
  MixerProduction? _value;
  bool _usePreselectedOnly = false;
  List<MixerProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant MixerProductionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usePreselectedOnly) return; // edit mode → ignore date changes

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
      // EDIT MODE: build single local item
      final item = MixerProduction(
        noProduksi: pre,
        idOperator: 0,
        namaOperator: '',
        idMesin: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        tglProduksi: DateTime.now().toUtc(),
        jam: 0,
        shift: widget.shiftFilter ?? 0,
        createBy: null,
        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        jmlhAnggota: 0,
        hadir: 0,
        hourMeter: null,
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
    final vm = context.read<MixerProductionViewModel>();

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

      final hasMatch = vm.items.any((e) => e.noProduksi == _value?.noProduksi);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data produksi mixer';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerProductionViewModel>(
      builder: (context, vm, _) {
        List<MixerProduction> base =
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

        return DropdownPlainField<MixerProduction>(
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
