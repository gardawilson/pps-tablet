import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/regu_model.dart';
import '../view_model/regu_view_model.dart';

class ReguDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstRegu?>? onChanged;
  final bool enabled;
  final String label;
  final String hint;
  final AutovalidateMode? autovalidateMode;
  final String? Function(MstRegu?)? validator;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final bool showSearchBox;
  final String searchHint;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  const ReguDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.enabled = true,
    this.label = 'Regu',
    this.hint = 'Pilih regu',
    this.autovalidateMode,
    this.validator,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.showSearchBox = true,
    this.searchHint = 'Cari regu…',
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  });

  @override
  State<ReguDropdown> createState() => _ReguDropdownState();
}

class _ReguDropdownState extends State<ReguDropdown> {
  MstRegu? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  MstRegu? _findById(List<MstRegu> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idRegu == id);
    } catch (_) {
      return null;
    }
  }

  void _load() {
    final vm = context.read<ReguViewModel>();
    vm.loadAll();
  }

  @override
  void didUpdateWidget(covariant ReguDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preselectId != oldWidget.preselectId) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReguViewModel>(
      builder: (context, vm, _) {
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstRegu>(
          key: ValueKey(widget.preselectId),
          items: vm.items,
          value: _selected,
          onChanged: widget.enabled
              ? (val) {
                  setState(() => _selected = val);
                  widget.onChanged?.call(val);
                }
              : null,
          itemAsString: (regu) => regu.displayName,
          compareFn: (a, b) => a.idRegu == b.idRegu,
          label: widget.label,
          hint: widget.hint,
          prefixIcon: widget.prefixIcon ?? Icons.groups,
          enabled: widget.enabled,
          autovalidateMode: widget.autovalidateMode,
          validator: widget.validator,
          helperText: widget.helperText,
          errorText: widget.errorText,
          showSearchBox: widget.showSearchBox,
          searchHint: widget.searchHint,
          popupMaxHeight: widget.popupMaxHeight,
          contentPadding: widget.contentPadding,
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: vm.loadAll,
        );
      },
    );
  }
}
