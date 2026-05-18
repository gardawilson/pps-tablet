import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../features/mesin/model/mesin_model.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../view_model/broker_production_view_model.dart';
import '../widgets/broker_delete_dialog.dart';
import '../widgets/broker_production_form_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _prodRepo.fetchBrokerMesin();
  }

  Future<({int shift, String hourStart, String hourEnd})?>
  _fetchCurrentShift() async {
    try {
      final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/*$'), '');
      final url = Uri.parse('$base/api/mst/shift/current');
      final token = await TokenStorage.getToken();
      final res = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      final shift = data['shift'] as int?;
      String trim(String? v) =>
          (v != null && v.length >= 5) ? v.substring(0, 5) : (v ?? '');
      final hourStart = trim(data['hourStart'] as String?);
      final hourEnd = trim(data['hourEnd'] as String?);
      if (shift == null) return null;
      return (shift: shift, hourStart: hourStart, hourEnd: hourEnd);
    } catch (_) {
      return null;
    }
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
    final defaultShift = await _fetchCurrentShift();
    if (!mounted) return;
    final created = await showDialog<BrokerProduction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BrokerProductionFormDialog(
        initialMesin: mstMesin,
        initialDate: today,
        existingProduksiList: mesin.produksiList,
        initialShift: defaultShift?.shift,
        initialHourStart: defaultShift?.hourStart,
        initialHourEnd: defaultShift?.hourEnd,
      ),
    );
    if (!mounted) return;
    if (created != null) {
      await Navigator.of(context).push(
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
      if (!mounted) return;
    }
    _refresh();
  }

  Future<void> _onMesinTap(BrokerMesinInfo mesin) async {
    if (!mounted) return;

    final item = mesin.produksiList.isNotEmpty
        ? mesin.produksiList.first
        : null;

    if (item == null) {
      await _openCreateDialog(mesin: mesin, today: DateTime.now());
      return;
    }

    await Navigator.of(context).push(
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
    if (!mounted) return;
    _refresh();
  }

  Future<void> _onMesinLongPress(BrokerMesinInfo mesin) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _MesinHistoryDialog(
        mesin: mesin,
        fetchCurrentShift: _fetchCurrentShift,
        onOpenInput: (row) async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BrokerProductionInputScreen(
                noProduksi: row.noProduksi,
                idMesin: row.idMesin,
                namaMesin: row.namaMesin,
                shift: row.shift,
                tglProduksi: row.tglProduksi,
                isLocked: row.isLocked,
                lastClosedDate: row.lastClosedDate,
                hourStart: row.hourStart,
                hourEnd: row.hourEnd,
              ),
            ),
          );
          if (mounted) _refresh();
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
                          onLongPress: () => _onMesinLongPress(mesin),
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
// Input Backdate dialog: shows paginated list of produksi for a mesin
// ---------------------------------------------------------------------------
class _MesinHistoryDialog extends StatefulWidget {
  const _MesinHistoryDialog({
    required this.mesin,
    required this.fetchCurrentShift,
    required this.onOpenInput,
  });

  final BrokerMesinInfo mesin;
  final Future<({int shift, String hourStart, String hourEnd})?> Function()
  fetchCurrentShift;
  final Future<void> Function(BrokerProduction row) onOpenInput;

  @override
  State<_MesinHistoryDialog> createState() => _MesinHistoryDialogState();
}

class _MesinHistoryDialogState extends State<_MesinHistoryDialog> {
  final _repo = BrokerProductionRepository();
  final _scrollCtl = ScrollController();

  final List<BrokerProduction> _items = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollCtl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtl.position.pixels >=
            _scrollCtl.position.maxScrollExtent - 100 &&
        !_isFetchingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final res = await _repo.fetchAll(
        page: 1,
        pageSize: _pageSize,
        idMesin: widget.mesin.idMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<BrokerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _items.addAll(newItems);
        _hasMore = 1 < totalPages;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isFetchingMore || !_hasMore) return;
    setState(() => _isFetchingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await _repo.fetchAll(
        page: nextPage,
        pageSize: _pageSize,
        idMesin: widget.mesin.idMesin,
      );
      if (!mounted) return;
      final newItems = res['items'] as List<BrokerProduction>;
      final totalPages = (res['totalPages'] as int?) ?? 1;
      setState(() {
        _items.addAll(newItems);
        _page = nextPage;
        _hasMore = nextPage < totalPages;
        _isFetchingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  List<AtlasTableColumn<BrokerProduction>> _buildColumns() {
    return [
      AtlasTableColumn(
        title: 'No. Produksi',
        width: 120,
        cellBuilder: (_, r, __) => Text(
          r.noProduksi,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E40AF),
          ),
        ),
      ),
      AtlasTableColumn(
        title: 'Tanggal',
        width: 110,
        cellBuilder: (_, r, __) => Text(
          r.tglProduksi != null
              ? '${r.tglProduksi!.day.toString().padLeft(2, '0')}/${r.tglProduksi!.month.toString().padLeft(2, '0')}/${r.tglProduksi!.year}'
              : '-',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      AtlasTableColumn(
        title: 'Shift',
        width: 70,
        cellBuilder: (_, r, __) =>
            Text(r.shift.toString(), style: const TextStyle(fontSize: 12)),
      ),
      AtlasTableColumn(
        title: 'Jam',
        width: 130,
        cellBuilder: (_, r, __) => Text(
          '${r.hourStart ?? '--:--'} – ${r.hourEnd ?? '--:--'}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      AtlasTableColumn(
        title: 'Operator',
        flex: 2,
        cellBuilder: (_, r, __) => Text(
          r.namaOperator,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      AtlasTableColumn(
        title: 'Jenis Output',
        flex: 2,
        cellBuilder: (_, r, __) {
          final jenis = (r.outputJenisNama ?? '').trim();
          return Text(
            jenis.isEmpty ? '-' : jenis,
            maxLines: 3,
            softWrap: true,
            style: const TextStyle(fontSize: 12),
          );
        },
      ),
      AtlasTableColumn(
        title: 'Aksi',
        width: 70,
        showDivider: false,
        cellBuilder: (context, r, __) => LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 110;
            if (isNarrow) {
              return Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') _openEdit(r);
                    if (value == 'hapus') _openDelete(r);
                    if (value == 'input') _openInput(r);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    PopupMenuItem(value: 'input', child: Text('Input')),
                  ],
                ),
              );
            }

            return Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF0D47A1),
                  tooltip: 'Edit',
                  onTap: () => _openEdit(r),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFDC2626),
                  tooltip: 'Hapus',
                  onTap: () => _openDelete(r),
                ),
                const SizedBox(width: 4),
                _ActionBtn(
                  icon: Icons.input_outlined,
                  color: const Color(0xFF00897B),
                  tooltip: 'Input',
                  onTap: () => _openInput(r),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  void _openInput(BrokerProduction row) {
    Navigator.of(context).pop();
    widget.onOpenInput(row);
  }

  Future<void> _openCreate() async {
    if (!mounted) return;
    final mstMesin = MstMesin(
      idMesin: widget.mesin.idMesin,
      namaMesin: widget.mesin.namaMesin,
      bagian: widget.mesin.bagian,
      enable: true,
    );
    final defaultShift = await widget.fetchCurrentShift();
    if (!mounted) return;

    final createVm = BrokerProductionViewModel();
    try {
      final created = await showDialog<BrokerProduction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: createVm,
          child: BrokerProductionFormDialog(
            initialMesin: mstMesin,
            initialDate: DateTime.now().subtract(const Duration(days: 1)),
            isBackdateInput: true,
            existingProduksiList: widget.mesin.produksiList,
            initialShift: defaultShift?.shift,
            initialHourStart: defaultShift?.hourStart,
            initialHourEnd: defaultShift?.hourEnd,
          ),
        ),
      );
      if (!mounted) return;
      if (created != null) {
        Navigator.of(context).pop();
        await widget.onOpenInput(created);
        return;
      }
    } finally {
      createVm.dispose();
    }
    if (!mounted) return;
    _loadPage();
  }

  Future<void> _openEdit(BrokerProduction row) async {
    if (!mounted) return;
    final editVm = BrokerProductionViewModel();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: editVm,
          child: BrokerProductionFormDialog(header: row),
        ),
      );
    } finally {
      editVm.dispose();
    }
    if (!mounted) return;
    _loadPage();
  }

  Future<void> _openDelete(BrokerProduction row) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BrokerProductionDeleteDialog(
        header: row,
        onConfirm: () async {
          final deleteVm = BrokerProductionViewModel();
          final success = await deleteVm.deleteProduksi(row.noProduksi);
          final errMsg = deleteVm.saveError;
          deleteVm.dispose();

          if (ctx.mounted) Navigator.of(ctx).pop();
          if (!mounted) return;

          if (success) {
            showDialog(
              context: context,
              builder: (_) => SuccessStatusDialog(
                title: 'Berhasil Menghapus',
                message: 'No. Produksi ${row.noProduksi} berhasil dihapus.',
              ),
            );
          } else {
            showDialog(
              context: context,
              builder: (_) => ErrorStatusDialog(
                title: 'Gagal Menghapus!',
                message: errMsg ?? 'Gagal menghapus data',
              ),
            );
          }
          _loadPage();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 760;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_calendar_outlined,
                            size: 18,
                            color: Color(0xFF0D47A1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.mesin.namaMesin,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
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
                      if (isNarrow) const SizedBox(height: 2),
                    ],
                  );
                },
              ),
            ),
            // Table
            Expanded(
              child: Stack(
                children: [
                  AtlasDataTable<BrokerProduction>(
                    columns: _buildColumns(),
                    items: _items,
                    scrollController: _scrollCtl,
                    isLoading: _isLoading,
                    isFetchingMore: _isFetchingMore,
                    errorMessage: '',
                  ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.extended(
                      heroTag: null,
                      backgroundColor: const Color(0xFF0A7349),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Input Backdate'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _MesinCard extends StatelessWidget {
  const _MesinCard({
    required this.mesin,
    required this.onTap,
    required this.onLongPress,
  });

  final BrokerMesinInfo mesin;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

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
    return mesin.produksiList.isNotEmpty ? mesin.produksiList.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final active = mesin.isActive;
    final current = active ? _currentItem() : null;

    const activeAccent = Color(0xFF16A34A);
    const inactiveAccent = Color(0xFFDC2626);
    final accent = active ? activeAccent : inactiveAccent;
    final borderColor = active
        ? const Color(0xFF86EFAC)
        : const Color(0xFFFCA5A5);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mesin.namaMesin,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _StatusPill(active: active),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          if (current != null) ...[
                            if (current.shift != null)
                              _InfoRow(
                                icon: Icons.access_time_outlined,
                                iconColor: const Color(0xFF0D47A1),
                                text:
                                    'Shift ${current.shift}  |  ${current.hourStart ?? '--:--'} - ${current.hourEnd ?? '--:--'}',
                                bold: true,
                              ),
                            if (current.outputJenisNama != null) ...[
                              const SizedBox(height: 4),
                              _InfoRow(
                                icon: Icons.inventory_2_outlined,
                                iconColor: const Color(0xFF7C3AED),
                                text: current.outputJenisNama!,
                                maxLines: 2,
                              ),
                            ],
                            if (current.operator_ != null) ...[
                              const SizedBox(height: 4),
                              _InfoRow(
                                icon: Icons.person_outline,
                                iconColor: const Color(0xFF0369A1),
                                text: current.operator_!,
                              ),
                            ],
                          ] else ...[
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  size: 13,
                                  color: Color(0xFFF87171),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Mesin belum aktif produksi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFB91C1C),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final dot = active ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final textColor = active
        ? const Color(0xFF15803D)
        : const Color(0xFFB91C1C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            active ? 'Aktif' : 'Tidak Aktif',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.bold = false,
    this.maxLines,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool bold;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 11, color: iconColor),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            softWrap: true,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: bold ? const Color(0xFF1E3A5F) : const Color(0xFF4B5563),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.activeMesin, required this.idleMesin});

  final int activeMesin;
  final int idleMesin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              'Mesin Broker Hari Ini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StatChip(
            icon: Icons.check_circle,
            color: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            value: activeMesin,
            label: 'Mesin Aktif',
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.cancel,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEE2E2),
            value: idleMesin,
            label: 'Mesin Tidak Aktif',
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
