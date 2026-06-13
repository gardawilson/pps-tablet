// lib/features/production/inject/widgets/inject_sak_picker_dialog.dart
// Thin wrapper around ProductionSakPickerDialog for InjectProductionInputViewModel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/production_sak_picker_dialog.dart';
import '../view_model/inject_production_input_view_model.dart';

class InjectSakPickerDialog extends StatelessWidget {
  final String noProduksi;

  const InjectSakPickerDialog({super.key, required this.noProduksi});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InjectProductionInputViewModel>();
    return ProductionSakPickerDialog(
      noProduksi: noProduksi,
      isPartialMode: false,
      vm: vm,
      getLookup: () => vm.lastLookup,
      willBeDuplicate: (row, np) => vm.willBeDuplicate(row, np),
      isPicked: (row) => vm.isPicked(row),
      hasTemporaryDataForLabel: (label) => vm.hasTemporaryDataForLabel(label),
      inputsOf: (np) => vm.inputsOf(np),
      isInputsLoading: (np) => vm.isInputsLoading(np),
      loadInputs: (np) => vm.loadInputs(np),
      clearPicks: () => vm.clearPicks(),
      togglePick: (row) => vm.togglePick(row),
      commitPickedToTemp: ({required String noProduksi}) {
        final r = vm.commitPickedToTemp(noProduksi: noProduksi);
        return (added: r.added, skipped: r.skipped);
      },
    );
  }
}
