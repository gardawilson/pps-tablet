import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../model/bs_v2_label_info.dart';
import '../view_model/bs_v2_create_view_model.dart';

class BsV2CreateScreen extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const BsV2CreateScreen({super.key, this.onSubmitted});

  @override
  State<BsV2CreateScreen> createState() => _BsV2CreateScreenState();
}

class _BsV2CreateScreenState extends State<BsV2CreateScreen> {
  final TextEditingController _labelCtl = TextEditingController();
  final TextEditingController _noteCtl = TextEditingController();
  final FocusNode _labelFocus = FocusNode();

  // Controllers keyed by entry id for bonggolan berat fields
  final Map<String, TextEditingController> _beratCtls = {};
  // Controllers keyed by "outputId_sakId" for sak berat fields
  final Map<String, TextEditingController> _sakBeratCtls = {};

  final NumberFormat _nf = NumberFormat('#,##0.##', 'id_ID');

  @override
  void dispose() {
    _labelCtl.dispose();
    _noteCtl.dispose();
    _labelFocus.dispose();
    for (final c in _beratCtls.values) {
      c.dispose();
    }
    for (final c in _sakBeratCtls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _beratCtl(String outputId, double current) {
    return _beratCtls.putIfAbsent(
      outputId,
      () => TextEditingController(text: current > 0 ? current.toString() : ''),
    );
  }

  TextEditingController _getSakBeratCtl(String key, double current) {
    return _sakBeratCtls.putIfAbsent(
      key,
      () => TextEditingController(text: current > 0 ? current.toString() : ''),
    );
  }

  void _cleanupCtls(BsV2CreateViewModel vm) {
    final validOutputIds = vm.outputs.map((o) => o.id).toSet();
    _beratCtls.removeWhere((k, v) {
      if (!validOutputIds.contains(k)) {
        v.dispose();
        return true;
      }
      return false;
    });

    final validSakKeys = <String>{};
    for (final o in vm.outputs) {
      for (final s in o.saks) {
        validSakKeys.add('${o.id}_${s.id}');
      }
    }
    _sakBeratCtls.removeWhere((k, v) {
      if (!validSakKeys.contains(k)) {
        v.dispose();
        return true;
      }
      return false;
    });
  }

  Future<void> _addLabel(BsV2CreateViewModel vm) async {
    final code = _labelCtl.text.trim();
    if (code.isEmpty) return;
    await vm.lookupLabel(code);
    if (vm.lookupError == null) {
      _labelCtl.clear();
    }
    _labelFocus.requestFocus();
  }

  Future<void> _submit(BuildContext context, BsV2CreateViewModel vm) async {
    vm.setNote(_noteCtl.text.trim());
    final result = await vm.submit();
    if (!context.mounted) return;

    if (result != null) {
      widget.onSubmitted?.call();
      await showDialog(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Transaksi Berhasil',
          message: '${result.noBongkarSusun} berhasil dibuat.',
        ),
      );
      if (context.mounted) Navigator.of(context).pop();
    } else {
      showDialog(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Submit',
          message: vm.submitError ?? 'Terjadi kesalahan',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BsV2CreateViewModel>(
      builder: (context, vm, _) {
        _cleanupCtls(vm);
        return Scaffold(
          appBar: AppBar(title: const Text('Buat Transaksi Bongkar/Susun')),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === LEFT PANEL ===
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      _ScanCard(
                        controller: _labelCtl,
                        focusNode: _labelFocus,
                        isLoading: vm.isLookingUp,
                        error: vm.lookupError,
                        category: vm.category,
                        onAdd: () => _addLabel(vm),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _InputsCard(
                          inputs: vm.inputs,
                          onRemove: vm.removeInput,
                          nf: _nf,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BeratSummaryCard(
                        inputByJenis: vm.inputBeratByJenis,
                        remainingByJenis: vm.remainingByJenis,
                        nf: _nf,
                      ),
                      const SizedBox(height: 10),
                      _NoteAndSubmitCard(
                        noteCtl: _noteCtl,
                        isSubmitting: vm.isSubmitting,
                        isBalanced: vm.isBalanced,
                        allOutputsValid: vm.allOutputsValid,
                        onSubmit: () => _submit(context, vm),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // === RIGHT PANEL ===
                Expanded(
                  child: _OutputsPanel(
                    vm: vm,
                    nf: _nf,
                    beratCtlOf: _beratCtl,
                    sakBeratCtlOf: _getSakBeratCtl,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT PANEL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ScanCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final String? error;
  final String? category;
  final VoidCallback onAdd;

  const _ScanCard({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.error,
    required this.category,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Scan / Input Label',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: category == 'washing'
                          ? Colors.blue.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category == 'washing' ? 'Washing (B.)' : 'Bonggolan (M.)',
                      style: TextStyle(
                        fontSize: 11,
                        color: category == 'washing'
                            ? Colors.blue.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'B.0000000001 / M.0000000001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      errorText: error,
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onAdd,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InputsCard extends StatelessWidget {
  final List<BsV2LabelInfo> inputs;
  final void Function(String) onRemove;
  final NumberFormat nf;

  const _InputsCard({
    required this.inputs,
    required this.onRemove,
    required this.nf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Label Input (${inputs.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: inputs.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada label di-scan',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: inputs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final lbl = inputs[i];
                        return _InputLabelTile(
                          lbl: lbl,
                          nf: nf,
                          onRemove: onRemove,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabelTile extends StatelessWidget {
  final BsV2LabelInfo lbl;
  final NumberFormat nf;
  final void Function(String) onRemove;

  const _InputLabelTile({
    required this.lbl,
    required this.nf,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasSaks = lbl.saks.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lbl.labelCode,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lbl.namaJenis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (hasSaks) ...[
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: lbl.saks
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Sak ${s.noSak}: ${nf.format(s.berat)} kg',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${nf.format(lbl.totalBerat)} kg',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasSaks)
                Text(
                  '${lbl.jumlahSak} sak',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: Colors.red,
            ),
            onPressed: () => onRemove(lbl.labelCode),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _BeratSummaryCard extends StatelessWidget {
  final Map<int, double> inputByJenis;
  final Map<int, double> remainingByJenis;
  final NumberFormat nf;

  const _BeratSummaryCard({
    required this.inputByJenis,
    required this.remainingByJenis,
    required this.nf,
  });

  @override
  Widget build(BuildContext context) {
    if (inputByJenis.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sisa Berat per Jenis',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...inputByJenis.entries.map((e) {
              final rem = remainingByJenis[e.key] ?? e.value;
              final isBalanced = rem.abs() < 0.001;
              final isOver = rem < -0.001;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID Jenis ${e.key}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LinearProgressIndicator(
                            value: e.value > 0
                                ? ((e.value - rem.clamp(0.0, e.value)) /
                                          e.value)
                                      .clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              isOver
                                  ? Colors.red
                                  : (isBalanced ? Colors.green : Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${nf.format(e.value)} kg',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          isBalanced
                              ? '✓ Seimbang'
                              : (isOver
                                    ? '⚠ Lebih ${nf.format(-rem)} kg'
                                    : 'Sisa ${nf.format(rem)} kg'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isBalanced
                                ? Colors.green
                                : (isOver
                                      ? Colors.red
                                      : Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NoteAndSubmitCard extends StatelessWidget {
  final TextEditingController noteCtl;
  final bool isSubmitting;
  final bool isBalanced;
  final bool allOutputsValid;
  final VoidCallback onSubmit;

  const _NoteAndSubmitCard({
    required this.noteCtl,
    required this.isSubmitting,
    required this.isBalanced,
    required this.allOutputsValid,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: noteCtl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: (!isBalanced || isSubmitting) ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(isSubmitting ? 'Menyimpan...' : 'Submit Transaksi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isBalanced ? Colors.green : null,
                foregroundColor: isBalanced ? Colors.white : null,
              ),
            ),
            if (!isBalanced)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  !allOutputsValid
                      ? 'Setiap output wajib memiliki minimal 1 sak dengan berat > 0'
                      : 'Berat output belum seimbang dengan input',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _OutputsPanel extends StatelessWidget {
  final BsV2CreateViewModel vm;
  final NumberFormat nf;
  final TextEditingController Function(String outputId, double current)
  beratCtlOf;
  final TextEditingController Function(String key, double current)
  sakBeratCtlOf;

  const _OutputsPanel({
    required this.vm,
    required this.nf,
    required this.beratCtlOf,
    required this.sakBeratCtlOf,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Label Output',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: vm.inputs.isEmpty ? null : vm.addOutput,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Output'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: vm.outputs.isEmpty
              ? Center(
                  child: Text(
                    vm.inputs.isEmpty
                        ? 'Scan label input terlebih dahulu'
                        : 'Tekan "Tambah Output" untuk mendefinisikan label baru',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: vm.outputs.length,
                  itemBuilder: (_, i) {
                    final out = vm.outputs[i];
                    return _OutputCard(
                      key: ValueKey(out.id),
                      entry: out,
                      index: i,
                      vm: vm,
                      nf: nf,
                      beratCtlOf: beratCtlOf,
                      sakBeratCtlOf: sakBeratCtlOf,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _OutputCard extends StatelessWidget {
  final OutputEntry entry;
  final int index;
  final BsV2CreateViewModel vm;
  final NumberFormat nf;
  final TextEditingController Function(String, double) beratCtlOf;
  final TextEditingController Function(String, double) sakBeratCtlOf;

  const _OutputCard({
    super.key,
    required this.entry,
    required this.index,
    required this.vm,
    required this.nf,
    required this.beratCtlOf,
    required this.sakBeratCtlOf,
  });

  @override
  Widget build(BuildContext context) {
    final jenisOptions = vm.jenisOptions;
    final isValid = vm.outputIsValid(entry);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isValid
            ? BorderSide.none
            : BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  'Output #${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '${nf.format(entry.totalBerat)} kg',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => vm.removeOutput(entry.id),
                  tooltip: 'Hapus output',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Jenis dropdown
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Jenis',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: DropdownButton<int>(
                value: entry.idJenis,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                isDense: true,
                items: jenisOptions
                    .map(
                      (j) => DropdownMenuItem(
                        value: j.idJenis,
                        child: Text('${j.namaJenis} (ID: ${j.idJenis})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  final jenis = jenisOptions.firstWhere(
                    (j) => j.idJenis == val,
                  );
                  vm.updateOutputJenis(entry.id, val, jenis.namaJenis);
                },
              ),
            ),
            const SizedBox(height: 10),

            // Washing: list of saks
            if (vm.isWashing) ...[
              Row(
                children: [
                  const Text(
                    'Sak',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => vm.addSak(entry.id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'Tambah Sak',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              ...entry.saks.map((sak) {
                final beratKey = '${entry.id}_${sak.id}';
                final beratCtl = sakBeratCtlOf(beratKey, sak.berat);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Sak ${sak.noSak}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: beratCtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Berat (kg)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) {
                            final d = double.tryParse(v);
                            if (d != null)
                              vm.updateSak(entry.id, sak.id, berat: d);
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        onPressed: () => vm.removeSak(entry.id, sak.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              if (entry.saks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Wajib minimal 1 sak. Tekan "Tambah Sak".',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // Bonggolan: single berat field
            if (vm.isBonggolan)
              TextField(
                controller: beratCtlOf(entry.id, entry.berat),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Berat (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) {
                  final d = double.tryParse(v);
                  if (d != null) vm.updateOutputBerat(entry.id, d);
                },
              ),
          ],
        ),
      ),
    );
  }
}
