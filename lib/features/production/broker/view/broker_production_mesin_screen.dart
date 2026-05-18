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
    await showDialog<void>(
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
  });

  final BrokerMesinInfo mesin;
  final Future<({int shift, String hourStart, String hourEnd})?> Function()
  fetchCurrentShift;

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
        width: 160,
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
        width: 180,
        cellBuilder: (_, r, __) => Text(
          r.namaOperator,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
      AtlasTableColumn(
        title: 'Aksi',
        width: 120,
        cellBuilder: (_, r, __) => Row(
          children: [
            _ActionBtn(
              icon: Icons.edit_outlined,
              color: const Color(0xFF0D47A1),
              tooltip: 'Edit',
              onTap: () => _openEdit(r),
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              icon: Icons.delete_outline,
              color: const Color(0xFFDC2626),
              tooltip: 'Hapus',
              onTap: () => _openDelete(r),
            ),
            const SizedBox(width: 6),
            _ActionBtn(
              icon: Icons.input_outlined,
              color: const Color(0xFF00897B),
              tooltip: 'Input',
              onTap: () => _openInput(r),
            ),
          ],
        ),
      ),
    ];
  }

  void _openInput(BrokerProduction row) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
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
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: createVm,
          child: BrokerProductionFormDialog(
            initialMesin: mstMesin,
            initialDate: DateTime.now(),
            existingProduksiList: widget.mesin.produksiList,
            initialShift: defaultShift?.shift,
            initialHourStart: defaultShift?.hourStart,
            initialHourEnd: defaultShift?.hourEnd,
          ),
        ),
      );
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
          maxWidth: 960,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: Color(0xFF0D47A1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Input Backdate – ${widget.mesin.namaMesin}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Produksi'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00897B),
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
            ),
            // Table
            Expanded(
              child: AtlasDataTable<BrokerProduction>(
                columns: _buildColumns(),
                items: _items,
                scrollController: _scrollCtl,
                isLoading: _isLoading,
                isFetchingMore: _isFetchingMore,
                errorMessage: '',
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
  const _PageHeader({required this.activeMesin, required this.idleMesin});

  final int activeMesin;
  final int idleMesin;

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
