import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/scan_label_dialog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/label_print_lock_api.dart';
import '../../../core/services/label_print_sync_queue.dart';
import '../../../core/utils/pdf_print_service.dart';
import '../../../core/view/app_shell.dart';
import '../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../core/view_model/permission_view_model.dart';
import '../../label/furniture_wip/repository/furniture_wip_repository.dart';
import '../../label/packing/repository/packing_repository.dart';
import '../../label/reject/repository/reject_repository.dart';
import '../model/retur_v3_header.dart';
import '../model/retur_v3_item.dart';
import '../model/retur_v3_output.dart';
import '../model/retur_v3_turnover.dart';
import '../repository/retur_v3_repository.dart';
import '../view_model/retur_v3_detail_view_model.dart';
import '../widgets/retur_v3_reject_generate_dialog.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF3F5F8);
const _kBorder = Color(0xFFE2E6EA);
const _kSuccess = Color(0xFF0A7349);
const _kMuted = Color(0xFF6B7280);
const _kText = Color(0xFF1A1D23);

const _kKategoriReject = 'reject';

// ── Print-flow helpers (mirrors lib/features/retur_v2/view/retur_v2_detail_screen.dart) ──

String _featureOf(ReturV3Output o) {
  switch (o.kodeKategori) {
    case ReturV3Kategori.furnitureWip:
      return 'furniture_wip';
    case _kKategoriReject:
      return 'reject';
    default:
      return 'packing';
  }
}

String _pdfUrlOf(ReturV3Output o) {
  switch (o.kodeKategori) {
    case ReturV3Kategori.furnitureWip:
      return ApiConstants.furnitureWipLabelPdf(o.labelCode);
    case _kKategoriReject:
      return ApiConstants.rejectLabelPdf(o.labelCode);
    default:
      return ApiConstants.packingLabelPdf(o.labelCode);
  }
}

Future<int?> _markAsPrinted(ReturV3Output o) {
  switch (o.kodeKategori) {
    case ReturV3Kategori.furnitureWip:
      return FurnitureWipRepository().markAsPrinted(o.labelCode);
    case _kKategoriReject:
      return RejectRepository(api: ApiClient()).markAsPrinted(o.labelCode);
    default:
      return PackingRepository(api: ApiClient()).markAsPrinted(o.labelCode);
  }
}

/// Detail 1 nomor Retur v3 — tampilan berubah menurut `statusRetur`:
/// PENDING (input item + keputusan PIC), TIDAK_DIGANTI (generate + cetak
/// label), DIGANTI (scan turnover + flag kirim). Permission gating pakai
/// kode `retur:create`, `retur:update` —
/// nama kode ini adalah tebakan konseptual mengikuti pola
/// `perm.can('feature:action')` yang dipakai fitur lain (lihat
/// `return_production_action_bar.dart`); sesuaikan kalau backend memakai
/// nama kode permission yang berbeda.
class ReturV3DetailScreen extends StatefulWidget {
  final String noRetur;

  /// Saat true, layar ini ditampilkan inline di panel kanan layout
  /// master-detail (lihat `retur_v3_list_screen.dart`) — bukan sebagai
  /// halaman yang di-push lewat Navigator — sehingga tidak boleh memutasi
  /// breadcrumb `AppShell` (daftar master di kiri tetap terlihat, tidak ada
  /// "perpindahan halaman" yang perlu direfleksikan di breadcrumb).
  final bool embedded;

  const ReturV3DetailScreen({
    super.key,
    required this.noRetur,
    this.embedded = false,
  });

  @override
  State<ReturV3DetailScreen> createState() => _ReturV3DetailScreenState();
}

class _ReturV3DetailScreenState extends State<ReturV3DetailScreen> {
  late final ReturV3DetailViewModel _vm;
  List<BreadcrumbSegment> _prevBreadcrumb = [];

  @override
  void initState() {
    super.initState();
    _vm = ReturV3DetailViewModel(
      noRetur: widget.noRetur,
      repository: ReturV3Repository(),
    );
    _vm.load();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _prevBreadcrumb = List<BreadcrumbSegment>.from(
          AppShell.breadcrumb.value,
        );
        AppShell.breadcrumb.value = [
          ..._prevBreadcrumb.map(
            (s) => BreadcrumbSegment(
              s.label,
              onTap: () {
                AppShell.breadcrumb.value = _prevBreadcrumb;
                AppShell.shellNavigatorKey.currentState?.pop();
              },
            ),
          ),
          BreadcrumbSegment(widget.noRetur),
        ];
      });
    }
  }

  @override
  void dispose() {
    if (!widget.embedded) {
      final prev = _prevBreadcrumb;
      final noRetur = widget.noRetur;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = AppShell.breadcrumb.value;
        if (current.isNotEmpty && current.last.label == noRetur) {
          AppShell.breadcrumb.value = prev;
        }
      });
    }
    _vm.dispose();
    super.dispose();
  }

  // ── Print flow ─────────────────────────────────────────────────────

  void _openPrintDialog() {
    if (_vm.outputs.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) =>
          _PrintPickerDialog(items: _vm.outputs, onPrint: _printEntries),
    );
  }

  Future<void> _printEntries(List<ReturV3Output> entries) async {
    if (entries.isEmpty) return;
    final lockApi = LabelPrintLockApi();
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    final acquiredCodes = <String>{};
    for (final entry in entries) {
      if (!mounted) break;
      try {
        await lockApi.acquire(entry.labelCode);
        acquiredCodes.add(entry.labelCode);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal lock ${entry.labelCode}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    final printedCodes = <String>{};
    final callbacks = entries.map((entry) {
      return () {
            printedCodes.add(entry.labelCode);
            () async {
              var needsIncrement = false;
              var needsRelease = false;
              try {
                final count = await _markAsPrinted(entry);
                if (count != null) lockVm.setPrintCount(entry.labelCode, count);
              } catch (_) {
                needsIncrement = true;
              }
              try {
                await lockApi.release(entry.labelCode);
              } catch (_) {
                needsRelease = true;
              }
              if (needsIncrement || needsRelease) {
                await queue.enqueue(
                  feature: _featureOf(entry),
                  noLabel: entry.labelCode,
                  needsIncrement: needsIncrement,
                  needsReleaseLock: needsRelease,
                );
              }
            }().ignore();
          }
          as VoidCallback;
    }).toList();

    try {
      await PdfPrintService(defaultSystem: 'pps').previewMultipleFromUrls(
        context: rootCtx,
        pdfUrls: entries.map((e) => Uri.parse(_pdfUrlOf(e))).toList(),
        title: 'Cetak ${entries.length} Label',
        onPrintedCallbacks: callbacks,
      );
    } finally {
      for (final entry in entries) {
        if (acquiredCodes.contains(entry.labelCode) &&
            !printedCodes.contains(entry.labelCode)) {
          () async {
            try {
              await lockApi.release(entry.labelCode);
            } catch (_) {
              await queue.enqueue(
                feature: _featureOf(entry),
                noLabel: entry.labelCode,
                needsReleaseLock: true,
              );
            }
          }().ignore();
        }
      }
      if (mounted) _vm.refreshOutputs();
    }
  }

  Future<void> _decide(String decision) async {
    final label = decision == 'DIGANTI' ? 'DIGANTI' : 'TIDAK DIGANTI';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Keputusan'),
        content: Text(
          'Tetapkan keputusan retur ini sebagai "$label"? Keputusan ini tidak bisa diubah kembali ke Pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Ya, Tetapkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _vm.decide(decision);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.decisionError ?? 'Gagal menetapkan keputusan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (decision == 'TIDAK_DIGANTI') {
      await _autoGenerateAllLabels();
    }
  }

  // ── Generate label (TIDAK_DIGANTI) ──────────────────────────────────

  /// Dipanggil otomatis begitu keputusan "Tidak Diganti" ditetapkan —
  /// men-generate label untuk semua item yang belum punya label sekaligus,
  /// jadi PIC tidak perlu klik "Generate Label" satu-satu lagi. Item BAGUS
  /// langsung digenerate; item REJECT tetap perlu isi berat + jenis reject
  /// lewat dialog (diminta berurutan, satu per satu). Tombol "Generate
  /// Label" per item tetap ada sebagai fallback kalau ada yang gagal/batal
  /// di sini (generate-label di backend idempotent, aman dipanggil ulang).
  Future<void> _autoGenerateAllLabels() async {
    final pending = _vm.items.where((it) => !it.hasGeneratedLabel).toList();
    for (final item in pending) {
      if (!mounted) return;
      await _generateLabel(item);
    }
  }

  Future<void> _generateLabel(ReturV3Item item) async {
    double? berat;
    int? idReject;
    if (item.isReject) {
      final result = await showDialog<ReturV3RejectGenerateResult>(
        context: context,
        builder: (_) => ReturV3RejectGenerateDialog(
          namaJenis: item.namaJenis ?? '-',
          pcs: item.pcs,
        ),
      );
      if (result == null) return;
      berat = result.berat;
      idReject = result.idReject;
    }
    final ok = await _vm.generateLabelForItem(
      item.idItem,
      berat: berat,
      idReject: idReject,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.generateError ?? 'Gagal generate label'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Scan (DIGANTI) ───────────────────────────────────────────────────

  /// Satu dialog scan untuk semua item pada retur ini — backend yang
  /// otomatis mendeteksi item mana yang cocok berdasarkan kategori+jenis
  /// label yang discan (lihat `ReturV3DetailViewModel.scanAuto`).
  void _openScanDialogAuto() {
    showDialog<void>(
      context: context,
      builder: (_) => ScanLabelDialog(
        headerSubtitle: 'Scan label untuk memenuhi turnover',
        manualHint: 'Scan atau ketik kode label',
        onLookup: _vm.scanAuto,
      ),
    );
  }

  Future<void> _undoScan(ReturV3Item item, int idTurnover) async {
    final ok = await _vm.undoScan(item.idItem, idTurnover);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_vm.decisionError ?? 'Gagal membatalkan scan'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _flagKirim() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Flag Kirim'),
        content: const Text(
          'Tandai retur ini sudah dikirim? Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _kSuccess),
            child: const Text('Ya, Kirim'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _vm.flagKirim();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.flagError ?? 'Gagal flag kirim'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReturV3DetailViewModel>.value(
      value: _vm,
      child: Consumer<ReturV3DetailViewModel>(
        builder: (context, vm, _) {
          final canFlag = context.watch<PermissionViewModel>().can(
            'retur:update',
          );
          final showPrintFab =
              vm.header?.isTidakDiganti == true && vm.outputs.isNotEmpty;
          final isDiganti = vm.header?.isDiganti == true;
          final alreadyFlagged = vm.header?.flagKirim == true;
          // Selama status DIGANTI: FAB scan tampil sampai semua item
          // terpenuhi, lalu otomatis berganti jadi FAB "Flag Kirim" (kalau
          // sudah pernah di-flag, tidak ada FAB lagi — sudah selesai).
          final showFlagKirimFab =
              isDiganti && !alreadyFlagged && vm.canFlagKirim && canFlag;
          final showScanFab = isDiganti && !alreadyFlagged && !vm.canFlagKirim;
          return Scaffold(
            backgroundColor: _kSurface,
            floatingActionButton: showPrintFab
                ? FloatingActionButton(
                    onPressed: _openPrintDialog,
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.print_rounded),
                  )
                : showFlagKirimFab
                ? FloatingActionButton.extended(
                    onPressed: vm.isFlagging ? null : _flagKirim,
                    backgroundColor: _kSuccess,
                    foregroundColor: Colors.white,
                    icon: vm.isFlagging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.local_shipping_rounded),
                    label: const Text('Flag Kirim'),
                  )
                : showScanFab
                ? FloatingActionButton.extended(
                    onPressed: _openScanDialogAuto,
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  )
                : null,
            body: RefreshIndicator(onRefresh: vm.load, child: _buildBody(vm)),
          );
        },
      ),
    );
  }

  Widget _buildBody(ReturV3DetailViewModel vm) {
    if (vm.isLoading && vm.header == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.header == null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Center(
            child: Text(vm.error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      );
    }

    final header = vm.header;
    if (header == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(header: header),
        const SizedBox(height: 16),
        if (header.isPending) _PendingSection(vm: vm, screen: this),
        if (header.isTidakDiganti) _TidakDigantiSection(vm: vm, screen: this),
        if (header.isDiganti) _DigantiSection(vm: vm, screen: this),
      ],
    );
  }
}

// ── Header summary card ─────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final ReturV3Header header;

  const _HeaderCard({required this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header.noRetur,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${header.tanggalText} · ${header.namaPembeli ?? '-'}',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
                if (header.keterangan != null &&
                    header.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    header.keterangan!,
                    style: const TextStyle(fontSize: 12.5, color: _kMuted),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: header.statusRetur),
              if (header.flagKirim) ...[
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.local_shipping_rounded, size: 14, color: _kSuccess),
                    SizedBox(width: 4),
                    Text(
                      'Sudah dikirim',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kSuccess,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    MaterialColor color;
    String label;
    switch (status.toUpperCase()) {
      case 'DIGANTI':
        color = Colors.blue;
        label = 'Diganti';
        break;
      case 'TIDAK_DIGANTI':
        color = Colors.orange;
        label = 'Tidak Diganti';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
      ),
    );
  }
}

// ── PENDING section ───────────────────────────────────────────────────

class _PendingSection extends StatelessWidget {
  final ReturV3DetailViewModel vm;
  final _ReturV3DetailScreenState screen;

  const _PendingSection({required this.vm, required this.screen});

  @override
  Widget build(BuildContext context) {
    final canDecide = context.watch<PermissionViewModel>().can(
      'retur:update',
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              'Item Retur',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (vm.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Belum ada item',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: vm.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
              itemBuilder: (context, i) => _PendingItemRow(item: vm.items[i]),
            ),
          if (vm.items.isNotEmpty && canDecide) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: vm.isDeciding
                          ? null
                          : () => screen._decide('TIDAK_DIGANTI'),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Tidak Diganti'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          vm.isDeciding ? null : () => screen._decide('DIGANTI'),
                      icon: const Icon(Icons.autorenew, size: 16),
                      label: const Text('Diganti'),
                      style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris item retur di section PENDING — satu baris saja, tampilan murni
/// (nama jenis, pcs, kondisi bagus/reject). Tanpa badge kategori BJ/FWIP
/// (beda dengan `_ItemTile` yang dipakai di section TIDAK_DIGANTI). Item
/// hanya bisa diisi lewat form pembuatan retur — section ini read-only,
/// tidak ada tombol tambah/hapus.
class _PendingItemRow extends StatelessWidget {
  final ReturV3Item item;

  const _PendingItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.namaJenis ?? 'Jenis #${item.idJenis}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${item.pcs} pcs',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isReject
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.kategoriInput,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: item.isReject ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris item retur di section TIDAK_DIGANTI — format sama seperti
/// `_PendingItemRow` (satu baris: nama jenis, pcs, kondisi bagus/reject,
/// tanpa badge kategori BJ/FWIP), ditambah slot `trailing` untuk tombol
/// generate label / chip kode label yang sudah dibuat.
class _ItemTile extends StatelessWidget {
  final ReturV3Item item;
  final Widget? trailing;

  const _ItemTile({required this.item, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.namaJenis ?? 'Jenis #${item.idJenis}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${item.pcs} pcs',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isReject
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.kategoriInput,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: item.isReject ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── TIDAK_DIGANTI section ───────────────────────────────────────────────

class _TidakDigantiSection extends StatelessWidget {
  final ReturV3DetailViewModel vm;
  final _ReturV3DetailScreenState screen;

  const _TidakDigantiSection({required this.vm, required this.screen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              'Generate Label per Item',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: vm.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
            itemBuilder: (context, i) {
              final item = vm.items[i];
              final generating = vm.generatingItemIds.contains(item.idItem);
              return _ItemTile(
                item: item,
                trailing: item.hasGeneratedLabel
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: _kSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.generatedLabelCode!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _kSuccess,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          height: 32,
                          child: FilledButton(
                            onPressed: generating
                                ? null
                                : () => screen._generateLabel(item),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: const TextStyle(fontSize: 11.5),
                            ),
                            child: generating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Generate Label'),
                          ),
                        ),
                      ),
              );
            },
          ),
          if (vm.outputs.isNotEmpty) ...[
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${vm.outputs.length} label sudah dibuat · '
                '${vm.outputs.where((o) => o.hasBeenPrinted).length} dicetak',
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── DIGANTI section ─────────────────────────────────────────────────────

class _DigantiSection extends StatelessWidget {
  final ReturV3DetailViewModel vm;
  final _ReturV3DetailScreenState screen;

  const _DigantiSection({required this.vm, required this.screen});

  @override
  Widget build(BuildContext context) {
    final flagKirim = vm.header?.flagKirim == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              'Progress Turnover per Item',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: vm.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
            itemBuilder: (context, i) {
              final item = vm.items[i];
              final t = vm.turnoverFor(item.idItem);
              return _TurnoverTile(
                item: item,
                turnover: t,
                flagKirim: flagKirim,
                onUndoScan: (idTurnover) => screen._undoScan(item, idTurnover),
              );
            },
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  flagKirim
                      ? Icons.local_shipping_rounded
                      : vm.canFlagKirim
                      ? Icons.check_circle_rounded
                      : Icons.qr_code_scanner_rounded,
                  size: 16,
                  color: flagKirim || vm.canFlagKirim ? _kSuccess : _kMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flagKirim
                        ? 'Sudah dikirim.'
                        : vm.canFlagKirim
                        ? 'Semua item terpenuhi — tekan tombol Flag Kirim di kanan bawah.'
                        : 'Scan label lewat tombol Scan di kanan bawah sampai semua item terpenuhi.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: flagKirim || vm.canFlagKirim ? _kSuccess : _kMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnoverTile extends StatelessWidget {
  final ReturV3Item item;
  final ReturV3Turnover? turnover;
  final bool flagKirim;
  final ValueChanged<int> onUndoScan;

  const _TurnoverTile({
    required this.item,
    required this.turnover,
    required this.flagKirim,
    required this.onUndoScan,
  });

  @override
  Widget build(BuildContext context) {
    final scanned = turnover?.scannedPcs ?? 0;
    final target = turnover?.targetPcs ?? item.pcs;
    final fulfilled = turnover?.isFulfilled ?? false;
    final progress = target > 0 ? (scanned / target).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.namaJenis ?? 'Jenis #${item.idJenis}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
              ),
              Text(
                '$scanned/$target pcs',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fulfilled ? _kSuccess : _kMuted,
                ),
              ),
              if (fulfilled) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: _kSuccess),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE5E7EB),
              color: fulfilled ? _kSuccess : _kPrimary,
            ),
          ),
          if (turnover != null && turnover!.scans.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: turnover!.scans
                  .map(
                    (s) => Chip(
                      label: Text(
                        '${s.labelCode} (${s.pcs})',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      onDeleted: flagKirim
                          ? null
                          : () => onUndoScan(s.idTurnover),
                      deleteIconColor: Colors.red.shade400,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Print picker dialog (single group, mirrors retur_v2's) ──────────────

class _PrintPickerDialog extends StatefulWidget {
  final List<ReturV3Output> items;
  final void Function(List<ReturV3Output> selected) onPrint;

  const _PrintPickerDialog({required this.items, required this.onPrint});

  @override
  State<_PrintPickerDialog> createState() => _PrintPickerDialogState();
}

class _PrintPickerDialogState extends State<_PrintPickerDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.map((e) => e.labelCode).toSet();
  }

  bool get _allSelected => _selected.length == widget.items.length;

  void _toggleAll() => setState(() {
    if (_allSelected) {
      _selected.clear();
    } else {
      _selected.addAll(widget.items.map((e) => e.labelCode));
    }
  });

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.items
        .where((e) => _selected.contains(e.labelCode))
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pilih Label untuk Dicetak',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(_allSelected ? 'Batalkan Semua' : 'Pilih Semua'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final item = widget.items[i];
                  final selected = _selected.contains(item.labelCode);
                  return InkWell(
                    onTap: () => setState(() {
                      if (selected) {
                        _selected.remove(item.labelCode);
                      } else {
                        _selected.add(item.labelCode);
                      }
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _kPrimary.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? _kPrimary.withValues(alpha: 0.35)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: selected ? _kPrimary : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaJenis?.isNotEmpty == true
                                      ? item.namaJenis!
                                      : item.labelCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.labelCode,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.qty} ${item.uom}'.trim(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton.icon(
                onPressed: selectedItems.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onPrint(selectedItems);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.print, size: 16),
                label: Text('Cetak ${selectedItems.length} Label'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
