import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/dialog_service.dart';
import '../view_model/mixer_view_model.dart';
import '../model/mixer_header_model.dart';
import '../model/mixer_detail_model.dart';
import '../widgets/interactive_popover.dart';
import '../widgets/mixer_row_popover.dart';
import '../widgets/mixer_action_bar.dart';
import '../widgets/mixer_header_table.dart';
import '../widgets/mixer_detail_table.dart';
import '../widgets/mixer_form_dialog.dart';
import '../widgets/mixer_delete_dialog.dart';

class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
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

  Future<void> _onEditHeader(MixerHeader header) async {
    final vm = context.read<MixerViewModel>();

    // pastikan selection benar
    vm.setSelectedNoMixer(header.noMixer);

    // fetch detail terbaru untuk header ini
    DialogService.instance.showLoading(message: 'Cek detail ${header.noMixer}...');
    await vm.fetchDetails(header.noMixer);
    DialogService.instance.hideLoading();

    if (!mounted) return;

    // RULE: tidak boleh edit jika ada DateUsage terisi atau ada isPartial = true
    final hasUsed = vm.details.any((d) => _isUsed(d.dateUsage));
    final hasPartial = vm.details.any((d) => d.isPartial == true);

    if (hasUsed || hasPartial) {
      final reason = [
        if (hasUsed) 'ada Sak yang sudah dipakai',
        if (hasPartial) 'ada Sak yang telah dipartial',
      ].join(' dan ');

      await DialogService.instance.showError(
        title: 'Edit ditolak',
        message: 'Tidak bisa edit karena $reason.',
      );
      return;
    }

    // aman -> buka form edit
    _showFormDialog(header: header, details: vm.details);
  }

  Future<void> _onDeleteHeader(MixerHeader header) async {
    final vm = context.read<MixerViewModel>();

    // pastikan selection benar
    vm.setSelectedNoMixer(header.noMixer);

    // fetch detail terbaru untuk header ini (biar rule valid)
    DialogService.instance.showLoading(message: 'Cek detail ${header.noMixer}...');
    await vm.fetchDetails(header.noMixer);
    DialogService.instance.hideLoading();

    if (!mounted) return;

    final hasUsed = vm.details.any((d) => _isUsed(d.dateUsage));
    final hasPartial = vm.details.any((d) => d.isPartial == true);

    if (hasUsed || hasPartial) {
      final reason = [
        if (hasUsed) 'ada Sak yang sudah dipakai',
        if (hasPartial) 'ada Sak yang telah dipartial',
      ].join(' dan ');

      await DialogService.instance.showError(
        title: 'Delete ditolak',
        message: 'Tidak bisa delete karena $reason.',
      );
      return;
    }

    // aman -> lanjut confirm delete
    _confirmDelete(header);
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MixerViewModel>().fetchHeaders();
      context.read<MixerViewModel>().resetForScreen();
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

    final vm = context.read<MixerViewModel>();
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
      context.read<MixerViewModel>().fetchHeaders(search: query);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _showFormDialog({MixerHeader? header, List<MixerDetail>? details}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => MixerFormDialog(
        header: header,
        details: details,
        onSave: (headerData, detailsData) {
          final vm = context.read<MixerViewModel>();
          if (header != null) {
            // vm.updateWashing(headerData, detailsData);
          } else {
            // vm.createWashing(headerData, detailsData);
          }
        },
      ),
    );
  }

  void _confirmDelete(MixerHeader header) {
    showDialog(
      context: context,
      builder: (_) => MixerDeleteDialog(
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
      MixerHeader header,
      Offset globalPosition,
      ) async {
    final vm = context.read<MixerViewModel>();

    // Pindahkan highlight saat long-press
    vm.setSelectedNoMixer(header.noMixer);

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: MixerRowPopover(
        header: header,
        onClose: _closeContextMenu,
        onEdit: () async {
          _closeContextMenu();
          await _onEditHeader(header);
        },

        onDelete: () async {
          if (context.read<MixerViewModel>().isLoading) return;
          _closeContextMenu();
          await _onDeleteHeader(header);
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
        title: Consumer<MixerViewModel>(
          builder: (_, vm, __) {
            final label = vm.isLoading && vm.items.isEmpty
                ? 'LABEL MIXER (…)'
                : 'LABEL MIXER (${vm.totalCount})';
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
                  MixerActionBar(
                    controller: searchCtrl,
                    onSearchChanged: _onSearchChanged,
                    onClear: () {
                      searchCtrl.clear();
                      context
                          .read<MixerViewModel>()
                          .fetchHeaders(search: "");
                    },
                    onAddPressed: _showFormDialog,
                  ),
                  Expanded(
                    child: MixerHeaderTable(
                      scrollController: _scrollController,
                      onItemTap: (header) {
                        final vm = context.read<MixerViewModel>();
                        // Klik: pindahkan highlight & (opsional) load detail
                        vm.setSelectedNoMixer(header.noMixer);
                        vm.fetchDetails(header.noMixer);
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
            child: MixerDetailTable(
              scrollController: _detailScrollController,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(MixerHeader header) async {
    final vm = context.read<MixerViewModel>();
    final noBroker = header.noMixer;

    DialogService.instance.showLoading(message: 'Menghapus $noBroker...');
    final ok = await vm.deleteMixer(noBroker);
    DialogService.instance.hideLoading();

    if (ok) {
      await DialogService.instance.showSuccess(
        title: 'Terhapus',
        message: 'Label $noBroker berhasil dihapus.',
      );

      // Selalu bersihkan panel detail & selection
      vm.setSelectedNoMixer(null);

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
