import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/dialog_service.dart';
import '../view_model/washing_view_model.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';

import '../widgets/interactive_popover.dart';
import '../widgets/washing_row_popover.dart';
import '../widgets/washing_action_bar.dart';
import '../widgets/washing_header_table.dart';
import '../widgets/washing_detail_table.dart';
import '../widgets/washing_form_dialog.dart';
import '../widgets/washing_delete_dialog.dart';

// NEW: dialog history
import '../widgets/washing_history_dialog.dart';

class WashingTableScreen extends StatefulWidget {
  const WashingTableScreen({super.key});

  @override
  State<WashingTableScreen> createState() => _WashingTableScreenState();
}

class _WashingTableScreenState extends State<WashingTableScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _debounce;

  // Popover animasi (custom)
  final InteractivePopover _popover = InteractivePopover();

  bool _isUsed(String? dateUsage) {
    final s = (dateUsage ?? '').trim();
    if (s.isEmpty) return false;
    if (s.toLowerCase() == 'null') return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<WashingViewModel>();
      vm.resetForScreen();
      vm.fetchWashingHeaders();
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

  void _closeContextMenu() => _popover.hide();

  void _onScroll() {
    if (_popover.isShown) _popover.hide();

    final vm = context.read<WashingViewModel>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && vm.hasMore) {
        _isLoadingMore = true;
        vm.loadMore().then((_) {
          if (!mounted) return;
          setState(() => _isLoadingMore = false);
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WashingViewModel>().fetchWashingHeaders(search: query);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _showFormDialog({WashingHeader? header, List<WashingDetail>? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => WashingFormDialog(
        header: header,
        details: details,
        onSave: (headerData, detailsData) {
          final vm = context.read<WashingViewModel>();
          if (header != null) {
            // vm.updateWashing(headerData, detailsData);
          } else {
            // vm.createWashing(headerData, detailsData);
          }
        },
      ),
    );
  }

  Future<void> _onEditHeader(WashingHeader header) async {
    final vm = context.read<WashingViewModel>();

    vm.setSelectedNoWashing(header.noWashing);

    DialogService.instance
        .showLoading(message: 'Cek detail ${header.noWashing}...');
    await vm.fetchDetails(header.noWashing);
    DialogService.instance.hideLoading();

    if (!mounted) return;

    final hasUsed = vm.details.any((d) => _isUsed(d.dateUsage));
    if (hasUsed) {
      await DialogService.instance.showError(
        title: 'Edit tidak tersedia',
        message: 'Tidak bisa edit karena ada Sak yang sudah dipakai',
      );
      return;
    }

    _showFormDialog(header: header, details: vm.details);
  }

  Future<void> _onDeleteHeader(WashingHeader header) async {
    final vm = context.read<WashingViewModel>();

    vm.setSelectedNoWashing(header.noWashing);

    DialogService.instance
        .showLoading(message: 'Cek detail ${header.noWashing}...');
    await vm.fetchDetails(header.noWashing);
    DialogService.instance.hideLoading();

    if (!mounted) return;

    final hasUsed = vm.details.any((d) => _isUsed(d.dateUsage));
    if (hasUsed) {
      await DialogService.instance.showError(
        title: 'Hapus tidak tersedia',
        message: 'Tidak bisa hapus karena ada Sak yang sudah dipakai',
      );
      return;
    }

    _confirmDelete(header);
  }

  void _confirmDelete(WashingHeader header) {
    showDialog(
      context: context,
      builder: (_) => WashingDeleteDialog(
        header: header,
        onConfirm: () async {
          Navigator.of(context).pop();
          await _handleDelete(header);
        },
      ),
    );
  }

  Future<void> _handleDelete(WashingHeader header) async {
    final vm = context.read<WashingViewModel>();
    final noWashing = header.noWashing;

    DialogService.instance.showLoading(message: 'Menghapus $noWashing...');
    final ok = await vm.deleteWashing(noWashing);
    DialogService.instance.hideLoading();

    if (!mounted) return;

    if (ok) {
      await DialogService.instance.showSuccess(
        title: 'Terhapus',
        message: 'Label $noWashing berhasil dihapus.',
      );
      vm.setSelectedNoWashing(null);
    } else {
      await DialogService.instance.showError(
        title: 'Gagal',
        message: vm.errorMessage ?? 'Tidak dapat menghapus label.',
      );
    }
  }

  /// Long-press handler: pindahkan highlight ke item & tampilkan popover.
  Future<void> _onItemLongPress(
      WashingHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<WashingViewModel>();
    vm.setSelectedNoWashing(header.noWashing);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: WashingRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () async {
          _closeContextMenu();
          await _onEditHeader(header);
        },
        onDelete: () async {
          if (context.read<WashingViewModel>().isLoading) return;
          _closeContextMenu();
          await _onDeleteHeader(header);
        },
        onPrint: () {
          _closeContextMenu();
          // TODO: print/preview
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        title: Consumer<WashingViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL WASHING (…)'
                : 'LABEL WASHING (${vm.totalCount})';
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
                  WashingActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context.read<WashingViewModel>().fetchWashingHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: WashingHeaderTable(
                      scrollController: _scrollController,
                      onItemTap: (header) {
                        final vm = context.read<WashingViewModel>();
                        vm.setSelectedNoWashing(header.noWashing);
                        vm.fetchDetails(header.noWashing);
                      },
                      onItemLongPress: _onItemLongPress,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(width: 2, color: Colors.grey.shade300),

          // Detail Panel
          Expanded(
            flex: 1,
            child: WashingDetailTable(
              scrollController: _detailScrollController,
            ),
          ),
        ],
      ),
    );
  }
}
