import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/dialog_service.dart';
import '../view_model/crusher_view_model.dart';
import '../model/crusher_header_model.dart';
import '../widgets/interactive_popover.dart';
import '../widgets/crusher_row_popover.dart';
import '../widgets/crusher_action_bar.dart';
import '../widgets/crusher_header_table.dart';
import '../widgets/crusher_form_dialog.dart';
import '../widgets/crusher_delete_dialog.dart';

class CrusherScreen extends StatefulWidget {
  const CrusherScreen({super.key});

  @override
  State<CrusherScreen> createState() => _CrusherScreenState();
}

class _CrusherScreenState extends State<CrusherScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _debounce;

  // Popover animasi (custom)
  final InteractivePopover _popover = InteractivePopover();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrusherViewModel>().fetchHeaders();
      context.read<CrusherViewModel>().resetForScreen();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _popover.dispose(); // langsung bersih tanpa animasi
    _scrollController.dispose();
    _detailScrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Tutup popover saat scroll supaya tidak "mengambang"
    if (_popover.isShown) {
      _popover.hide();
    }

    final vm = context.read<CrusherViewModel>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && vm.hasMore) {
        _isLoadingMore = true;
        vm.loadMore().then((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<CrusherViewModel>().fetchHeaders(search: query);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _showFormDialog({CrusherHeader? header}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => CrusherFormDialog(
        header: header,
        onSave: (headerData) {
          final vm = context.read<CrusherViewModel>();
          if (header != null) {
            // vm.updateWashing(headerData, detailsData);
          } else {
            // vm.createWashing(headerData, detailsData);
          }
        },
      ),
    );
  }

  void _confirmDelete(CrusherHeader header) {
    showDialog(
      context: context,
      builder: (_) => CrusherDeleteDialog(
        header: header,
        onConfirm: () async {
          // Tutup dialog dahulu
          Navigator.of(context).pop();

          // Lanjut eksekusi delete
          await _handleDelete(header);
        },
      ),
    );
  }



  // Tutup popover (tidak mengubah selection — biarkan tetap menandai item aktif)
  void _closeContextMenu() {
    _popover.hide();
  }

  /// Long-press handler: pindahkan highlight ke item & tampilkan popover.
  Future<void> _onItemLongPress(
      CrusherHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<CrusherViewModel>();

    // Pindahkan highlight saat long-press
    vm.setSelected(header.noCrusher);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: CrusherRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () {
          _closeContextMenu();
          _showFormDialog(header: header);
        },
        onDelete: () {
          if (context.read<CrusherViewModel>().isLoading) return;
          _closeContextMenu();
          _confirmDelete(header);
        },
        onPrint: () {
          _closeContextMenu();
          // TODO: print/preview
        },
      ),
      // animasi & penempatan cerdas
      preferAbove: true,
      verticalGap: 8,
      backdropOpacity: 0.06,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack, // overshoot untuk SCALE tetap aman
      startScale: 0.94,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<CrusherViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL CRUSHER (…)'
                : 'LABEL CRUSHER (${vm.totalCount})';
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
          // Master Table
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  CrusherActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<CrusherViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: CrusherHeaderTable(
                      scrollController: _scrollController,
                      onItemTap: (header) {
                        final vm = context.read<CrusherViewModel>();
                        // Klik: pindahkan highlight & (opsional) load detail
                        vm.setSelected(header.noCrusher);
                      },
                      // Long-press: pindahkan highlight & tampilkan popover
                      onItemLongPress: _onItemLongPress,
                      // ⚠️ Tidak perlu highlightedNoWashing lagi
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

  Future<void> _handleDelete(CrusherHeader header) async {
    final vm = context.read<CrusherViewModel>();
    final no = header.noCrusher;

    try {
      DialogService.instance.showLoading(message: 'Menghapus $no...');
      await vm.deleteCrusher(no);
      DialogService.instance.hideLoading();

      // Success toast/snackbar/dialog
      await DialogService.instance.showSuccess(
        title: 'Terhapus',
        message: 'Label $no berhasil dihapus.',
      );

      // Bersihkan selection & (opsional) scroll detail ke atas
      vm.setSelected(null);
      if (_detailScrollController.hasClients) {
        _detailScrollController.jumpTo(0);
      }
    } catch (e) {
      DialogService.instance.hideLoading();
      await DialogService.instance.showError(
        title: 'Gagal',
        message: vm.errorMessage.isNotEmpty ? vm.errorMessage : e.toString(),
      );
    }
  }



}
