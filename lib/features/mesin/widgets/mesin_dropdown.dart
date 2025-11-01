// lib/features/mesin/widgets/mesin_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/dropdown_field.dart';
import '../model/mesin_model.dart';
import '../view_model/mesin_view_model.dart';

class MesinDropdown extends StatefulWidget {
  final String bagian;

  /// Optional: preselect row by its id
  final int? preselectId;

  /// Emit selected mesin (or null)
  final ValueChanged<MstMesin?>? onChanged;

  // UI props
  final String label;
  final String hintText;
  final bool enabled;

  // Data props
  final bool includeDisabled;

  // Form props
  final String? Function(MstMesin?)? validator;
  final AutovalidateMode? autovalidateMode;

  const MesinDropdown({
    super.key,
    required this.bagian,
    this.preselectId,
    this.onChanged,
    this.label = 'Mesin',
    this.hintText = 'PILIH MESIN',
    this.enabled = true,
    this.includeDisabled = false,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<MesinDropdown> createState() => _MesinDropdownState();
}

class _MesinDropdownState extends State<MesinDropdown> {
  MstMesin? _selected;

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<MesinViewModel>();
      vm.fetchByBagian(widget.bagian, includeDisabled: widget.includeDisabled).then((_) {
        _syncSelectedFromVM();
      });
    });
  }

  @override
  void didUpdateWidget(covariant MesinDropdown old) {
    super.didUpdateWidget(old);

    final vm = context.read<MesinViewModel>();

    // If bagian/includeDisabled changes, refetch
    final bagianChanged = widget.bagian != old.bagian;
    final includeChanged = widget.includeDisabled != old.includeDisabled;
    if (bagianChanged || includeChanged) {
      vm.fetchByBagian(widget.bagian, includeDisabled: widget.includeDisabled).then((_) {
        _syncSelectedFromVM();
      });
      return; // will resync after fetch
    }

    // If preselectId changed, resync selection
    if (widget.preselectId != old.preselectId) {
      _syncSelectedFromVM();
    } else {
      // If items changed outside, try to keep selection object in-sync by id
      _rebindSelectedToCurrentItems();
    }
  }

  void _syncSelectedFromVM() {
    final vm = context.read<MesinViewModel>();
    if (widget.preselectId != null) {
      final found = vm.items.firstWhere(
            (m) => _idOf(m) == widget.preselectId,
        orElse: () => null as MstMesin, // will throw; handle with try/catch
      );
      setState(() {
        _selected = found;
      });
      return;
    }
    // No explicit preselect: keep current if exists in new list
    _rebindSelectedToCurrentItems();
  }

  void _rebindSelectedToCurrentItems() {
    final vm = context.read<MesinViewModel>();
    if (_selected == null) return;
    final current = vm.items.where((m) => _idOf(m) == _idOf(_selected!)).toList();
    setState(() {
      _selected = current.isNotEmpty ? current.first : null;
    });
  }

  int _idOf(MstMesin m) {
    // 🔧 Adjust if your model uses a different id field
    return m.idMesin;
  }

  String _nameOf(MstMesin m) {
    // 🔧 Adjust if your model uses a different display field
    return m.namaMesin;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MesinViewModel>(
      builder: (context, vm, _) {
        return DropdownPlainField<MstMesin>(
          items: vm.items,
          value: _selected,
          onChanged: (val) {
            setState(() => _selected = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (m) => _nameOf(m),
          compareFn: (a, b) => _idOf(a) == _idOf(b),

          // UX & form
          label: widget.label,
          hint: widget.hintText,
          enabled: widget.enabled,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,

          // Loading / error reflection from VM
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error,
          onRetry: () {
            vm.fetchByBagian(widget.bagian, includeDisabled: widget.includeDisabled).then((_) {
              _syncSelectedFromVM();
            });
          },
        );
      },
    );
  }
}
