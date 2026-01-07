// lib/features/cetakan/widgets/cetakan_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/mst_cetakan_model.dart';
import '../view_model/cetakan_view_model.dart';

class CetakanDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstCetakan?>? onChanged;

  // server filter
  final int? idBj;

  // UI & form
  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstCetakan?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  // search UI
  final bool showSearchBox;
  final String searchHint;

  const CetakanDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.idBj,

    // UI
    this.label = 'Cetakan',
    this.hint = 'PILIH CETAKAN',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.grid_view_rounded,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

    // search UI
    this.showSearchBox = true,
    this.searchHint = 'Cari cetakan…',
  });

  @override
  State<CetakanDropdown> createState() => _CetakanDropdownState();
}

class _CetakanDropdownState extends State<CetakanDropdown> {
  MstCetakan? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CetakanDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // reload if filter changed
    if (oldWidget.idBj != widget.idBj) {
      _selected = null;
      _load();
    }
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CetakanViewModel>();
      vm.loadAll(idBj: widget.idBj);
    });
  }

  MstCetakan? _findById(List<MstCetakan> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idCetakan == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CetakanViewModel>(
      builder: (context, vm, _) {
        // apply preselect once when data arrives
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstCetakan>(
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (x) => x.displayName,
          compareFn: (a, b) => a.idCetakan == b.idCetakan,

          // UI
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
          popupMaxHeight: widget.popupMaxHeight,
          contentPadding: widget.contentPadding,

          // search
          showSearchBox: widget.showSearchBox,
          searchHint: widget.searchHint,

          // states
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () {
            final r = context.read<CetakanViewModel>();
            r.loadAll(idBj: widget.idBj);
          },
        );
      },
    );
  }
}
