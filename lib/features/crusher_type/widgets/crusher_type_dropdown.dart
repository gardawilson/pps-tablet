import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/crusher_type_model.dart';
import '../view_model/crusher_type_view_model.dart';

class CrusherTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<CrusherType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (opsional)
  final String? Function(CrusherType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const CrusherTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Crusher',
    this.icon = Icons.construction_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<CrusherTypeDropdown> createState() => _CrusherTypeDropdownState();
}

class _CrusherTypeDropdownState extends State<CrusherTypeDropdown> {
  CrusherType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<CrusherTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list.where((e) => e.idCrusher == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CrusherTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<CrusherType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (ct) => ct.namaCrusher,

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis crusher',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<CrusherTypeViewModel>().ensureLoaded();
            if (!mounted) return;
            setState(() {}); // refresh tampilan
          },

          // SEARCH POPUP
          showSearchBox: true,
          searchHint: 'Cari nama / ID...',
          popupMaxHeight: 500,

          // FORM
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          // COMPARE/FILTER
          compareFn: (a, b) => a.idCrusher == b.idCrusher,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.namaCrusher.toLowerCase().contains(q) ||
                item.idCrusher.toString().contains(q);
          },
        );
      },
    );
  }
}
