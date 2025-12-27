import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../view_model/reject_view_model.dart';
import '../model/reject_header_model.dart';

import '../widgets/interactive_popover.dart';
import '../widgets/reject_row_popover.dart';
import '../widgets/reject_action_bar.dart';
import '../widgets/reject_header_table.dart';
import '../widgets/reject_form_dialog.dart';
import '../widgets/reject_delete_dialog.dart';
import '../widgets/reject_partial_info_popover.dart';

class RejectScreen extends StatefulWidget {
  const RejectScreen({super.key});

  @override
  State<RejectScreen> createState() => _RejectScreenState();
}

class _RejectScreenState extends State<RejectScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _detailScrollController = ScrollController();
  Timer? _debounce;

  /// Satu popover controller untuk:
  /// - Row popover (edit/print/delete)
  /// - Partial info popover
  final InteractivePopover _popover = InteractivePopover();

  bool _isPartialHeader(RejectHeader h) {
    // sesuaikan kalau nama field beda (mis: IsPartial / isPartialBool / partial)
    return h.isPartial == 1;
  }

  Future<void> _onEditHeader(RejectHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Edit Tidak Tersedia',
        message: 'Label ini tidak dapat diedit karena telah di partial.',
      );
      return;
    }

    _showFormDialog(header: header);
  }

  Future<void> _onDeleteHeader(RejectHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Delete Tidak Tersedia',
        message: 'Label ini tidak dapat dihapus karena telah di partial.',
      );
      return;
    }

    _confirmDelete(header);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RejectViewModel>();
      vm.resetForScreen();
      vm.fetchHeaders();
    });
  }

  @override
  void dispose() {
    _popover.dispose();
    _detailScrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ==========================
  // SEARCH
  // ==========================

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<RejectViewModel>().fetchHeaders(search: query);
    });
  }

  // ==========================
  // FORM DIALOG
  // ==========================

  void _showFormDialog({RejectHeader? header}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => RejectFormDialog(
        header: header,
      ),
    );
  }

  // ==========================
  // DELETE FLOW
  // ==========================

  void _confirmDelete(RejectHeader header) {
    showDialog(
      context: context,
      builder: (_) => RejectDeleteDialog(
        header: header,
        onConfirm: () async {
          // Tutup dialog dulu
          Navigator.of(context).pop();

          // Baru eksekusi delete
          await _handleDelete(header);
        },
      ),
    );
  }

  Future<void> _handleDelete(RejectHeader header) async {
    final vm = context.read<RejectViewModel>();
    final no = header.noReject;

    try {
      DialogService.instance.showLoading(message: 'Deleting $no...');
      await vm.deleteReject(no);
      DialogService.instance.hideLoading();

      await DialogService.instance.showSuccess(
        title: 'Deleted',
        message: 'Label $no has been deleted.',
      );

      vm.setSelected(null);
      if (_detailScrollController.hasClients) {
        _detailScrollController.jumpTo(0);
      }
    } catch (e) {
      DialogService.instance.hideLoading();
      await DialogService.instance.showError(
        title: 'Failed',
        message: vm.errorMessage.isNotEmpty ? vm.errorMessage : e.toString(),
      );
    }
  }

  // ==========================
  // POPOVER HELPERS
  // ==========================

  void _closeContextMenu() {
    _popover.hide();
  }

  /// Long-press handler: set highlight & show row popover (Edit / Print / Delete)
  Future<void> _onItemLongPress(
      RejectHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<RejectViewModel>();

    // Pindah highlight ke row ini
    vm.setSelected(header.noReject);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: RejectRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () async {
          _closeContextMenu();
          await _onEditHeader(header);
        },
        onDelete: () async {
          if (context.read<RejectViewModel>().isLoading) return;
          _closeContextMenu();
          await _onDeleteHeader(header);
        },
        onPrint: () {
          _closeContextMenu();
          // printing sudah di-handle di dalam RejectRowPopover
        },
      ),
      preferAbove: true,
      verticalGap: 8,
      backdropOpacity: 0.06,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      startScale: 0.94,
    );
  }

  /// Tap handler khusus untuk row yang punya partial.
  /// Karena HorizontalPagedTable tidak kirim Offset posisi tap,
  /// kita pilih posisi "default" di layar (misal tengah-atas).
  Future<void> _onPartialTap(RejectHeader header) async {
    final vm = context.read<RejectViewModel>();

    // Set selected row
    vm.setSelected(header.noReject);

    final size = MediaQuery.of(context).size;
    final defaultPos = Offset(size.width * 0.5, size.height * 0.3);

    await showRejectPartialInfoPopover(
      context: context,
      vm: vm,
      noReject: header.noReject,
      popover: _popover,
      globalPosition: defaultPos,
    );
  }

  // ==========================
  // BUILD
  // ==========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<RejectViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL REJECT (…)'
                : 'LABEL REJECT (${vm.totalCount})';
            return Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Master table only (no detail panel yet)
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  RejectActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<RejectViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: Consumer<RejectViewModel>(
                      builder: (context, vm, _) {
                        return RejectHeaderTable(
                          pagingController: vm.pagingController,
                          selectedNoReject: vm.selectedNoReject,
                          onItemTap: (header) {
                            vm.setSelected(header.noReject);
                            // optional: vm.fetchDetail(header.noReject);
                          },
                          onItemLongPress: _onItemLongPress,
                          onPartialTap: _onPartialTap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
