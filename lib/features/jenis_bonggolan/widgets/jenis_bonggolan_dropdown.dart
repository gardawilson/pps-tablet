// lib/features/shared/bonggolan_type/presentation/jenis_bonggolan_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../../common/widgets/search_dropdown_field.dart';
import '../model/jenis_bonggolan_model.dart';
import '../view_model/jenis_bonggolan_view_model.dart';

class JenisBonggolanDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<JenisBonggolan?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (opsional)
  final String? Function(JenisBonggolan?)? validator;
  final AutovalidateMode? autovalidateMode;

  const JenisBonggolanDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Bonggolan',
    this.icon = Icons.category,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<JenisBonggolanDropdown> createState() => _JenisBonggolanDropdownState();
}

class _JenisBonggolanDropdownState extends State<JenisBonggolanDropdown> {
  JenisBonggolan? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<JenisBonggolanViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list.where((e) => e.idBonggolan == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JenisBonggolanViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<JenisBonggolan>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (jb) => jb.namaBonggolan,

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis bonggolan',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<JenisBonggolanViewModel>().ensureLoaded();
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
          compareFn: (a, b) => a.idBonggolan == b.idBonggolan,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.namaBonggolan.toLowerCase().contains(q) ||
                item.idBonggolan.toString().contains(q);
          },
        );
      },
    );
  }
}
