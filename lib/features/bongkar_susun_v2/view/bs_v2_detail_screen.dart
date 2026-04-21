import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/bs_v2_label_info.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';

class BsV2DetailScreen extends StatefulWidget {
  final String noBongkarSusun;

  const BsV2DetailScreen({super.key, required this.noBongkarSusun});

  @override
  State<BsV2DetailScreen> createState() => _BsV2DetailScreenState();
}

class _BsV2DetailScreenState extends State<BsV2DetailScreen> {
  final BsV2Repository _repo = BsV2Repository();
  BsV2Transaction? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchDetail(widget.noBongkarSusun);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail • ${widget.noBongkarSusun}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gagal memuat: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    if (_data == null) return const Center(child: Text('Data tidak ditemukan'));

    final trx = _data!;
    final isWashing = trx.inputs.isNotEmpty && trx.inputs.first.isWashing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderCard(trx: trx, isWashing: isWashing),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _InputsSection(inputs: trx.inputs)),
              const SizedBox(width: 16),
              Expanded(child: _OutputsSection(outputs: trx.outputs, isWashing: isWashing)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final BsV2Transaction trx;
  final bool isWashing;

  const _HeaderCard({required this.trx, required this.isWashing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(trx.noBongkarSusun,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _CategoryChip(isWashing: isWashing),
              ],
            ),
            const SizedBox(height: 12),
            _Row('Tanggal', trx.tanggalText),
            _Row('Operator', trx.username ?? '-'),
            if (trx.note != null && trx.note!.isNotEmpty) _Row('Catatan', trx.note!),
            _Row('Jumlah Input', '${trx.inputs.length} label'),
            _Row('Jumlah Output', '${trx.outputs.length} label'),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final bool isWashing;
  const _CategoryChip({required this.isWashing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isWashing ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWashing ? Colors.blue.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        isWashing ? 'Washing' : 'Bonggolan',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isWashing ? Colors.blue.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Text(': ', style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _InputsSection extends StatelessWidget {
  final List<BsV2LabelInfo> inputs;
  const _InputsSection({required this.inputs});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0.##', 'id_ID');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.input, size: 18, color: Colors.blue),
                const SizedBox(width: 6),
                Text('Label Input (${inputs.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (inputs.isEmpty)
              const Text('Tidak ada input', style: TextStyle(color: Colors.grey))
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF7F8F9)),
                    children: [
                      _TableHeader('Label Code'),
                      _TableHeader('Jenis'),
                      _TableHeader('Berat (kg)'),
                    ],
                  ),
                  ...inputs.map((l) => TableRow(
                    children: [
                      _TableCell(l.labelCode),
                      _TableCell(l.namaJenis),
                      _TableCell(nf.format(l.totalBerat)),
                    ],
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OutputsSection extends StatelessWidget {
  final List<BsV2OutputLabel> outputs;
  final bool isWashing;
  const _OutputsSection({required this.outputs, required this.isWashing});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0.##', 'id_ID');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.output, size: 18, color: Colors.green),
                const SizedBox(width: 6),
                Text('Label Output (${outputs.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (outputs.isEmpty)
              const Text('Tidak ada output', style: TextStyle(color: Colors.grey))
            else
              ...outputs.map((out) => _OutputCard(out: out, isWashing: isWashing, nf: nf)),
          ],
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  final BsV2OutputLabel out;
  final bool isWashing;
  final NumberFormat nf;
  const _OutputCard({required this.out, required this.isWashing, required this.nf});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (out.labelCode != null)
                Text(out.labelCode!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              Text(out.namaJenis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const Spacer(),
              Text('${nf.format(out.totalBerat)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (isWashing && out.saks.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...out.saks.map((s) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                children: [
                  Text('Sak ${s.noSak}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  Text('${nf.format(s.berat)} kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            )),
          ],
          if (!isWashing)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text('Berat: ${nf.format(out.berat ?? out.totalBerat)} kg',
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
