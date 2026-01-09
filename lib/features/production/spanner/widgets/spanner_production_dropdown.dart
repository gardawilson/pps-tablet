import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../model/spanner_production_model.dart';
import '../view_model/spanner_production_view_model.dart';
import '../../../../common/widgets/dropdown_field.dart';

class SpannerProductionDropdown extends StatefulWidget {
  final String? preselectNoProduksi;
  final String? preselectNamaMesin;
  final ValueChanged<SpannerProduction?>? onChanged;

  final String label;
  final IconData? icon;
  final String? hintText;
  final DateTime? date;
  final int? shiftFilter;
  final bool enabled;

  const SpannerProductionDropdown({
    super.key,
    this.preselectNoProduksi,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Spanner',
    this.icon,
    this.hintText,
    this.date,
    this.shiftFilter,
    this.enabled = true,
  });

  @override
  State<SpannerProductionDropdown> createState() =>
      _SpannerProductionDropdownState();
}

class _SpannerProductionDropdownState
    extends State<SpannerProductionDropdown> {
  SpannerProduction? _value;
  bool _usePreselectedOnly = false;
  List<SpannerProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant SpannerProductionDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Kalau sedang edit mode (pakai item synthetic), jangan auto-fetch
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
      // EDIT MODE → buat satu synthetic item lokal
      final item = SpannerProduction(
        noProduksi: pre,
        idMesin: 0,
        idOperator: 0,
        namaMesin: widget.preselectNamaMesin ?? '',
        namaOperator: '',

        // model pakai tglProduksi (nullable)
        tglProduksi: DateTime.now().toUtc(),
        shift: widget.shiftFilter ?? 0,

        // nullable in model, jadi boleh null / 0
        jamKerja: 0,

        // createBy di model REQUIRED string (bukan nullable)
        // kalau edit mode tidak punya value, kasih default aman
        createBy: '',

        checkBy1: null,
        checkBy2: null,
        approveBy: null,
        hourMeter: null,

        // optional time range
        hourStart: null,
        hourEnd: null,

        // optional lock flags
        lastClosedDate: null,
        isLocked: false,
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
    final vm = context.read<SpannerProductionViewModel>();

    if (widget.date == null) {
      vm.clear();
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
      vm.error = 'Gagal memuat data Spanner';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpannerProductionViewModel>(
      builder: (context, vm, _) {
        List<SpannerProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        // Filter shift kalau diminta
        if (widget.shiftFilter != null) {
          base = base.where((e) => e.shift == widget.shiftFilter).toList();
        }

        final hasMatch =
        base.any((e) => e.noProduksi == _value?.noProduksi);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<SpannerProduction>(
          label: widget.label,
          prefixIcon: widget.icon ?? MaterialCommunityIcons.wrench_outline,
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
