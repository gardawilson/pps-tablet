import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/mixer_type_model.dart';
import '../view_model/mixer_type_view_model.dart';

class MixerTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MixerType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (optional)
  final String? Function(MixerType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const MixerTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Mixer',
    this.icon = Icons.blender_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<MixerTypeDropdown> createState() => _MixerTypeDropdownState();
}

class _MixerTypeDropdownState extends State<MixerTypeDropdown> {
  MixerType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<MixerTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found =
        vm.list.where((e) => e.idMixer == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MixerTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<MixerType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (mt) => mt.jenis,

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis mixer',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<MixerTypeViewModel>().ensureLoaded();
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
          compareFn: (a, b) => a.idMixer == b.idMixer,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.jenis.toLowerCase().contains(q) ||
                item.idMixer.toString().contains(q);
          },
        );
      },
    );
  }
}
