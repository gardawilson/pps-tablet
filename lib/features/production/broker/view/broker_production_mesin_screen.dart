import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/time_formatter.dart';
import '../../../../features/mesin/model/mesin_model.dart';
import '../../../broker_type/model/broker_type_model.dart';
import '../../../broker_type/widgets/broker_type_dropdown.dart';
import '../../shared/widgets/time_form_field.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../widgets/broker_production_form_dialog.dart';
import 'broker_production_input_screen.dart';
import 'broker_production_screen.dart';

class BrokerProductionMesinScreen extends StatefulWidget {
  const BrokerProductionMesinScreen({super.key});

  @override
  State<BrokerProductionMesinScreen> createState() =>
      _BrokerProductionMesinScreenState();
}

class _BrokerProductionMesinScreenState
    extends State<BrokerProductionMesinScreen> {
  final _prodRepo = BrokerProductionRepository();
  late Future<List<BrokerMesinInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _prodRepo.fetchBrokerMesin();
  }

  void _refresh() {
    setState(() {
      _future = _prodRepo.fetchBrokerMesin();
    });
  }

  Future<void> _openCreateDialog({
    required BrokerMesinInfo mesin,
    required DateTime today,
  }) async {
    if (!mounted) return;
    final mstMesin = MstMesin(
      idMesin: mesin.idMesin,
      namaMesin: mesin.namaMesin,
      bagian: mesin.bagian,
      enable: true,
    );
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        initialMesin: mstMesin,
        initialDate: today,
        existingProduksiList: mesin.produksiList,
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  Future<void> _onMesinTap(BrokerMesinInfo mesin) async {
    if (!mounted) return;

    if (mesin.produksiList.isEmpty) {
      await _openCreateDialog(mesin: mesin, today: DateTime.now());
      return;
    }

    // show selection dialog — no loading needed, data already in card
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _ProduksiSelectionDialog(
        mesin: mesin,
        onTambahBaru: () async {
          Navigator.of(dialogCtx).pop();
          if (!mounted) return;
          final created = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _QuickCreateDialog(mesin: mesin),
          );
          if (!mounted) return;
          if (created == true) _refresh();
        },
        onSelectProduksi: (item) {
          Navigator.of(dialogCtx).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BrokerProductionInputScreen(
                noProduksi: item.noProduksi,
                idMesin: mesin.idMesin,
                namaMesin: mesin.namaMesin,
                shift: item.shift ?? 1,
                tglProduksi: item.tglProduksi,
                isLocked: false,
                lastClosedDate: null,
                hourStart: item.hourStart,
                hourEnd: item.hourEnd,
              ),
            ),
          );
        },
      ),
    );
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<List<BrokerMesinInfo>>(
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
                        'Data mesin belum bisa dimuat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.error.toString(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final allMesin = snapshot.data ?? [];
              final activeCount = allMesin.where((m) => m.isActive).length;
              final idleCount = allMesin.length - activeCount;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageHeader(
                      activeMesin: activeCount,
                      idleMesin: idleCount,
                      onRiwayatProduksi: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BrokerProductionScreen(),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final mesin = allMesin[index];
                        return _MesinCard(
                          mesin: mesin,
                          onTap: () => _onMesinTap(mesin),
                        );
                      }, childCount: allMesin.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisExtent: 150,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-create dialog: jenis broker + jam mulai + jam selesai + operator
// ---------------------------------------------------------------------------
class _QuickCreateDialog extends StatefulWidget {
  const _QuickCreateDialog({required this.mesin});
  final BrokerMesinInfo mesin;

  @override
  State<_QuickCreateDialog> createState() => _QuickCreateDialogState();
}

class _QuickCreateDialogState extends State<_QuickCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BrokerProductionRepository();

  BrokerType? _brokerType;
  late final TextEditingController _hourStartCtrl;
  late TimeOfDay _startTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _startTime = now;
    _hourStartCtrl = TextEditingController(
      text:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _hourStartCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_brokerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis broker terlebih dahulu')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.addProduksi(
        idMesin: widget.mesin.idMesin,
        tanggal: DateTime.now(),
        hourStart: _hourStartCtrl.text.trim(),
        outputJenisId: _brokerType!.idBroker,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.mesin.namaMesin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tambah Produksi Baru',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),

              // Jenis Broker + Jam Mulai dalam satu baris
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: BrokerTypeDropdown(
                      onChanged: (bt) => setState(() => _brokerType = bt),
                      validator: (v) =>
                          v == null ? 'Wajib pilih jenis broker' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TimeFormField(
                      controller: _hourStartCtrl,
                      label: 'Jam Mulai',
                      hintText: 'HH:mm',
                      onPick: () async {
                        final picked = await pickTime24h(
                          context,
                          initial: _startTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _startTime = picked;
                            _hourStartCtrl.text = formatHHmm(picked);
                          });
                        }
                      },
                      validator: (_) => parseHHmm(_hourStartCtrl.text) == null
                          ? 'Wajib isi (HH:mm)'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('BATAL'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _saving ? 'MENYIMPAN...' : 'SIMPAN',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

class _ProduksiSelectionDialog extends StatelessWidget {
  const _ProduksiSelectionDialog({
    required this.mesin,
    required this.onTambahBaru,
    required this.onSelectProduksi,
  });

  final BrokerMesinInfo mesin;
  final VoidCallback onTambahBaru;
  final void Function(BrokerProduksiItem item) onSelectProduksi;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mesin.namaMesin,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mesin.produksiList.length} produksi hari ini',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...mesin.produksiList.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => onSelectProduksi(item),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.tag,
                                            size: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.noProduksi,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1E40AF),
                                            ),
                                          ),
                                          if (item.shift != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Shift ${item.shift}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (item.outputJenisNama != null) ...[
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.category_outlined,
                                              size: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                item.outputJenisNama!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (item.hourStart != null ||
                                          item.hourEnd != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.schedule,
                                              size: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${item.hourStart ?? '--:--'} – ${item.hourEnd ?? '--:--'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (item.operator_ != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item.operator_!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTambahBaru,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Produksi Baru'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MesinCard extends StatelessWidget {
  const _MesinCard({required this.mesin, required this.onTap});

  final BrokerMesinInfo mesin;
  final VoidCallback onTap;

  BrokerProduksiItem? _currentItem() {
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;

    TimeOfDay? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      final parts = s.split(':');
      if (parts.length < 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    for (final p in mesin.produksiList) {
      final start = parse(p.hourStart);
      final end = parse(p.hourEnd);
      if (start == null || end == null) continue;
      final s = start.hour * 60 + start.minute;
      final e = end.hour * 60 + end.minute;
      final inRange = s <= e
          ? nowMin >= s && nowMin < e
          : nowMin >= s || nowMin < e;
      if (inRange) return p;
    }
    // fallback: no time-matched item, return first if any
    return mesin.produksiList.isNotEmpty ? mesin.produksiList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final current = active ? _currentItem() : null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'Aktif' : 'Idle',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                mesin.namaMesin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              if (current != null) ...[
                if (current.shift != null)
                  Text(
                    'Shift ${current.shift}  ${current.hourStart ?? '--:--'} – ${current.hourEnd ?? '--:--'}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                if (current.outputJenisNama != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    current.outputJenisNama!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
                if (current.operator_ != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 10,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          current.operator_!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else
                const Text(
                  'Belum ada produksi aktif',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.activeMesin,
    required this.idleMesin,
    required this.onRiwayatProduksi,
  });

  final int activeMesin;
  final int idleMesin;
  final VoidCallback onRiwayatProduksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Pilih Mesin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(width: 16),
          _StatDot(
            color: const Color(0xFF16A34A),
            value: activeMesin,
            label: 'aktif',
          ),
          const SizedBox(width: 12),
          _StatDot(
            color: const Color(0xFF94A3B8),
            value: idleMesin,
            label: 'idle',
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onRiwayatProduksi,
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Riwayat Produksi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D47A1),
              side: const BorderSide(color: Color(0xFF0D47A1)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot({
    required this.color,
    required this.value,
    required this.label,
  });

  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextSpan(
                text: label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
