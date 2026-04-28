import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/mst_barang_jadi_model.dart';
import '../view_model/mst_barang_jadi_view_model.dart';

class BarangJadiDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstBarangJadi?>? onChanged;

  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstBarangJadi?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  final bool showSearchBox;
  final String searchHint;

  const BarangJadiDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Barang Jadi',
    this.hint = 'PILIH JENIS',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.category_outlined,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 0,
    ),
    this.showSearchBox = true,
    this.searchHint = 'Cari jenis barang jadi…',
  });

  @override
  State<BarangJadiDropdown> createState() => _BarangJadiDropdownState();
}

class _BarangJadiDropdownState extends State<BarangJadiDropdown> {
  MstBarangJadi? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MstBarangJadiViewModel>().loadAll();
    });
  }

  MstBarangJadi? _findById(List<MstBarangJadi> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idJenis == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MstBarangJadiViewModel>(
      builder: (context, vm, _) {
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstBarangJadi>(
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (b) => b.displayName,
          compareFn: (a, b) => a.idJenis == b.idJenis,
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
          showSearchBox: widget.showSearchBox,
          searchHint: widget.searchHint,
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () => context.read<MstBarangJadiViewModel>().loadAll(),
        );
      },
    );
  }
}
