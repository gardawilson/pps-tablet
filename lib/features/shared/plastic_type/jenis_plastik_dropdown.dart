// features/shared/plastic_type/presentation/jenis_plastik_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'jenis_plastik_view_model.dart';
import 'jenis_plastik_model.dart';
import '../../../common/widgets/search_dropdown_field.dart';

class JenisPlastikDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<JenisPlastik?>? onChanged;

  // UI props
  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled; // <- bisa disable saat edit

  // data
  final bool onlyActive;

  // form validator (opsional)
  final String? Function(JenisPlastik?)? validator;
  final AutovalidateMode? autovalidateMode;

  const JenisPlastikDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Plastik',
    this.icon = Icons.category,
    this.hintText,
    this.enabled = true,
    this.onlyActive = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<JenisPlastikDropdown> createState() => _JenisPlastikDropdownState();
}

class _JenisPlastikDropdownState extends State<JenisPlastikDropdown> {
  JenisPlastik? _value;

  @override
  void initState() {
    super.initState();
    // Pastikan data tersedia lalu preselect
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<JenisPlastikViewModel>();
      await vm.ensureLoaded(onlyActive: widget.onlyActive);
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list.where((e) => e.idJenisPlastik == widget.preselectId).toList();
        if (found.isNotEmpty) {
          setState(() => _value = found.first);
          widget.onChanged?.call(_value);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JenisPlastikViewModel>(
      builder: (context, vm, _) {
        // Kalau value sekarang tak ada di list (mis. data refresh), null-kan
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<JenisPlastik>(
          // ====== DATA ======
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (jp) => jp.jenis,

          // ====== UI ======
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis plastik',
          enabled: widget.enabled,

          // ====== STATE ======
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<JenisPlastikViewModel>().ensureLoaded(onlyActive: widget.onlyActive);
            if (!mounted) return;
            setState(() {}); // refresh tampilan
          },

          // ====== SEARCH POPUP ======
          showSearchBox: true,
          searchHint: 'Cari jenis / ID...',
          popupMaxHeight: 500,

          // ====== FORM VALIDATION ======
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          // ====== COMPARE/FILTER (opsional tapi disarankan) ======
          compareFn: (a, b) => a.idJenisPlastik == b.idJenisPlastik,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.jenis.toLowerCase().contains(q) ||
                item.idJenisPlastik.toString().contains(q);
          },
        );
      },
    );
  }
}
