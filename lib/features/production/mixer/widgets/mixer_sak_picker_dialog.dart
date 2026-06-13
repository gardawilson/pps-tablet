// lib/features/production/mixer/widgets/mixer_sak_picker_dialog.dart
// Thin wrapper around ProductionSakPickerDialog for MixerProductionInputViewModel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/production_sak_picker_dialog.dart';
import '../view_model/mixer_production_input_view_model.dart';

class MixerSakPickerDialog extends StatelessWidget {
  final String noProduksi;
  final bool isPartialMode;

  const MixerSakPickerDialog({
    super.key,
    required this.noProduksi,
    this.isPartialMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MixerProductionInputViewModel>();
    return ProductionSakPickerDialog(
      noProduksi: noProduksi,
      isPartialMode: isPartialMode,
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
