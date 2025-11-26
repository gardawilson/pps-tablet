import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/dropdown_field.dart';
import '../model/crusher_production_model.dart';
import '../view_model/crusher_production_view_model.dart';

class CrusherProductionDropdown extends StatefulWidget {
  final String? preselectNoCrusherProduksi; // edit mode
  final String? preselectNamaMesin;         // edit mode (optional label)
  final ValueChanged<CrusherProduction?>? onChanged;
  final String label;
  final IconData icon;
  final String? hintText;

  final DateTime? date;     // required for fetch mode
  final int? idMesinFilter; // optional extra filter for fetch
  final String? shiftFilter;

  final bool enabled;

  const CrusherProductionDropdown({
    super.key,
    this.preselectNoCrusherProduksi,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Proses Crusher',
    this.icon = Icons.construction_outlined,
    this.hintText,
    this.date,
    this.idMesinFilter,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<CrusherProductionDropdown> createState() => _CrusherProductionDropdownState();
}

class _CrusherProductionDropdownState extends State<CrusherProductionDropdown> {
  CrusherProduction? _value;
  bool _usePreselectedOnly = false;
  List<CrusherProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant CrusherProductionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usePreselectedOnly) return; // edit mode → ignore updates

    final dateChanged = oldWidget.date != widget.date;
    final idMesinChanged = oldWidget.idMesinFilter != widget.idMesinFilter;
    final shiftChanged = oldWidget.shiftFilter != widget.shiftFilter;

    if (dateChanged || idMesinChanged || shiftChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentDate();
      });
    }
  }

  Future<void> _primeOrFetch() async {
    final pre = (widget.preselectNoCrusherProduksi ?? '').trim();
    if (pre.isNotEmpty) {
      // EDIT MODE: single local item
      final item = CrusherProduction(
        noCrusherProduksi: pre,
        idOperator: 0,
        idMesin: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        namaOperator: '', // ⬅️ CHANGED: added required field
        tanggal: DateTime.now(), // display-only; not used
        jamKerja: 0, // ⬅️ CHANGED: int instead of String?
        shift: int.tryParse(widget.shiftFilter ?? '0') ?? 0, // ⬅️ CHANGED: int instead of String
        createBy: '', // ⬅️ CHANGED: required String
        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        jmlhAnggota: 0,
        hadir: 0,
        hourMeter: null,
        hourStart: null, // ⬅️ ADDED
        hourEnd: null,   // ⬅️ ADDED
        outputNoCrusher: null,
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
    final vm = context.read<CrusherProductionViewModel>();

    if (widget.date == null) {
      vm.clear();
      setState(() => _value = null);
      return;
    }

    vm.isLoading = true;
    vm.error = '';
    vm.notifyListeners();

    try {
      await vm.fetchByDate(
        widget.date!,
        idMesin: widget.idMesinFilter,
        shift: widget.shiftFilter,
      );
      if (!mounted) return;

      final hasMatch = vm.items.any((e) => e.noCrusherProduksi == _value?.noCrusherProduksi);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data produksi crusher';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrusherProductionViewModel>(
      builder: (context, vm, _) {
        List<CrusherProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        // Optional filter by shift (client-side), in case backend returns mixed shifts
        if (widget.shiftFilter != null && widget.shiftFilter!.isNotEmpty) {
          final shiftInt = int.tryParse(widget.shiftFilter!);
          if (shiftInt != null) {
            base = base.where((e) => e.shift == shiftInt).toList(); // ⬅️ CHANGED: compare int
          }
        }

        final hasMatch = base.any((e) => e.noCrusherProduksi == _value?.noCrusherProduksi);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        String itemLabel(CrusherProduction e) {
          final outputs = e.outputNoCrusherList;
          final outputsStr = outputs.isEmpty ? '' : ' • [${outputs.join(', ')}]';
          final shiftStr = (e.shift == 0) ? '' : ' (SHIFT ${e.shift})'; // ⬅️ CHANGED: int comparison
          return '${e.noCrusherProduksi} | ${e.namaMesin}$shiftStr$outputsStr';
        }

        return DropdownPlainField<CrusherProduction>(
          label: widget.label,
          prefixIcon: widget.icon,
          fieldHeight: 40,

          value: safeValue,
          items: base,
          itemAsString: itemLabel,
          compareFn: (a, b) => a.noCrusherProduksi == b.noCrusherProduksi,

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