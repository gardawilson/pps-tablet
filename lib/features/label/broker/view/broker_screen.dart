import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/dialog_service.dart';
import '../view_model/broker_view_model.dart';
import '../model/broker_header_model.dart';
import '../model/broker_detail_model.dart';
import '../widgets/interactive_popover.dart';
import '../widgets/broker_row_popover.dart';
import '../widgets/broker_action_bar.dart';
import '../widgets/broker_header_table.dart';
import '../widgets/broker_detail_table.dart';
import '../widgets/broker_form_dialog.dart';
import '../widgets/broker_delete_dialog.dart';

class BrokerScreen extends StatefulWidget {
  const BrokerScreen({super.key});

  @override
  State<BrokerScreen> createState() => _BrokerScreenState();
}

class _BrokerScreenState extends State<BrokerScreen> {
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
      context.read<BrokerViewModel>().fetchBrokerHeaders();
      context.read<BrokerViewModel>().resetForScreen();
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

    final vm = context.read<BrokerViewModel>();
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
      context.read<BrokerViewModel>().fetchBrokerHeaders(search: query);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _showFormDialog({BrokerHeader? header, List<BrokerDetail>? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => BrokerFormDialog(
        header: header,
        details: details,
        onSave: (headerData, detailsData) {
          final vm = context.read<BrokerViewModel>();
          if (header != null) {
            // vm.updateWashing(headerData, detailsData);
          } else {
            // vm.createWashing(headerData, detailsData);
          }
        },
      ),
    );
  }

  void _confirmDelete(BrokerHeader header) {
    showDialog(
      context: context,
      builder: (_) => BrokerDeleteDialog(
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
      BrokerHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<BrokerViewModel>();

    // Pindahkan highlight saat long-press
    vm.setSelectedNoBroker(header.noBroker);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: BrokerRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () {
          _closeContextMenu();
          _showFormDialog(header: header, details: vm.details);
        },
        onDelete: () {
          if (context.read<BrokerViewModel>().isLoading) return;
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        title: Consumer<BrokerViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL BROKER (…)'
                : 'LABEL BROKER (${vm.totalCount})';
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
                  BrokerActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<BrokerViewModel>()
                          .fetchBrokerHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: BrokerHeaderTable(
                      scrollController: _scrollController,
                      onItemTap: (header) {
                        final vm = context.read<BrokerViewModel>();
                        // Klik: pindahkan highlight & (opsional) load detail
                        vm.setSelectedNoBroker(header.noBroker);
                        vm.fetchDetails(header.noBroker);
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

          // Divider
          Container(width: 2, color: Colors.grey.shade300),

          // Detail Panel
          Expanded(
            flex: 1,
            child: BrokerDetailTable(
              scrollController: _detailScrollController,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BrokerHeader header) async {
    final vm = context.read<BrokerViewModel>();
    final noBroker = header.noBroker;

    DialogService.instance.showLoading(message: 'Menghapus $noBroker...');
    final ok = await vm.deleteWashing(noBroker);
    DialogService.instance.hideLoading();

    if (ok) {
      await DialogService.instance.showSuccess(
        title: 'Terhapus',
        message: 'Label $noBroker berhasil dihapus.',
      );

      // Selalu bersihkan panel detail & selection
      vm.setSelectedNoBroker(null);

      // (Opsional) scroll panel detail ke atas
      // _detailScrollController.jumpTo(0);

    } else {
      await DialogService.instance.showError(
        title: 'Gagal',
        message: vm.errorMessage ?? 'Tidak dapat menghapus label.',
      );
    }
  }


}
