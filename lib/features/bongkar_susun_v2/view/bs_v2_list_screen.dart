import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/atlas_paged_data_table.dart';
import '../../../../common/widgets/error_status_dialog.dart';
import '../../../../common/widgets/success_status_dialog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';
import '../utils/bs_v2_category_label.dart';
import '../view_model/bs_v2_list_view_model.dart';
import '../view_model/bs_v2_create_view_model.dart';
import 'bs_v2_create_screen.dart';
import 'bs_v2_detail_screen.dart';

// ─── Theme ─────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

// ─── Screen ────────────────────────────────────────────────────────────────

class BsV2ListScreen extends StatefulWidget {
  const BsV2ListScreen({super.key});

  @override
  State<BsV2ListScreen> createState() => _BsV2ListScreenState();
}

class _BsV2ListScreenState extends State<BsV2ListScreen> {
  final TextEditingController _searchCtl = TextEditingController();
  late final BsV2ListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = BsV2ListViewModel();
    _vm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _showRowPopover(BsV2Transaction row, Offset globalPos) async {
    final overlay =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final local = overlay.globalToLocal(globalPos);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        final safeLeft = local.dx.clamp(8.0, overlay.size.width - 240.0);
        final safeTop = local.dy.clamp(8.0, overlay.size.height - 160.0);
        return Stack(
          children: [
            Positioned(
              left: safeLeft,
              top: safeTop,
              child: _RowPopover(
                row: row,
                onClose: () => Navigator.of(dialogCtx).pop(),
                onDetail: () {
                  Future.microtask(() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BsV2DetailScreen(
                          noBongkarSusun: row.noBongkarSusun,
                        ),
                      ),
                    );
                  });
                },
                onDelete: () async {
                  Navigator.of(dialogCtx).pop();
                  await _confirmDelete(row);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BsV2Transaction row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Transaksi?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Hapus ${row.noBongkarSusun}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await _vm.delete(row.noBongkarSusun);
    if (!mounted) return;
    if (success) {
      showDialog(
        context: context,
        builder: (_) => SuccessStatusDialog(
          title: 'Berhasil Dihapus',
          message: '${row.noBongkarSusun} berhasil dihapus.',
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => ErrorStatusDialog(
          title: 'Gagal Menghapus',
          message: _vm.saveError ?? 'Gagal menghapus data',
        ),
      );
    }
  }

  void _openCreate() {
    final repo = BsV2Repository();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => BsV2CreateViewModel(repository: repo),
          child: BsV2CreateScreen(onSubmitted: () => _vm.refresh()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BsV2ListViewModel>.value(
      value: _vm,
      child: Consumer<BsV2ListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: _kSurface,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Buat Baru',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            body: Column(
              children: [
                _SearchBar(
                  controller: _searchCtl,
                  onChanged: vm.setSearchDebounced,
                  onClear: () {
                    _searchCtl.clear();
                    vm.clearSearch();
                  },
                ),
                Expanded(
                  child: AtlasPagedDataTable<BsV2Transaction>(
                    pagingController: vm.pagingController,
                    columns: _columns(),
                    rowColorBuilder: (row) =>
                        (row.balance == false) ? Colors.red.shade50 : null,
                    onRowTap: (row) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BsV2DetailScreen(
                          noBongkarSusun: row.noBongkarSusun,
                        ),
                      ),
                    ),
                    onRowLongPress: (row, pos) => _showRowPopover(row, pos),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AtlasTableColumn<BsV2Transaction>> _columns() {
    return [
      AtlasTableColumn<BsV2Transaction>(
        title: 'NO. BONGKAR SUSUN',
        width: 200,
        cellBuilder: (ctx, item, state) => Text(
          item.noBongkarSusun,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF1A1D23),
            letterSpacing: -0.2,
          ),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'TANGGAL',
        width: 120,
        cellBuilder: (ctx, item, state) => Text(
          formatDateToShortId(item.tanggal),
          style: TextStyle(
            fontSize: 13,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'CREATE BY',
        width: 110,
        cellBuilder: (ctx, item, state) {
          final name = item.username;
          if (name == null || name.isEmpty) {
            return Text(
              '—',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: state.isSelected
                        ? const Color(0xFF0C66E4)
                        : const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'KATEGORI',
        width: 130,
        cellBuilder: (ctx, item, state) {
          final cat =
              item.category ??
              (item.inputs.isNotEmpty ? item.inputs.first.category : null);
          return Text(
            bsV2CategoryLabel(cat),
            style: TextStyle(
              fontSize: 13,
              color: state.isSelected
                  ? const Color(0xFF0C66E4)
                  : const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'IN → OUT',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (ctx, item, state) {
          final inputCount = item.inputLabelCount ?? item.inputs.length;
          final outputCount = item.outputLabelCount ?? item.outputs.length;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountPill(count: inputCount, color: const Color(0xFF1E6FD9)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: Colors.grey.shade400,
                ),
              ),
              _CountPill(count: outputCount, color: const Color(0xFF0A7349)),
            ],
          );
        },
      ),
      AtlasTableColumn<BsV2Transaction>(
        title: 'CATATAN',
        width: 260,
        showDivider: false,
        cellBuilder: (ctx, item, state) {
          final note = item.note;
          if (note == null || note.isEmpty) {
            return Text(
              '—',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            );
          }
          return Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: state.isSelected
                  ? const Color(0xFF0C66E4)
                  : const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    ];
  }
}

// ─── Count Pill ────────────────────────────────────────────────────────────

class _CountPill extends StatelessWidget {
  final int count;
  final Color color;

  const _CountPill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nomor bongkar susun...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: onClear,
                      )
                    : null,
                filled: true,
                fillColor: _kSurface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Row Popover ───────────────────────────────────────────────────────────

class _RowPopover extends StatelessWidget {
  final BsV2Transaction row;
  final VoidCallback onClose;
  final VoidCallback onDetail;
  final VoidCallback onDelete;

  const _RowPopover({
    required this.row,
    required this.onClose,
    required this.onDetail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black26,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: const Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.noBongkarSusun,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              Icons.open_in_new_rounded,
              'Lihat Detail',
              onDetail,
              color: _kPrimary,
            ),
            const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: _kBorder,
            ),
            _tile(
              Icons.delete_outline_rounded,
              'Hapus Transaksi',
              onDelete,
              color: Colors.red.shade600,
            ),
            const Divider(
              height: 1,
              indent: 14,
              endIndent: 14,
              color: _kBorder,
            ),
            _tile(Icons.close_rounded, 'Tutup', onClose),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    final c = color ?? const Color(0xFF374151);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
