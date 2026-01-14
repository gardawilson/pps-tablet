// lib/features/pembeli/widgets/pembeli_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart'; // ⬅️ use the SEARCH version
import '../model/pembeli_model.dart';
import '../view_model/pembeli_view_model.dart';

class PembeliDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstPembeli?>? onChanged;

  // filtering (server)
  final bool includeDisabled;
  final String? q;           // optional query (passed to BE)
  final String orderBy;      // default 'NamaPembeli'
  final String orderDir;     // 'ASC' | 'DESC'

  // UI & form
  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstPembeli?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  // search UI (client)
  final bool showSearchBox;
  final String searchHint;

  const PembeliDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.includeDisabled = false,
    this.q,
    this.orderBy = 'NamaPembeli',
    this.orderDir = 'ASC',

    // UI
    this.label = 'Pembeli',
    this.hint = 'PILIH PEMBELI',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.storefront_outlined,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

    // search UI
    this.showSearchBox = true,
    this.searchHint = 'Cari pembeli…',
  });

  @override
  State<PembeliDropdown> createState() => _PembeliDropdownState();
}

class _PembeliDropdownState extends State<PembeliDropdown> {
  MstPembeli? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PembeliDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // reload data if filter props changed
    if (oldWidget.includeDisabled != widget.includeDisabled ||
        oldWidget.q != widget.q ||
        oldWidget.orderBy != widget.orderBy ||
        oldWidget.orderDir != widget.orderDir) {
      _selected = null;
      _load();
    }
  }

  void _load() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PembeliViewModel>();
      vm.loadAll(
        includeDisabled: widget.includeDisabled,
        q: widget.q,
        orderBy: widget.orderBy,
        orderDir: widget.orderDir,
      );
    });
  }

  MstPembeli? _findById(List<MstPembeli> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idPembeli == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PembeliViewModel>(
      builder: (context, vm, _) {
        // apply preselect once when data arrives
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstPembeli>(
          // data
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (p) => p.displayName,

          // compare & filter
          compareFn: (a, b) => a.idPembeli == b.idPembeli,

          // UI & form
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

          // search popup UI
          showSearchBox: widget.showSearchBox,
          searchHint: widget.searchHint,

          // states
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isNotEmpty ? vm.error : null,
          onRetry: () {
            final r = context.read<PembeliViewModel>();
            r.loadAll(
              includeDisabled: widget.includeDisabled,
              q: widget.q,
              orderBy: widget.orderBy,
              orderDir: widget.orderDir,
            );
          },
        );
      },
    );
  }
}
