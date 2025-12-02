import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/gilingan_type_model.dart';
import '../view_model/gilingan_type_view_model.dart';

class GilinganTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<GilinganType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (optional)
  final String? Function(GilinganType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const GilinganTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Gilingan',
    this.icon = Icons.settings_input_component_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<GilinganTypeDropdown> createState() => _GilinganTypeDropdownState();
}

class _GilinganTypeDropdownState extends State<GilinganTypeDropdown> {
  GilinganType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<GilinganTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list
            .where((e) => e.idGilingan == widget.preselectId)
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
    return Consumer<GilinganTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<GilinganType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (gt) => gt.namaGilingan,

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis gilingan',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<GilinganTypeViewModel>().ensureLoaded();
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
          compareFn: (a, b) => a.idGilingan == b.idGilingan,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.namaGilingan.toLowerCase().contains(q) ||
                item.idGilingan.toString().contains(q);
          },
        );
      },
    );
  }
}
