// lib/features/furniture_wip/view/reject_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../view_model/furniture_wip_view_model.dart';
import '../model/furniture_wip_header_model.dart';

import '../widgets/interactive_popover.dart';
import '../widgets/furniture_wip_row_popover.dart';
import '../widgets/furniture_wip_action_bar.dart';
import '../widgets/furniture_wip_header_table.dart';
import '../widgets/furniture_wip_form_dialog.dart';
import '../widgets/furniture_wip_delete_dialog.dart';
import '../widgets/furniture_wip_partial_info_popover.dart';

class FurnitureWipScreen extends StatefulWidget {
  const FurnitureWipScreen({super.key});

  @override
  State<FurnitureWipScreen> createState() => _FurnitureWipScreenState();
}

class _FurnitureWipScreenState extends State<FurnitureWipScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _detailScrollController = ScrollController();
  Timer? _debounce;

  /// Satu popover controller untuk:
  /// - Row popover (edit/print/delete)
  /// - Partial info popover
  final InteractivePopover _popover = InteractivePopover();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<FurnitureWipViewModel>();
      // Bebas: implementasi dalam VM boleh reset search + refresh paging.
      vm.resetForScreen();
      vm.fetchHeaders(); // di VM bisa di-mapping ke pagingController.refresh()
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
      context.read<FurnitureWipViewModel>().fetchHeaders(search: query);
      // Tidak perlu scrollController lagi; paging table akan handle sendiri.
    });
  }

  void _showFormDialog({FurnitureWipHeader? header}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => FurnitureWipFormDialog(
        header: header,
      ),
    );
  }

  void _confirmDelete(FurnitureWipHeader header) {
    showDialog(
      context: context,
      builder: (_) => FurnitureWipDeleteDialog(
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
      FurnitureWipHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<FurnitureWipViewModel>();

    // Pindah highlight ke row ini
    vm.setSelected(header.noFurnitureWip);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: FurnitureWipRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () {
          _closeContextMenu();
          _showFormDialog(header: header);
        },
        onDelete: () {
          if (context.read<FurnitureWipViewModel>().isLoading) return;
          _closeContextMenu();
          _confirmDelete(header);
        },
        onPrint: () {
          _closeContextMenu();
          // printing sudah dihandle di dalam FurnitureWipRowPopover
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
  Future<void> _onPartialTap(FurnitureWipHeader header) async {
    final vm = context.read<FurnitureWipViewModel>();

    // Set selected row
    vm.setSelected(header.noFurnitureWip);

    final size = MediaQuery.of(context).size;
    final defaultPos = Offset(size.width * 0.5, size.height * 0.3);

    // Tampilkan popover partial menggunakan controller yang sama
    await showFurnitureWipPartialInfoPopover(
      context: context,
      vm: vm,
      noFurnitureWip: header.noFurnitureWip,
      popover: _popover,
      globalPosition: defaultPos,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<FurnitureWipViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL FURNITURE WIP (…)'
                : 'LABEL FURNITURE WIP (${vm.totalCount})';
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
                  FurnitureWipActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<FurnitureWipViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: Consumer<FurnitureWipViewModel>(
                      builder: (context, vm, _) {
                        return FurnitureWipHeaderTable(
                          // ✅ pakai PagingController dari ViewModel
                          pagingController: vm.pagingController,
                          // ✅ highlight row terpilih
                          selectedNoFurnitureWip: vm.selectedNoFurnitureWip,
                          // Tap biasa: hanya set selected row (dan optional: load detail)
                          onItemTap: (header) {
                            vm.setSelected(header.noFurnitureWip);
                            // optional: vm.fetchDetail(header.noFurnitureWip);
                          },
                          // Long-press: row popover (Edit / Print / Delete)
                          onItemLongPress: _onItemLongPress,
                          // Tap khusus untuk row partial (isPartialBool == true)
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

  Future<void> _handleDelete(FurnitureWipHeader header) async {
    final vm = context.read<FurnitureWipViewModel>();
    final no = header.noFurnitureWip;

    try {
      DialogService.instance.showLoading(message: 'Deleting $no...');
      await vm.deleteFurnitureWip(no);
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
