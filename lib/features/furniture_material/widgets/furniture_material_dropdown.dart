// lib/features/furniture_material/widgets/furniture_material_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/dropdown_field.dart';
import '../model/furniture_material_lookup_model.dart';
import '../view_model/furniture_material_lookup_view_model.dart';

class FurnitureMaterialDropdown extends StatefulWidget {
  final int? idCetakan;
  final int? idWarna;

  final int? preselectId;

  final ValueChanged<FurnitureMaterialLookupResult?>? onChanged;

  final String label;
  final String hint;
  final bool enabled;
  final String? Function(FurnitureMaterialLookupResult?)? validator;
  final AutovalidateMode? autovalidateMode;

  const FurnitureMaterialDropdown({
    super.key,
    required this.idCetakan,
    required this.idWarna,
    this.preselectId,
    this.onChanged,
    this.label = 'Furniture Material',
    this.hint = 'Pilih furniture material',
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<FurnitureMaterialDropdown> createState() => _FurnitureMaterialDropdownState();
}

class _FurnitureMaterialDropdownState extends State<FurnitureMaterialDropdown> {
  FurnitureMaterialLookupResult? _selected;

  int? _lastCetakan;
  int? _lastWarna;

  // ✅ placeholder "tidak ada data"
  static const int _noneId = 0;
  static const FurnitureMaterialLookupResult _noneItem = FurnitureMaterialLookupResult(
    idFurnitureMaterial: _noneId,
    nama: 'Tidak ada Furniture Material untuk cetakan & warna ini',
    itemCode: null,
    enable: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetch(force: true));
  }

  @override
  void didUpdateWidget(covariant FurnitureMaterialDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed =
        oldWidget.idCetakan != widget.idCetakan || oldWidget.idWarna != widget.idWarna;

    if (changed) {
      _selected = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFetch(force: true));
    }

    if (oldWidget.preselectId != widget.preselectId) {
      _selected = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyAutoSelectFromVm());
    }
  }

  Future<void> _maybeFetch({bool force = false}) async {
    final idCetakan = widget.idCetakan;
    final idWarna = widget.idWarna;

    final vm = context.read<FurnitureMaterialLookupViewModel>();

    if (idCetakan == null || idWarna == null) {
      _lastCetakan = null;
      _lastWarna = null;
      vm.clear();
      if (!mounted) return;
      setState(() => _selected = null);
      widget.onChanged?.call(null);
      return;
    }

    if (!force && _lastCetakan == idCetakan && _lastWarna == idWarna) return;
    _lastCetakan = idCetakan;
    _lastWarna = idWarna;

    await vm.resolve(idCetakan: idCetakan, idWarna: idWarna);
    if (!mounted) return;

    _applyAutoSelectFromVm();
  }

  void _applyAutoSelectFromVm() {
    final vm = context.read<FurnitureMaterialLookupViewModel>();

    // ✅ kalau empty => pilih placeholder & kirim null ke form (payload null)
    if (vm.isEmpty && vm.error.isEmpty) {
      setState(() => _selected = _noneItem);
      widget.onChanged?.call(null);
      return;
    }

    // ✅ kalau error => kosong (biar field bisa retry)
    if (vm.error.isNotEmpty) {
      setState(() => _selected = null);
      widget.onChanged?.call(null);
      return;
    }

    // ✅ normal
    final items = <FurnitureMaterialLookupResult>[];
    if (vm.result != null) items.add(vm.result!);

    FurnitureMaterialLookupResult? pick;
    if (items.isEmpty) {
      pick = null;
    } else if (widget.preselectId != null) {
      pick = items.firstWhere(
            (e) => e.idFurnitureMaterial == widget.preselectId,
        orElse: () => items.first,
      );
    } else {
      pick = items.first;
    }

    setState(() => _selected = pick);
    widget.onChanged?.call(pick);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FurnitureMaterialLookupViewModel>(
      builder: (_, vm, __) {
        // ✅ susun items:
        // - error: items kosong (biar komponen tampil error+retry)
        // - empty: items = [placeholder] (tanpa merah)
        // - ok: items = [result]
        final items = <FurnitureMaterialLookupResult>[];
        if (vm.error.isEmpty && vm.isEmpty && !vm.isLoading) {
          items.add(_noneItem);
        } else if (vm.result != null) {
          items.add(vm.result!);
        }

        final isEmptyMode = vm.error.isEmpty && vm.isEmpty && !vm.isLoading;

        return DropdownPlainField<FurnitureMaterialLookupResult>(
          items: items,
          value: _selected,

          // ✅ kalau emptyMode, dropdown tampil tapi tidak bisa dipilih (biar tidak misleading)
          enabled: widget.enabled && !vm.isLoading && vm.error.isEmpty && !isEmptyMode,

          onChanged: (widget.enabled && !isEmptyMode)
              ? (val) {
            setState(() => _selected = val);
            // kalau yang dipilih placeholder => kirim null
            if (val == null || val.idFurnitureMaterial == _noneId) {
              widget.onChanged?.call(null);
            } else {
              widget.onChanged?.call(val);
            }
          }
              : null,

          itemAsString: (x) => x.displayText,
          compareFn: (a, b) => a.idFurnitureMaterial == b.idFurnitureMaterial,

          label: widget.label,

          // ✅ kalau emptyMode, hint tidak dipakai karena ada selected value placeholder
          hint: widget.hint,

          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          isLoading: vm.isLoading,

          // ✅ merah hanya kalau error beneran
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () => _maybeFetch(force: true),
        );
      },
    );
  }
}
