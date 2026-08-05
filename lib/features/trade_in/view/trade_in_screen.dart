import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/atlas_data_table.dart';
import '../../../common/widgets/atlas_paged_data_table.dart';
import '../../../common/widgets/confirm_dialog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/label_print_lock_api.dart';
import '../../../core/services/dialog_service.dart';
import '../../../core/services/label_print_sync_queue.dart';
import '../../../core/utils/pdf_print_service.dart';
import '../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../label/reject/repository/reject_repository.dart';
import '../model/trade_in_reject_detail.dart';
import '../model/trade_in_transaction.dart';
import '../view_model/trade_in_list_view_model.dart';
import 'trade_in_form_dialog.dart';
import 'trade_in_preview_dialog.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

class TradeInScreen extends StatefulWidget {
  const TradeInScreen({super.key});

  @override
  State<TradeInScreen> createState() => _TradeInScreenState();
}

class _TradeInScreenState extends State<TradeInScreen> {
  late final TradeInListViewModel _vm;
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = TradeInListViewModel();
    _vm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openForm() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const TradeInFormDialog(),
    );
    if (saved == true && mounted) _vm.refresh();
  }

  void _openPreview(TradeInTransaction item) {
    showDialog<void>(
      context: context,
      builder: (_) => TradeInPreviewDialog(
        item: item,
        onPrintReject: _printReject,
        onDelete: () => _onDelete(item),
      ),
    );
  }

  /// Konfirmasi + hapus 1 penerimaan trade-in. Return `true` kalau berhasil
  /// dihapus, supaya caller (dialog preview) tahu kapan harus menutup diri.
  Future<bool> _onDelete(TradeInTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Hapus Penerimaan',
        message:
            'Yakin ingin menghapus penerimaan ${item.noPenerimaan} '
            '("${item.supplier}")? Data reject terkait akan ikut terhapus '
            'dan tidak dapat dikembalikan.',
        confirmLabel: 'Hapus',
        confirmIcon: Icons.delete_outline_rounded,
      ),
    );
    if (confirmed != true) return false;

    final errorMessage = await _vm.deleteItem(item.noPenerimaan);
    if (!mounted) return false;
    if (errorMessage != null) {
      await DialogService.instance.showError(
        title: 'Gagal Menghapus',
        message: errorMessage,
      );
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.noPenerimaan} berhasil dihapus'),
        backgroundColor: Colors.green.shade700,
      ),
    );
    return true;
  }

  /// Cetak label reject terkait 1 penerimaan trade-in — pola sama dengan
  /// `_printEntries` di ReturV2DetailScreen: lock label, preview PDF,
  /// tandai HasBeenPrinted & lepas lock setelah user selesai print, dengan
  /// fallback ke [LabelPrintSyncQueue] kalau mark/lepas lock gagal.
  Future<void> _printReject(TradeInRejectDetail reject) async {
    final noReject = reject.noReject;
    if (noReject.isEmpty) return;

    final lockApi = LabelPrintLockApi();
    final repo = RejectRepository(api: ApiClient());
    final lockVm = context.read<LabelPrintLockSocketManager>();
    final queue = context.read<LabelPrintSyncQueue>();
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    var isLockAcquired = false;
    var isPrinted = false;

    try {
      await lockApi.acquire(noReject);
      isLockAcquired = true;

      await PdfPrintService(defaultSystem: 'pps').previewFromUrl(
        context: rootCtx,
        pdfUrl: Uri.parse(ApiConstants.rejectLabelPdf(noReject)),
        title: noReject,
        onPrinted: () {
          isPrinted = true;
          () async {
            var needsIncrement = false;
            var needsRelease = false;
            try {
              final count = await repo.markAsPrinted(noReject);
              if (count != null) lockVm.setPrintCount(noReject, count);
            } catch (_) {
              needsIncrement = true;
            }
            try {
              await lockApi.release(noReject);
            } catch (_) {
              needsRelease = true;
            }
            if (needsIncrement || needsRelease) {
              await queue.enqueue(
                feature: 'reject',
                noLabel: noReject,
                needsIncrement: needsIncrement,
                needsReleaseLock: needsRelease,
              );
            }
          }().ignore();
        },
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (isLockAcquired && !isPrinted) {
        () async {
          try {
            await lockApi.release(noReject);
          } catch (_) {
            await queue.enqueue(
              feature: 'reject',
              noLabel: noReject,
              needsReleaseLock: true,
            );
          }
        }().ignore();
      }
      if (mounted) _vm.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TradeInListViewModel>.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: _kSurface,
        floatingActionButton: FloatingActionButton(
          onPressed: _openForm,
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
        body: Builder(
          builder: (context) {
            final vm = context.watch<TradeInListViewModel>();
            return Column(
              children: [
                _buildToolbar(vm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AtlasPagedDataTable<TradeInTransaction>(
                      pagingController: vm.pagingController,
                      columns: _columns(),
                      onRowTap: _openPreview,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(TradeInListViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtl,
              onChanged: vm.setSearchDebounced,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari no. penerimaan / supplier / sales person...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchCtl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          _searchCtl.clear();
                          vm.clearSearch();
                          setState(() {});
                        },
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

  List<AtlasTableColumn<TradeInTransaction>> _columns() {
    return [
      AtlasTableColumn<TradeInTransaction>(
        title: 'TANGGAL',
        width: 130,
        cellBuilder: (ctx, item, state) => Text(
          item.tanggal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF1A1D23),
          ),
        ),
      ),
      AtlasTableColumn<TradeInTransaction>(
        title: 'SALES PERSON',
        width: 200,
        cellBuilder: (ctx, item, state) => Text(
          item.salesPersonName.isEmpty ? '-' : item.salesPersonName,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AtlasTableColumn<TradeInTransaction>(
        title: 'SUPPLIER',
        width: 220,
        cellBuilder: (ctx, item, state) => Text(
          item.supplier.isEmpty ? '-' : item.supplier,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AtlasTableColumn<TradeInTransaction>(
        title: 'REJECT',
        width: 260,
        cellBuilder: (ctx, item, state) {
          final reject = item.reject;
          if (reject == null) {
            return Text(
              '-',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            );
          }
          return Text(
            '${reject.namaReject} · ${_formatWeight(reject.berat)} kg',
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    ];
  }

  String _formatWeight(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
