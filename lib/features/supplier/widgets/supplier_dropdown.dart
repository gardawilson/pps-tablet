// lib/features/supplier/widgets/supplier_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/supplier_model.dart';
import '../view_model/supplier_view_model.dart';

class SupplierDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstSupplier?>? onChanged;
  final bool enabled;
  final String label;
  final String hint;
  final AutovalidateMode? autovalidateMode;
  final String? Function(MstSupplier?)? validator;
  final IconData? prefixIcon;
  final EdgeInsetsGeometry contentPadding;

  const SupplierDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.enabled = true,
    this.label = 'Supplier',
    this.hint = 'Pilih supplier',
    this.autovalidateMode,
    this.validator,
    this.prefixIcon,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 0,
    ),
  });

  @override
  State<SupplierDropdown> createState() => _SupplierDropdownState();
}

class _SupplierDropdownState extends State<SupplierDropdown> {
  MstSupplier? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierViewModel>().loadAll();
    });
  }

  MstSupplier? _findById(List<MstSupplier> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idSupplier == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierViewModel>(
      builder: (context, vm, _) {
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstSupplier>(
          key: ValueKey(widget.preselectId),
          items: vm.items,
          value: _selected,
          onChanged: widget.enabled
              ? (val) {
                  setState(() => _selected = val);
                  widget.onChanged?.call(val);
                }
              : null,
          itemAsString: (s) => s.namaSupplier,
          compareFn: (a, b) => a.idSupplier == b.idSupplier,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon ?? Icons.local_shipping_outlined,
          enabled: widget.enabled,
          autovalidateMode: widget.autovalidateMode,
          validator: widget.validator,
          showSearchBox: true,
          searchHint: 'Cari supplier…',
          contentPadding: widget.contentPadding,
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: vm.loadAll,
        );
      },
    );
  }
}
