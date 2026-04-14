import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/washing_type_model.dart';
import '../view_model/washing_type_view_model.dart';

class WashingTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<WashingType?>? onChanged;

  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  final String? Function(WashingType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const WashingTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Washing',
    this.icon = Icons.local_laundry_service_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<WashingTypeDropdown> createState() => _WashingTypeDropdownState();
}

class _WashingTypeDropdownState extends State<WashingTypeDropdown> {
  WashingType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<WashingTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list
            .where((e) => e.idWashing == widget.preselectId)
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
    return Consumer<WashingTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<WashingType>(
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (wt) {
            final code = (wt.itemCode ?? '').trim();
            if (code.isEmpty) return wt.nama;
            return '${wt.nama} [$code]';
          },
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis washing',
          enabled: widget.enabled,
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<WashingTypeViewModel>().ensureLoaded();
            if (!mounted) return;
            setState(() {});
          },
          showSearchBox: true,
          searchHint: 'Cari nama / item code...',
          popupMaxHeight: 500,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          compareFn: (a, b) => a.idWashing == b.idWashing,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.nama.toLowerCase().contains(q) ||
                (item.itemCode ?? '').toLowerCase().contains(q) ||
                item.idWashing.toString().contains(q);
          },
        );
      },
    );
  }
}
