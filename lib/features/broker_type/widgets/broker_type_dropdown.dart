import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/search_dropdown_field.dart';
import '../model/broker_type_model.dart';
import '../view_model/broker_type_view_model.dart';

class BrokerTypeDropdown extends StatefulWidget {
  final int? preselectId;
  final ValueChanged<BrokerType?>? onChanged;

  final String label;
  final IconData icon;
  final String? hintText;
  final bool enabled;

  final String? Function(BrokerType?)? validator;
  final AutovalidateMode? autovalidateMode;

  const BrokerTypeDropdown({
    super.key,
    this.preselectId,
    this.onChanged,
    this.label = 'Jenis Broker',
    this.icon = Icons.handshake_outlined,
    this.hintText,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
  });

  @override
  State<BrokerTypeDropdown> createState() => _BrokerTypeDropdownState();
}

class _BrokerTypeDropdownState extends State<BrokerTypeDropdown> {
  BrokerType? _value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<BrokerTypeViewModel>();
      await vm.ensureLoaded();
      if (!mounted) return;

      if (widget.preselectId != null && vm.list.isNotEmpty) {
        final found = vm.list
            .where((e) => e.idBroker == widget.preselectId)
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
    return Consumer<BrokerTypeViewModel>(
      builder: (context, vm, _) {
        final exists = vm.list.any((e) => e == _value);
        final safeValue = exists ? _value : null;

        return SearchDropdownField<BrokerType>(
          items: vm.list,
          value: safeValue,
          onChanged: (val) {
            setState(() => _value = val);
            widget.onChanged?.call(val);
          },
          itemAsString: (bt) {
            final code = (bt.itemCode ?? '').trim();
            if (code.isEmpty) return bt.nama;
            return '${bt.nama} [$code]';
          },
          label: widget.label,
          prefixIcon: widget.icon,
          hint: widget.hintText ?? 'Pilih jenis broker',
          enabled: widget.enabled,
          isLoading: vm.isLoading,
          fetchError: vm.error.isNotEmpty,
          fetchErrorText: vm.error.isEmpty ? null : vm.error,
          onRetry: () async {
            await context.read<BrokerTypeViewModel>().ensureLoaded();
            if (!mounted) return;
            setState(() {});
          },
          showSearchBox: true,
          searchHint: 'Cari nama / item code...',
          popupMaxHeight: 500,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          compareFn: (a, b) => a.idBroker == b.idBroker,
          filterFn: (item, filter) {
            final q = filter.toLowerCase();
            return item.nama.toLowerCase().contains(q) ||
                (item.itemCode ?? '').toLowerCase().contains(q) ||
                item.idBroker.toString().contains(q);
          },
        );
      },
    );
  }
}
