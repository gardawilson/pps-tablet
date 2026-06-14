import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../features/mesin/model/mesin_model.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../widgets/broker_production_form_dialog.dart';
import 'broker_production_input_screen.dart';

class BrokerProductionListScreen extends StatefulWidget {
  const BrokerProductionListScreen({super.key, required this.mesin});

  final MstMesin mesin;

  @override
  State<BrokerProductionListScreen> createState() =>
      _BrokerProductionListScreenState();
}

class _BrokerProductionListScreenState
    extends State<BrokerProductionListScreen> {
  final _repo = BrokerProductionRepository();
  DateTime _selectedDate = DateTime.now();
  late Future<List<BrokerProduction>> _future;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    _future = _repo.fetchByMesinAndDate(
      idMesin: widget.mesin.idMesin,
      tanggal: _selectedDate,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fetch();
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        initialMesin: widget.mesin,
        initialDate: _selectedDate,
      ),
    );
    if (!mounted) return;
    if (created != null) {
      setState(_fetch);
      showDialog(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. Produksi ${created.noProduksi} berhasil dibuat.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        tooltip: 'Tambah Produksi',
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(widget.mesin.namaMesin),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => setState(_fetch),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<BrokerProduction>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(_fetch),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 56,
                    color: Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tidak ada data produksi',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisExtent: 140,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => _ProductionCard(row: list[index]),
          );
        },
      ),
    );
  }
}

class _ProductionCard extends StatelessWidget {
  const _ProductionCard({required this.row});

  final BrokerProduction row;

  @override
  Widget build(BuildContext context) {
    final jam = (row.hourStart != null && row.hourEnd != null)
        ? '${row.hourStart} – ${row.hourEnd}'
        : '-';

    final accentColor = row.isLocked
        ? const Color(0xFFDC2626)
        : const Color(0xFF0D47A1);
    final bgColor = row.isLocked
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFEFF6FF);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BrokerProductionInputScreen(
              noProduksi: row.noProduksi,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      row.isLocked
                          ? Icons.lock_outline
                          : Icons.assignment_outlined,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Shift ${row.shift}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        jam,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.namaOperator,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
