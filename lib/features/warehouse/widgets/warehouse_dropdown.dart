// lib/features/warehouse/widgets/warehouse_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/warehouse_model.dart';
import '../view_model/warehouse_view_model.dart';

class WarehouseDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<MstWarehouse?>? onChanged;

  // filtering (server)
  final bool includeDisabled;
  final String? q;
  final String orderBy;
  final String orderDir;

  // UI & form
  final String label;
  final String hint;
  final bool enabled;
  final bool isExpanded;
  final double fieldHeight;
  final String? Function(MstWarehouse?)? validator;
  final AutovalidateMode? autovalidateMode;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final double popupMaxHeight;
  final EdgeInsetsGeometry contentPadding;

  // search UI (client)
  final bool showSearchBox;
  final String searchHint;

  const WarehouseDropdown({
    super.key,
    this.preselectId,
    this.onChanged,

    this.includeDisabled = false,
    this.q,
    this.orderBy = 'NamaWarehouse',
    this.orderDir = 'ASC',

    // UI
    this.label = 'Warehouse',
    this.hint = 'PILIH WAREHOUSE',
    this.enabled = true,
    this.isExpanded = true,
    this.fieldHeight = 40,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
    this.prefixIcon = Icons.warehouse_outlined,
    this.popupMaxHeight = 500,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

    // search UI
    this.showSearchBox = true,
    this.searchHint = 'Cari warehouse…',
  });

  @override
  State<WarehouseDropdown> createState() => _WarehouseDropdownState();
}

class _WarehouseDropdownState extends State<WarehouseDropdown> {
  MstWarehouse? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WarehouseDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      final vm = context.read<WarehouseViewModel>();
      vm.loadAll(
        includeDisabled: widget.includeDisabled,
        q: widget.q,
        orderBy: widget.orderBy,
        orderDir: widget.orderDir,
      );
    });
  }

  MstWarehouse? _findById(List<MstWarehouse> items, int? id) {
    if (id == null) return null;
    try {
      return items.firstWhere((e) => e.idWarehouse == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WarehouseViewModel>(
      builder: (context, vm, _) {
        if (_selected == null && vm.items.isNotEmpty) {
          _selected = _findById(vm.items, widget.preselectId);
        }

        return SearchDropdownField<MstWarehouse>(
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (w) => w.displayName,

          compareFn: (a, b) => a.idWarehouse == b.idWarehouse,

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
            final r = context.read<WarehouseViewModel>();
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
