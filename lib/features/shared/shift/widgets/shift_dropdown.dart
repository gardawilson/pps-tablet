import 'package:flutter/material.dart';

import '../../../../common/widgets/dropdown_field.dart';

/// Model sederhana utk item shift (id + label)
class ShiftOption {
  final int id;
  final String label;
  const ShiftOption(this.id, this.label);
}

/// Tiga opsi shift (hardcoded)
const List<ShiftOption> kShiftItems = <ShiftOption>[
  ShiftOption(1, 'Shift 1'),
  ShiftOption(2, 'Shift 2'),
  ShiftOption(3, 'Shift 3'),
];

class ShiftDropdown extends StatefulWidget {
  /// preselect by id (1/2/3)
  final int? preselectId;

  /// Callback saat berubah (kembalikan seluruh object)
  final ValueChanged<ShiftOption?>? onChanged;

  /// Alternatif callback kalau cuma perlu id
  final ValueChanged<int?>? onChangedId;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (opsional)
  final String? Function(ShiftOption?)? validator;
  final AutovalidateMode? autovalidateMode;

  // error override optional (jika mau control error dari luar)
  final String? errorText;

  const ShiftDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.onChangedId,
    this.label = 'Shift',
    this.icon = Icons.schedule,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
    this.errorText,
  });

  @override
  State<ShiftDropdown> createState() => _ShiftDropdownState();
}

class _ShiftDropdownState extends State<ShiftDropdown> {
  ShiftOption? _value;

  @override
  void initState() {
    super.initState();
    _seedFromPreselect();
  }

  @override
  void didUpdateWidget(covariant ShiftDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sinkron bila preselectId berubah dari parent
    if (oldWidget.preselectId != widget.preselectId) {
      _seedFromPreselect();
    }
  }

  void _seedFromPreselect() {
    if (widget.preselectId != null) {
      final found = kShiftItems.where((e) => e.id == widget.preselectId).toList();
      _value = found.isNotEmpty ? found.first : null;
    } else {
      _value = null;
    }
    // Beritahu parent nilai awal (optional)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged?.call(_value);
      widget.onChangedId?.call(_value?.id);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan value valid terhadap list
    final exists = kShiftItems.any((e) => e.id == _value?.id);
    final safeValue = exists ? _value : null;

    return DropdownPlainField<ShiftOption>(
      // ===== DATA =====
      items: kShiftItems,
      value: safeValue,
      onChanged: (val) {
        setState(() => _value = val);
        widget.onChanged?.call(val);
        widget.onChangedId?.call(val?.id);
      },
      itemAsString: (s) => s.label,

      // ===== UI =====
      label: widget.label,
      hint: widget.hintText ?? 'Pilih shift',
      prefixIcon: widget.icon,
      enabled: widget.enabled,
      isExpanded: true,
      fieldHeight: 40,
      popupMaxHeight: 320,

      // ===== VALIDATION =====
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      errorText: widget.errorText,

      // ===== COMPARE =====
      compareFn: (a, b) => a.id == b.id,

      // ===== STATE (tak pakai API) =====
      isLoading: false,
      fetchError: false,
      fetchErrorText: null,
      onRetry: null,
    );
  }
}
