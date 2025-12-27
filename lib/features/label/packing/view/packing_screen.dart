// lib/features/packing/view/reject_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../view_model/packing_view_model.dart';
import '../model/packing_header_model.dart';

import '../widgets/interactive_popover.dart';
import '../widgets/packing_row_popover.dart';
import '../widgets/packing_action_bar.dart';
import '../widgets/packing_header_table.dart';
import '../widgets/packing_form_dialog.dart';
import '../widgets/packing_delete_dialog.dart';
import '../widgets/packing_partial_info_popover.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _detailScrollController = ScrollController();
  Timer? _debounce;

  /// Satu popover controller untuk:
  /// - Row popover (edit/print/delete)
  /// - Partial info popover
  final InteractivePopover _popover = InteractivePopover();

  bool _isPartialHeader(PackingHeader h) {
    // sesuaikan kalau nama field beda (mis: IsPartial / isPartialBool / partial)
    return h.isPartial == 1;
  }

  Future<void> _onEditHeader(PackingHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Edit Tidak Tersedia',
        message: 'Label ini tidak dapat diedit karena telah di partial.',
      );
      return;
    }

    _showFormDialog(header: header);
  }

  Future<void> _onDeleteHeader(PackingHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Delete Tidak Tersedia',
        message: 'Label ${header.noBJ} tidak dapat dihapus karena telah di partial.',
      );
      return;
    }

    _confirmDelete(header);
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PackingViewModel>();
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<PackingViewModel>().fetchHeaders(search: query);
    });
  }

  void _showFormDialog({PackingHeader? header}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => PackingFormDialog(
        header: header,
      ),
    );
  }

  void _confirmDelete(PackingHeader header) {
    showDialog(
      context: context,
      builder: (_) => PackingDeleteDialog(
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

  void _closeContextMenu() {
    _popover.hide();
  }

  /// Long-press handler: set highlight & show row popover (Edit / Print / Delete)
  Future<void> _onItemLongPress(
      PackingHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<PackingViewModel>();

    // Pindah highlight ke row ini
    vm.setSelected(header.noBJ);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: PackingRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () async {
          _closeContextMenu();
          await _onEditHeader(header);
        },
        onDelete: () async {
          if (context.read<PackingViewModel>().isLoading) return;
          _closeContextMenu();
          await _onDeleteHeader(header);
        },

        onPrint: () {
          _closeContextMenu();
          // printing sudah dihandle di dalam PackingRowPopover
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
  Future<void> _onPartialTap(PackingHeader header) async {
    final vm = context.read<PackingViewModel>();

    // Set selected row
    vm.setSelected(header.noBJ);

    final size = MediaQuery.of(context).size;
    final defaultPos = Offset(size.width * 0.5, size.height * 0.3);

    await showPackingPartialInfoPopover(
      context: context,
      vm: vm,
      noBJ: header.noBJ,
      popover: _popover,
      globalPosition: defaultPos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<PackingViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL BARANG JADI (…)'
                : 'LABEL BARANG JADI (${vm.totalCount})';
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
                  PackingActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<PackingViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: Consumer<PackingViewModel>(
                      builder: (context, vm, _) {
                        return PackingHeaderTable(
                          pagingController: vm.pagingController,
                          selectedNoBJ: vm.selectedNoBJ,
                          onItemTap: (header) {
                            vm.setSelected(header.noBJ);
                            // optional: vm.fetchDetail(header.noBJ);
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

  Future<void> _handleDelete(PackingHeader header) async {
    final vm = context.read<PackingViewModel>();
    final no = header.noBJ;

    try {
      DialogService.instance.showLoading(message: 'Deleting $no...');
      await vm.deletePacking(no);
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
}
