import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../common/widgets/info_line.dart';
import '../../../../common/widgets/interactive_popover.dart';
import '../model/bahan_baku_pallet.dart';
import '../view_model/bahan_baku_view_model.dart';
import 'bahan_baku_pallet_popover.dart';

class BahanBakuPalletTable extends StatefulWidget {
  static const _colPalletWidth = 70.0;
  static const _colLokasiWidth = 60.0;
  static const _colPrintWidth = 72.0;

  final ScrollController scrollController;
  final ValueChanged<BahanBakuPallet> onPalletTap;
  final ValueChanged<BahanBakuPallet> onInputQcTap;

  const BahanBakuPalletTable({
    super.key,
    required this.scrollController,
    required this.onPalletTap,
    required this.onInputQcTap,
  });

  @override
  State<BahanBakuPalletTable> createState() => _BahanBakuPalletTableState();
}

class _BahanBakuPalletTableState extends State<BahanBakuPalletTable> {
  final InteractivePopover _popover = InteractivePopover();

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_hidePopoverOnScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_hidePopoverOnScroll);
    _popover.dispose();
    super.dispose();
  }

  void _hidePopoverOnScroll() {
    if (_popover.isShown &&
        widget.scrollController.position.isScrollingNotifier.value) {
      _popover.hide();
    }
  }

  void _showPalletPopover(BahanBakuPallet pallet, Offset globalPosition) {
    if (pallet.isEmpty) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final adaptiveMaxHeight = (screenHeight - 32)
        .clamp(480.0, 820.0)
        .toDouble();

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: BahanBakuPalletPopover(
        pallet: pallet,
        onClose: () => _popover.hide(),
        onInputQc: () => widget.onInputQcTap(pallet),
        onAfterPrint: () {
          context.read<BahanBakuViewModel>().markAsPalletPrinted(
            noBahanBaku: pallet.noBahanBaku,
            noPallet: pallet.noPallet,
          );
        },
      ),
      preferAbove: true,
      verticalGap: 8,
      maxHeight: adaptiveMaxHeight,
      backdropOpacity: 0.06,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      startScale: 0.94,
    );
  }

  String _fmtInt(int v) => v.toString();

  String _fmtKg(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('.00')) return s.substring(0, s.length - 3);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Consumer<BahanBakuViewModel>(
        builder: (context, vm, _) {
          final pallets = vm.pallets;

          final int palletActual = pallets.length;
          final int palletSisa = pallets
              .where((p) => p.isEmpty == false)
              .length;

          final int sakActual = pallets.fold<int>(
            0,
            (sum, p) => sum + p.sakActual,
          );
          final int sakSisa = pallets.fold<int>(0, (sum, p) => sum + p.sakSisa);

          final double beratActual = pallets.fold<double>(
            0.0,
            (sum, p) => sum + p.beratActual,
          );
          final double beratSisa = pallets.fold<double>(
            0.0,
            (sum, p) => sum + p.beratSisa,
          );

          return Column(
            children: [
              _buildHeader(
                palletSisa: palletSisa,
                palletActual: palletActual,
                sakSisa: sakSisa,
                sakActual: sakActual,
                beratSisa: beratSisa,
                beratActual: beratActual,
              ),
              if (vm.isPalletLoading) _buildLoadingState(),
              if (!vm.isPalletLoading && vm.pallets.isEmpty) _buildEmptyState(),
              if (!vm.isPalletLoading && vm.pallets.isNotEmpty)
                Expanded(
                  child: AtlasDataTable<BahanBakuPallet>(
                    columns: _buildColumns(),
                    items: vm.pallets,
                    scrollController: widget.scrollController,
                    selectedPredicate: (p) => vm.selectedNoPallet == p.noPallet,
                    highlightPredicate: _isQCCompleted,
                    onRowTap: (pallet) {
                      if (pallet.isEmpty) return;
                      widget.onPalletTap(pallet);
                    },
                    onRowLongPress: (pallet, pos) {
                      if (pallet.isEmpty) return;
                      _showPalletPopover(pallet, pos);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<AtlasTableColumn<BahanBakuPallet>> _buildColumns() {
    return [
      AtlasTableColumn<BahanBakuPallet>(
        title: 'PALLET',
        width: BahanBakuPalletTable._colPalletWidth,
        cellBuilder: (context, pallet, rowState) {
          final isDisabled = pallet.isEmpty;
          final textColorMain = isDisabled
              ? Colors.grey.shade500
              : (rowState.isSelected
                    ? const Color(0xFF0C66E4)
                    : Colors.black87);

          return Row(
            children: [
              Expanded(
                child: Text(
                  pallet.noPallet,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: rowState.isSelected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: textColorMain,
                  ),
                  softWrap: true,
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(width: 6),
                Icon(Icons.block, size: 14, color: Colors.grey.shade600),
              ],
            ],
          );
        },
      ),
      AtlasTableColumn<BahanBakuPallet>(
        title: 'JENIS',
        flex: 2,
        horizontalPadding: 14,
        cellBuilder: (context, pallet, rowState) {
          final isDisabled = pallet.isEmpty;
          return Text(
            pallet.namaJenisPlastik,
            style: TextStyle(
              fontSize: 13,
              color: isDisabled ? Colors.grey.shade500 : rowState.textColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BahanBakuPallet>(
        title: 'LOK',
        width: BahanBakuPalletTable._colLokasiWidth,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        cellBuilder: (context, pallet, rowState) {
          final isDisabled = pallet.isEmpty;
          return Text(
            _formatBlokLokasi(pallet.blok, pallet.idLokasi),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDisabled ? Colors.grey.shade500 : rowState.textColor,
            ),
            softWrap: true,
          );
        },
      ),
      AtlasTableColumn<BahanBakuPallet>(
        title: 'PRINT',
        width: BahanBakuPalletTable._colPrintWidth,
        showDivider: false,
        cellBuilder: (context, pallet, rowState) {
          final count = pallet.hasBeenPrinted;
          if (count == 0) {
            return Text(
              '—',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0C66E4).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF0C66E4).withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.print_rounded,
                  size: 12,
                  color: Color(0xFF0C66E4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${count}x',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C66E4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  Widget _buildHeader({
    required int palletSisa,
    required int palletActual,
    required int sakSisa,
    required int sakActual,
    required double beratSisa,
    required double beratActual,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PALLET',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                InfoLine(
                  label: 'Jumlah Pallet',
                  value: '${_fmtInt(palletSisa)} / ${_fmtInt(palletActual)}',
                  icon: Icons.view_module_outlined,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                InfoLine(
                  label: 'Jumlah Sak',
                  value: '${_fmtInt(sakSisa)} / ${_fmtInt(sakActual)}',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                InfoLine(
                  label: 'Total Berat (kg)',
                  value: '${_fmtKg(beratSisa)} / ${_fmtKg(beratActual)}',
                  icon: Icons.scale_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Expanded(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_module, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Pilih bahan baku untuk melihat pallet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBlokLokasi(String? blok, int? idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi > 0;

    if (!hasBlok && !hasLokasi) return '-';
    return '${blok ?? ''}${idLokasi ?? ''}';
  }

  bool _isQCCompleted(BahanBakuPallet pallet) {
    return (pallet.tenggelam != null) ||
        (pallet.density != null) ||
        (pallet.density2 != null) ||
        (pallet.density3 != null);
  }
}
