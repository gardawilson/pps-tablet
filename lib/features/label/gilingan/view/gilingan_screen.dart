// lib/features/gilingan/view/reject_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../view_model/gilingan_view_model.dart';
import '../model/gilingan_header_model.dart';

import '../widgets/interactive_popover.dart';
import '../widgets/gilingan_row_popover.dart';
import '../widgets/gilingan_action_bar.dart';
import '../widgets/gilingan_header_table.dart';
import '../widgets/gilingan_form_dialog.dart';
import '../widgets/gilingan_delete_dialog.dart';
import '../widgets/gilingan_partial_info_popover.dart';

class GilinganScreen extends StatefulWidget {
  const GilinganScreen({super.key});

  @override
  State<GilinganScreen> createState() => _GilinganScreenState();
}

class _GilinganScreenState extends State<GilinganScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _debounce;

  /// Satu popover controller untuk:
  /// - Row popover (edit/print/delete)
  /// - Partial info popover
  final InteractivePopover _popover = InteractivePopover();

  bool _isPartialHeader(GilinganHeader h) {
    // sesuaikan kalau nama field beda (mis: IsPartial / isPartialBool / partial)
    return h.isPartial == 1;
  }

  Future<void> _onEditHeader(GilinganHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Edit Tidak Tersedia',
        message: 'Label ini tidak dapat diedit karena telah di partial.',
      );
      return;
    }

    _showFormDialog(header: header);
  }

  Future<void> _onDeleteHeader(GilinganHeader header) async {
    if (_isPartialHeader(header)) {
      await DialogService.instance.showError(
        title: 'Hapus Tidak Tersedia',
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
      final vm = context.read<GilinganViewModel>();
      vm.fetchHeaders();
      vm.resetForScreen();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _popover.dispose();
    _scrollController.dispose();
    _detailScrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Tutup semua popover ketika scroll
    if (_popover.isShown) {
      _popover.hide();
    }

    final vm = context.read<GilinganViewModel>();
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
      context.read<GilinganViewModel>().fetchHeaders(search: query);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _showFormDialog({GilinganHeader? header}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => GilinganFormDialog(
        header: header,
      ),
    );
  }

  void _confirmDelete(GilinganHeader header) {
    showDialog(
      context: context,
      builder: (_) => GilinganDeleteDialog(
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
      GilinganHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<GilinganViewModel>();

    // Pindah highlight ke row ini
    vm.setSelected(header.noGilingan);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: GilinganRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () async {
          _closeContextMenu();
          await _onEditHeader(header);
        },
        onDelete: () async {
          if (context.read<GilinganViewModel>().isLoading) return;
          _closeContextMenu();
          await _onDeleteHeader(header);
        },
        onPrint: () {
          _closeContextMenu();
          // printing sudah dihandle di dalam GilinganRowPopover (PdfPrintService)
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

  /// Tap handler khusus untuk row yang punya partial: tampilkan popover partial.
  Future<void> _onPartialTap(
      GilinganHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<GilinganViewModel>();

    // Set selected row
    vm.setSelected(header.noGilingan);

    // Tampilkan popover partial menggunakan controller yang sama
    await showGilinganPartialInfoPopover(
      context: context,
      vm: vm,
      noGilingan: header.noGilingan,
      popover: _popover,
      globalPosition: globalPosition,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<GilinganViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL GILINGAN (…)'
                : 'LABEL GILINGAN (${vm.totalCount})';
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
                  GilinganActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<GilinganViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: GilinganHeaderTable(
                      scrollController: _scrollController,
                      // Tap biasa: hanya set selected row
                      onItemTap: (header) {
                        final vm = context.read<GilinganViewModel>();
                        vm.setSelected(header.noGilingan);
                        // optional: load details
                      },
                      // Long-press: row popover (Edit / Print / Delete)
                      onItemLongPress: _onItemLongPress,
                      // Tap khusus untuk row partial (isPartialBool == true)
                      onPartialTap: _onPartialTap,
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

  Future<void> _handleDelete(GilinganHeader header) async {
    final vm = context.read<GilinganViewModel>();
    final no = header.noGilingan;

    try {
      DialogService.instance.showLoading(message: 'Deleting $no...');
      await vm.deleteGilingan(no);
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
