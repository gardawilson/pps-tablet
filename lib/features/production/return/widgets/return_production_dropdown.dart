// lib/features/shared/return_production/widgets/packing_production_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../view_model/return_production_view_model.dart';
import '../model/return_production_model.dart';
import '../../../../common/widgets/dropdown_field.dart';

class ReturnProductionDropdown extends StatefulWidget {
  /// Untuk edit mode: preselect berdasarkan NoRetur
  final String? preselectNoRetur;
  final String? preselectNamaPembeli;
  final ValueChanged<ReturnProduction?>? onChanged;

  final String label;
  final IconData? icon;
  final String? hintText;
  final DateTime? date;
  final bool enabled;

  const ReturnProductionDropdown({
    super.key,
    this.preselectNoRetur,
    this.preselectNamaPembeli,
    this.onChanged,
    this.label = 'Retur',
    this.icon,
    this.hintText,
    this.date,
    this.enabled = true,
  });

  @override
  State<ReturnProductionDropdown> createState() =>
      _ReturnProductionDropdownState();
}

class _ReturnProductionDropdownState extends State<ReturnProductionDropdown> {
  ReturnProduction? _value;
  bool _usePreselectedOnly = false;
  List<ReturnProduction> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant ReturnProductionDropdown oldWidget) {
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
    final pre = (widget.preselectNoRetur ?? '').trim();

    if (pre.isNotEmpty) {
      // EDIT MODE → buat satu synthetic item lokal
      final item = ReturnProduction(
        noRetur: pre,
        invoice: '',
        tanggal: DateTime.now().toUtc(),
        idPembeli: 0,
        namaPembeli: widget.preselectNamaPembeli ?? '',
        noBJSortir: '',
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
    final vm = context.read<ReturnProductionViewModel>();

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

      final hasMatch =
      vm.items.any((e) => e.noRetur == _value?.noRetur);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data retur';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReturnProductionViewModel>(
      builder: (context, vm, _) {
        List<ReturnProduction> base =
        _usePreselectedOnly ? _localItems : vm.items;

        final hasMatch =
        base.any((e) => e.noRetur == _value?.noRetur);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<ReturnProduction>(
          label: widget.label,
          prefixIcon: widget.icon ?? Ionicons.return_down_back_outline,
          fieldHeight: 40,

          value: safeValue,
          items: base,
          itemAsString: (e) =>
          '${e.noRetur} | ${e.namaPembeli}',
          compareFn: (a, b) => a.noRetur == b.noRetur,

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
