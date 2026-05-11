import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/mesin/model/mesin_model.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../view_model/broker_production_view_model.dart';
import '../widgets/broker_production_form_dialog.dart';
import '../widgets/broker_production_header_table.dart';
import 'broker_production_input_screen.dart';

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
  late final BrokerProductionViewModel _todayViewModel;
  String? _selectedNoProduksi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _prodRepo.fetchBrokerMesin();
    _todayViewModel = BrokerProductionViewModel();
    _todayViewModel.applyFilters(date: DateTime.now());
  }

  @override
  void dispose() {
    _todayViewModel.dispose();
    super.dispose();
  }

  void _refreshAll() {
    setState(() {
      _future = _prodRepo.fetchBrokerMesin();
    });
    _todayViewModel.applyFilters(date: DateTime.now());
  }

  /// Parse "HH:mm" string into a [TimeOfDay].
  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Returns minutes-since-midnight for a [TimeOfDay].
  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Find the [BrokerProduction] entry whose hourStart <= now < hourEnd.
  BrokerProduction? _matchCurrentShift(List<BrokerProduction> list) {
    final now = TimeOfDay.now();
    final nowMin = _toMinutes(now);

    for (final p in list) {
      final start = _parseTime(p.hourStart);
      final end = _parseTime(p.hourEnd);
      if (start == null || end == null) continue;

      final startMin = _toMinutes(start);
      final endMin = _toMinutes(end);

      // handle overnight ranges (e.g. 22:00 – 06:00)
      final inRange = startMin <= endMin
          ? nowMin >= startMin && nowMin < endMin
          : nowMin >= startMin || nowMin < endMin;

      if (inRange) return p;
    }
    return null;
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
    final created = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        initialMesin: mstMesin,
        initialDate: today,
      ),
    );
    if (!mounted) return;
    if (created != null) {
      showDialog(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Membuat',
          message: 'No. Produksi ${created.noProduksi} berhasil dibuat.',
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BrokerProductionInputScreen(
            noProduksi: created.noProduksi,
            idMesin: created.idMesin,
            namaMesin: created.namaMesin,
            shift: created.shift,
            tglProduksi: created.tglProduksi,
            isLocked: created.isLocked,
            lastClosedDate: created.lastClosedDate,
            hourStart: created.hourStart,
            hourEnd: created.hourEnd,
          ),
        ),
      );
    }
  }

  Future<void> _onMesinTap(BrokerMesinInfo mesin) async {
    if (!mounted || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final list = await _prodRepo.fetchByMesinAndDate(
        idMesin: mesin.idMesin,
        tanggal: today,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final matched = _matchCurrentShift(list);

      if (matched != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BrokerProductionInputScreen(
              noProduksi: matched.noProduksi,
              idMesin: matched.idMesin,
              namaMesin: matched.namaMesin,
              shift: matched.shift,
              tglProduksi: matched.tglProduksi,
              isLocked: matched.isLocked,
              lastClosedDate: matched.lastClosedDate,
              hourStart: matched.hourStart,
              hourEnd: matched.hourEnd,
            ),
          ),
        );
      } else {
        await _openCreateDialog(mesin: mesin, today: today);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _openCreateDialog(mesin: mesin, today: DateTime.now());
    }
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
                        'Gagal memuat data mesin',
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
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(
                          () => _future = _prodRepo.fetchBrokerMesin(),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                );
              }

              final mesinList = snapshot.data ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      children: [
                        Text(
                          'Pilih Mesin',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _refreshAll,
                        ),
                      ],
                    ),
                  ),
                  // ── mesin grid ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 150,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: mesinList.length,
                      itemBuilder: (context, index) {
                        final mesin = mesinList[index];
                        return _MesinCard(
                          mesin: mesin,
                          onTap: () => _onMesinTap(mesin),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── produksi hari ini ────────────────────────────────
                  Expanded(
                    child:
                        ChangeNotifierProvider<BrokerProductionViewModel>.value(
                          value: _todayViewModel,
                          child: _TodayProductionSection(
                            selectedNoProduksi: _selectedNoProduksi,
                            onRowTap: (prod) {
                              setState(
                                () => _selectedNoProduksi = prod.noProduksi,
                              );
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BrokerProductionInputScreen(
                                    noProduksi: prod.noProduksi,
                                    idMesin: prod.idMesin,
                                    namaMesin: prod.namaMesin,
                                    shift: prod.shift,
                                    tglProduksi: prod.tglProduksi,
                                    isLocked: prod.isLocked,
                                    lastClosedDate: prod.lastClosedDate,
                                    hourStart: prod.hourStart,
                                    hourEnd: prod.hourEnd,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ),
                ],
              );
            },
          ),
          if (_isLoading)
            const ColoredBox(
              color: Color(0x55000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _MesinCard extends StatelessWidget {
  const _MesinCard({required this.mesin, required this.onTap});

  final BrokerMesinInfo mesin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final iconBg = active ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF);
    final iconColor = active
        ? const Color(0xFF15803D)
        : const Color(0xFF0D47A1);
    final start = mesin.hourStart ?? '--:--';
    final end = mesin.hourEnd ?? '--:--';

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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing_outlined,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
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
              if (active) ...[
                Row(
                  children: [
                    const Icon(Icons.tag, size: 11, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        mesin.noProduksi ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 11,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$start – $end',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (mesin.shift != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Shift ${mesin.shift}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 11,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        mesin.operator_ ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                const Text(
                  'Tidak ada produksi aktif',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayProductionSection extends StatelessWidget {
  const _TodayProductionSection({
    required this.selectedNoProduksi,
    required this.onRowTap,
  });

  final String? selectedNoProduksi;
  final ValueChanged<BrokerProduction> onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Text(
            'Daftar Produksi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        Expanded(
          child: BrokerProductionHeaderTable(
            selectedNoProduksi: selectedNoProduksi,
            onRowTap: onRowTap,
            onRowLongPress: (row, _) => onRowTap(row),
          ),
        ),
      ],
    );
  }
}
