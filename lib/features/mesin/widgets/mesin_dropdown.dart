import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/dropdown_field.dart';
import '../model/mesin_model.dart';
import '../view_model/mesin_view_model.dart';

class MesinDropdown extends StatefulWidget {
  /// Wajib: filter by IdBagianMesin (integer)
  final int idBagianMesin;

  /// Opsional: preselect by IdMesin
  final int? preselectId;

  /// Callback ketika nilai berubah
  final ValueChanged<MstMesin?>? onChanged;

  /// Sertakan mesin non-aktif? default false
  final bool includeDisabled;

  /// ---------- UI & Form ----------
  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstMesin?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText; // override error
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  const MesinDropdown({
    super.key,
    required this.idBagianMesin,
    this.preselectId,
    this.onChanged,
    this.includeDisabled = false,
    this.label = 'Mesin',
    this.hint = 'PILIH MESIN',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.precision_manufacturing_outlined,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  });

  @override
  State<MesinDropdown> createState() => _MesinDropdownState();
}

class _MesinDropdownState extends State<MesinDropdown> {
  MstMesin? _selected; // state lokal supaya dropdown terkontrol

  @override
  void initState() {
    super.initState();
    _ensureDataLoaded();
  }

  @override
  void didUpdateWidget(covariant MesinDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idBagianMesin != widget.idBagianMesin ||
        oldWidget.includeDisabled != widget.includeDisabled) {
      _selected = null; // reset saat ganti bagian
      _ensureDataLoaded();
    }
  }

  void _ensureDataLoaded() {
    // Jalankan fetch setelah frame agar tidak trigger notify saat build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MesinViewModel>();
      vm.fetchByIdBagian(
        widget.idBagianMesin,
        includeDisabled: widget.includeDisabled,
      );
    });
  }

  /// Temukan item by IdMesin dari list
  MstMesin? _findById(List<MstMesin> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idMesin == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MesinViewModel>(
      builder: (context, vm, _) {
        // Saat data baru datang, jika belum ada pilihan lokal, coba preselect
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        final items = vm.items;

        return DropdownPlainField<MstMesin>(
          // data
          items: items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (item) {
            final suffix = item.enable ? '' : ' (non-aktif)';
            return '${item.namaMesin}$suffix';
          },

          // compare
          compareFn: (a, b) => a.idMesin == b.idMesin,

          // UX & form
          label: widget.label,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon,
          enabled: widget.enabled,
          isExpanded: widget.isExpanded,
          fieldHeight: widget.fieldHeight,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          helperText: widget.helperText,
          errorText: widget.errorText,

          // state → mapping dari VM
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () {
            final r = context.read<MesinViewModel>();
            r.fetchByIdBagian(
              widget.idBagianMesin,
              includeDisabled: widget.includeDisabled,
            );
          },

          // style
          popupMaxHeight: widget.popupMaxHeight,
          contentPadding: widget.contentPadding,
        );
      },
    );
  }
}
