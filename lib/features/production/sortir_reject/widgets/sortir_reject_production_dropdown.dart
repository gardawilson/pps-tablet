// lib/features/shared/sortir_reject_production/widgets/sortir_reject_production_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../view_model/sortir_reject_production_view_model.dart';
import '../model/sortir_reject_production_model.dart';
import '../../../../common/widgets/dropdown_field.dart';

class SortirRejectProductionDropdown extends StatefulWidget {
  /// Untuk edit mode: preselect berdasarkan NoBJSortir
  final String? preselectNoBJSortir;
  final String? preselectUsername;
  final ValueChanged<SortirRejectProduction?>? onChanged;

  final String label;
  final IconData? icon;
  final String? hintText;
  final DateTime? date;
  final bool enabled;

  const SortirRejectProductionDropdown({
    super.key,
    this.preselectNoBJSortir,
    this.preselectUsername,
    this.onChanged,
    this.label = 'Sortir Reject',
    this.icon,
    this.hintText,
    this.date,
    this.enabled = true,
  });

  @override
  State<SortirRejectProductionDropdown> createState() =>
      _SortirRejectProductionDropdownState();
}

class _SortirRejectProductionDropdownState
    extends State<SortirRejectProductionDropdown> {
  SortirRejectProduction? _value;
  bool _usePreselectedOnly = false;
  List<SortirRejectProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(
      covariant SortirRejectProductionDropdown oldWidget) {
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
    final pre = (widget.preselectNoBJSortir ?? '').trim();

    if (pre.isNotEmpty) {
      // EDIT MODE → buat satu synthetic item lokal
      final item = SortirRejectProduction(
        noBJSortir: pre,
        tanggal: DateTime.now().toUtc(),
        idUsername: 0,
        username: widget.preselectUsername ?? '',
        idWarehouse: null,
        namaWarehouse: '',
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
    final vm = context.read<SortirRejectProductionViewModel>();

    // Kalau tidak ada tanggal → clear saja
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

      final hasMatch = vm.items
          .any((e) => e.noBJSortir == _value?.noBJSortir);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data sortir reject';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SortirRejectProductionViewModel>(
      builder: (context, vm, _) {
        List<SortirRejectProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        final hasMatch =
        base.any((e) => e.noBJSortir == _value?.noBJSortir);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError =
        _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<SortirRejectProduction>(
          label: widget.label,
          prefixIcon:
          widget.icon ?? Ionicons.alert_circle_outline,
          fieldHeight: 40,

          value: safeValue,
          items: base,
          itemAsString: (e) =>
          '${e.noBJSortir}',
          compareFn: (a, b) => a.noBJSortir == b.noBJSortir,

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
