// lib/features/reject_type/widgets/reject_type_dropdown.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/reject_type_model.dart';
import '../view_model/packing_type_view_model.dart';

class RejectTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<RejectType?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  // form validator (optional)
  final String? Function(RejectType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const RejectTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Reject',
    this.icon = Icons.report_problem_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<RejectTypeDropdown> createState() => _RejectTypeDropdownState();
}

class _RejectTypeDropdownState extends State<RejectTypeDropdown> {
  RejectType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<RejectTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found =
        vm.list.where((e) => e.idReject == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RejectTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<RejectType>(
          // DATA
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (r) {
            // tampilkan NamaReject + ItemCode kalau ada
            final code = (r.itemCode ?? '').trim();
            if (code.isEmpty) return r.namaReject;
            return '$code | ${r.namaReject}';
          },

          // UI
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis reject',
          enabled: widget.enabled,

          // STATE
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<RejectTypeViewModel>().ensureLoaded();
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
          compareFn: (a, b) => a.idReject == b.idReject,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.namaReject.toLowerCase().contains(q) ||
                (item.itemCode ?? '').toLowerCase().contains(q) ||
                item.idReject.toString().contains(q);
          },
        );
      },
    );
  }
}
