// lib/features/furniture_material/widgets/furniture_material_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/dropdown_field.dart';
import '../model/furniture_material_lookup_model.dart';
import '../view_model/furniture_material_lookup_view_model.dart';

class FurnitureMaterialDropdown extends StatefulWidget {
  final int? idCetakan;
  final int? idWarna;

  /// if you want auto-pick a specific id (when list has more than 1)
  final int? preselectId;

  /// IMPORTANT:
  /// - when user picks "Tidak ada" => onChanged(null)
  /// - when user picks real item    => onChanged(item)
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
  State<FurnitureMaterialDropdown> createState() =>
      _FurnitureMaterialDropdownState();
}

class _FurnitureMaterialDropdownState extends State<FurnitureMaterialDropdown> {
  FurnitureMaterialLookupResult? _selected;

  int? _lastCetakan;
  int? _lastWarna;

  // =========================================================
  // ✅ HARD-CODED DEFAULT ITEM: "Tidak ada"
  // - keep ID sentinel (0) because model id is non-nullable int
  // - whenever selected => send null to form/payload
  // =========================================================
  static const int _noneId = 0;
  static const FurnitureMaterialLookupResult _noneItem =
  FurnitureMaterialLookupResult(
    idFurnitureMaterial: _noneId,
    nama: 'Tidak ada',
    itemCode: null,
    enable: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeFetch(force: true));
  }

  @override
  void didUpdateWidget(covariant FurnitureMaterialDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    final changed = oldWidget.idCetakan != widget.idCetakan ||
        oldWidget.idWarna != widget.idWarna;

    if (changed) {
      _selected = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _maybeFetch(force: true));
    }

    if (oldWidget.preselectId != widget.preselectId) {
      _selected = null;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _applyAutoSelectFromVm());
    }
  }

  Future<void> _maybeFetch({bool force = false}) async {
    final idCetakan = widget.idCetakan;
    final idWarna = widget.idWarna;

    final vm = context.read<FurnitureMaterialLookupViewModel>();

    // If parents not selected yet => clear VM and select "Tidak ada" (payload null)
    if (idCetakan == null || idWarna == null) {
      _lastCetakan = null;
      _lastWarna = null;
      vm.clear();

      if (!mounted) return;
      setState(() => _selected = _noneItem);
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

    // ✅ If error => clear selection (let user retry / show error)
    if (vm.error.isNotEmpty) {
      if (!mounted) return;
      setState(() => _selected = null);
      widget.onChanged?.call(null);
      return;
    }

    // ✅ Build list from VM (LIST)
    final items = <FurnitureMaterialLookupResult>[_noneItem, ...vm.items];

    FurnitureMaterialLookupResult pick;

    // ✅ If preselectId provided and exists => select it, else default to "Tidak ada"
    if (widget.preselectId != null) {
      pick = items.firstWhere(
            (e) => e.idFurnitureMaterial == widget.preselectId,
        orElse: () => _noneItem,
      );
    } else {
      // Default selection is "Tidak ada" (payload null)
      pick = _noneItem;
    }

    if (!mounted) return;
    setState(() => _selected = pick);

    // ✅ If "Tidak ada" => send null
    if (pick.idFurnitureMaterial == _noneId) {
      widget.onChanged?.call(null);
    } else {
      widget.onChanged?.call(pick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FurnitureMaterialLookupViewModel>(
      builder: (_, vm, __) {
        final hasError = vm.error.isNotEmpty;

        // ✅ items always include "Tidak ada" (when not error)
        final items = <FurnitureMaterialLookupResult>[];
        if (!hasError) {
          items.add(_noneItem);
          items.addAll(vm.items); // ✅ LIST
        }

        // ✅ Safety: kalau _selected tidak ada di items (mis. data berubah),
        // set null supaya Dropdown tidak error "value not in items".
        final value = (_selected != null &&
            items.any((e) => e.idFurnitureMaterial == _selected!.idFurnitureMaterial))
            ? _selected
            : null;

        // ✅ enabled rules:
        // - must be widget.enabled
        // - not loading
        // - if error, keep enabled false (user uses retry button)
        final effectiveEnabled = widget.enabled && !vm.isLoading && !hasError;

        return DropdownPlainField<FurnitureMaterialLookupResult>(
          items: items,
          value: value,

          enabled: effectiveEnabled,

          onChanged: effectiveEnabled
              ? (val) {
            setState(() => _selected = val);

            // ✅ map "Tidak ada" -> null payload
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
          hint: widget.hint,

          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          isLoading: vm.isLoading,

          // ✅ error UI
          fetchError: hasError,
          fetchErrorText: hasError ? vm.error : null,
          onRetry: () => _maybeFetch(force: true),
        );
      },
    );
  }
}
