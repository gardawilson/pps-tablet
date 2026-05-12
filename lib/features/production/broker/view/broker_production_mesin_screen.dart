import 'package:flutter/material.dart';

import '../../../../features/mesin/model/mesin_model.dart';
import '../../../../common/widgets/success_status_dialog.dart';
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

enum _MesinFilter { semua, aktif, idle }

class _BrokerProductionMesinScreenState
    extends State<BrokerProductionMesinScreen> {
  final _prodRepo = BrokerProductionRepository();
  late Future<List<BrokerMesinInfo>> _future;
  bool _isLoading = false;
  _MesinFilter _filter = _MesinFilter.semua;

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

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

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
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                );
              }

              final allMesin = snapshot.data ?? [];
              final activeCount = allMesin.where((m) => m.isActive).length;
              final idleCount = allMesin.length - activeCount;

              final filtered = switch (_filter) {
                _MesinFilter.aktif =>
                  allMesin.where((m) => m.isActive).toList(),
                _MesinFilter.idle =>
                  allMesin.where((m) => !m.isActive).toList(),
                _MesinFilter.semua => allMesin,
              };

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _PageHeader(
                      activeMesin: activeCount,
                      idleMesin: idleCount,
                      onRefresh: _refresh,
                      onRiwayatProduksi: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BrokerProductionScreen(),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FilterTabs(
                      selected: _filter,
                      totalCount: allMesin.length,
                      activeCount: activeCount,
                      idleCount: idleCount,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final mesin = filtered[index];
                        return _MesinCard(
                          mesin: mesin,
                          onTap: () => _onMesinTap(mesin),
                        );
                      }, childCount: filtered.length),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
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
    required this.onRefresh,
    required this.onRiwayatProduksi,
  });

  final int activeMesin;
  final int idleMesin;
  final VoidCallback onRefresh;
  final VoidCallback onRiwayatProduksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Pilih Mesin" label + stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Mesin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _StatDot(
                    color: const Color(0xFF16A34A),
                    value: activeMesin,
                    label: 'aktif',
                  ),
                  const SizedBox(width: 16),
                  _StatDot(
                    color: const Color(0xFF94A3B8),
                    value: idleMesin,
                    label: 'idle',
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // actions
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
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF0D47A1)),
            onPressed: onRefresh,
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

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.totalCount,
    required this.activeCount,
    required this.idleCount,
    required this.onChanged,
  });

  final _MesinFilter selected;
  final int totalCount;
  final int activeCount;
  final int idleCount;
  final ValueChanged<_MesinFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Semua',
            count: totalCount,
            selected: selected == _MesinFilter.semua,
            dotColor: null,
            onTap: () => onChanged(_MesinFilter.semua),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Aktif',
            count: activeCount,
            selected: selected == _MesinFilter.aktif,
            dotColor: const Color(0xFF16A34A),
            onTap: () => onChanged(_MesinFilter.aktif),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Idle',
            count: idleCount,
            selected: selected == _MesinFilter.idle,
            dotColor: const Color(0xFF94A3B8),
            onTap: () => onChanged(_MesinFilter.idle),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.dotColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color? dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D47A1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? Colors.white70 : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              '$label $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
