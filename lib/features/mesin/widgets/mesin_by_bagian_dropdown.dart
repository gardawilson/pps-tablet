import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/mesin_view_model.dart';
import '../model/mesin_model.dart';
import '../../../../common/widgets/dropdown_field.dart';

class MesinByBagianDropdown extends StatefulWidget {
  final String? bagian;                     // e.g. 'WASHING  KECIL'
  final bool includeDisabled;               // default: false (only active)
  final int? preselectIdMesin;              // edit mode
  final String? preselectNamaMesin;         // optional label for edit mode
  final ValueChanged<MstMesin?>? onChanged;
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  const MesinByBagianDropdown({
    super.key,
    required this.bagian,
    this.includeDisabled = false,
    this.preselectIdMesin,
    this.preselectNamaMesin,
    this.onChanged,
    this.label = 'Mesin',
    this.icon = Icons.precision_manufacturing_outlined,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<MesinByBagianDropdown> createState() => _MesinByBagianDropdownState();
}

class _MesinByBagianDropdownState extends State<MesinByBagianDropdown> {
  MstMesin? _value;
  bool _usePreselectedOnly = false;
  List<MstMesin> _localItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeOrFetch());
  }

  @override
  void didUpdateWidget(covariant MesinByBagianDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_usePreselectedOnly) return; // edit mode → skip fetching

    if (oldWidget.bagian != widget.bagian ||
        oldWidget.includeDisabled != widget.includeDisabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchForCurrentBagian();
      });
    }
  }

  Future<void> _primeOrFetch() async {
    final preId = widget.preselectIdMesin;
    if (preId != null) {
      final item = MstMesin(
        idMesin: preId,
        namaMesin: widget.preselectNamaMesin ?? '',
        bagian: widget.bagian ?? '',
        defaultOperator: null,
        enable: true,
        kapasitas: null,
        idUom: null,
        shotWeightPs: null,
        klemLebar: null,
        klemPanjang: null,
        idBagianMesin: null,
        target: null,
      );

      setState(() {
        _usePreselectedOnly = true;
        _localItems = [item];
        _value = item;
      });
      widget.onChanged?.call(item);
      return;
    }

    await _fetchForCurrentBagian();
  }

  Future<void> _fetchForCurrentBagian() async {
    final vm = context.read<MesinViewModel>();

    if ((widget.bagian ?? '').trim().isEmpty) {
      vm.clear();
      setState(() => _value = null);
      return;
    }

    vm.isLoading = true;
    vm.error = '';
    vm.notifyListeners();

    try {
      await vm.fetchByBagian(widget.bagian!.trim(),
          includeDisabled: widget.includeDisabled);
      if (!mounted) return;

      final hasMatch = vm.items.any((e) => e.idMesin == _value?.idMesin);
      setState(() {
        _usePreselectedOnly = false;
        if (!hasMatch) _value = null;
      });
    } catch (_) {
      vm.error = 'Gagal memuat data mesin';
    } finally {
      vm.isLoading = false;
      vm.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MesinViewModel>(
      builder: (context, vm, _) {
        final List<MstMesin> base =
        _usePreselectedOnly ? _localItems : vm.items;

        final hasMatch = base.any((e) => e.idMesin == _value?.idMesin);
        final safeValue = hasMatch ? _value : null;

        final isLoading = _usePreselectedOnly ? false : vm.isLoading;
        final hasError = _usePreselectedOnly ? false : vm.error.isNotEmpty;
        final errorText = _usePreselectedOnly ? null : vm.error;

        return DropdownPlainField<MstMesin>(
          label: widget.label,
          prefixIcon: widget.icon,
          fieldHeight: 40,

          value: safeValue,
          items: base,
          // feel free to tweak the label:
          itemAsString: (e) =>
              '${e.namaMesin}${e.enable ? '' : ' (DISABLED)'}'.trim(),
          compareFn: (a, b) => a.idMesin == b.idMesin,

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
          onRetry: _usePreselectedOnly ? null : _fetchForCurrentBagian,

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
