import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/packing_type_model.dart';
import '../view_model/packing_type_view_model.dart';

class PackingTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<PackingType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (optional)
  final String? Function(PackingType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const PackingTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Packing',
    this.icon = Icons.category_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<PackingTypeDropdown> createState() => _PackingTypeDropdownState();
}

class _PackingTypeDropdownState extends State<PackingTypeDropdown> {
  PackingType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<PackingTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found =
        vm.list.where((e) => e.idBj == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PackingTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<PackingType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (p) {
            // tampilkan NamaBJ + ItemCode kalau ada
            final code = (p.itemCode ?? '').trim();
            if (code.isEmpty) return p.namaBj;
            return '$code | ${p.namaBj}';
          },

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih barang jadi (packing)',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<PackingTypeViewModel>().ensureLoaded();
            if (!mounted) return;
            setState(() {}); // refresh UI
          },

          // SEARCH POPUP
          showSearchBox: true,
          searchHint: 'Cari nama / item code / ID...',
          popupMaxHeight: 500,

          // FORM
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          // COMPARE/FILTER
          compareFn: (a, b) => a.idBj == b.idBj,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.namaBj.toLowerCase().contains(q) ||
                (item.itemCode ?? '').toLowerCase().contains(q) ||
                item.idBj.toString().contains(q);
          },
        );
      },
    );
  }
}
