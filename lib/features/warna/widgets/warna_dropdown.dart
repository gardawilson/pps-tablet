// lib/features/warna/widgets/warna_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/warna_model.dart';
import '../view_model/warna_view_model.dart';

class WarnaDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstWarna?>? onChanged;

  // UI & form
  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstWarna?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  // search UI
  final bool showSearchBox;
  final String searchHint;

  const WarnaDropdown({
    super.key,
    this.preselectId,
    this.onChanged,

    // UI
    this.label = 'Warna',
    this.hint = 'PILIH WARNA',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.color_lens_outlined,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

    // search UI
    this.showSearchBox = true,
    this.searchHint = 'Cari warna…',
  });

  @override
  State<WarnaDropdown> createState() => _WarnaDropdownState();
}

class _WarnaDropdownState extends State<WarnaDropdown> {
  MstWarna? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarnaViewModel>().loadAll();
    });
  }

  MstWarna? _findById(List<MstWarna> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idWarna == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WarnaViewModel>(
      builder: (context, vm, _) {
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstWarna>(
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (x) => x.displayName,
          compareFn: (a, b) => a.idWarna == b.idWarna,

          // UI
          label: widget.label,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon,
          enabled: widget.enabled,
          isExpanded: widget.isExpanded,
          fieldHeight: widget.fieldHeight,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          helperText: widget.helperText,
          errorText: widget.errorText,
          popupMaxHeight: widget.popupMaxHeight,
          contentPadding: widget.contentPadding,

          // search
          showSearchBox: widget.showSearchBox,
          searchHint: widget.searchHint,

          // states
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () => context.read<WarnaViewModel>().loadAll(),
        );
      },
    );
  }
}
