// lib/features/furniture_wip_type/widgets/furniture_wip_type_dropdown.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/furniture_wip_type_model.dart';
import '../view_model/furniture_wip_type_view_model.dart';

class FurnitureWipTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<FurnitureWipType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (optional)
  final String? Function(FurnitureWipType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const FurnitureWipTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Furniture WIP',
    this.icon = Icons.category_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<FurnitureWipTypeDropdown> createState() =>
      _FurnitureWipTypeDropdownState();
}

class _FurnitureWipTypeDropdownState extends State<FurnitureWipTypeDropdown> {
  FurnitureWipType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<FurnitureWipTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list
            .where((e) => e.idCabinetWip == widget.preselectId)
            .toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FurnitureWipTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<FurnitureWipType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          // sesuaikan dengan nama field di model kamu
          itemAsString: (fw) => fw.nama,

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih furniture WIP',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<FurnitureWipTypeViewModel>().ensureLoaded();
            if (!mounted) return;
            setState(() {}); // refresh UI
          },

          // SEARCH POPUP
          showSearchBox: true,
          searchHint: 'Cari nama / ID...',
          popupMaxHeight: 500,

          // FORM
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          // COMPARE/FILTER
          compareFn: (a, b) => a.idCabinetWip == b.idCabinetWip,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.nama.toLowerCase().contains(q) ||
                item.idCabinetWip.toString().contains(q);
          },
        );
      },
    );
  }
}
