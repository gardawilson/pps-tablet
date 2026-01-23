// lib/features/production/bahan_baku/widgets/bahan_baku_pallet_table.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/info_line.dart';
import '../../bonggolan/widgets/interactive_popover.dart';
import '../model/bahan_baku_pallet.dart';
import '../view_model/bahan_baku_view_model.dart';
import 'bahan_baku_pallet_popover.dart';

class BahanBakuPalletTable extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<BahanBakuPallet> onPalletTap;

  const BahanBakuPalletTable({
    super.key,
    required this.scrollController,
    required this.onPalletTap,
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
    // ✅ disable popover kalau pallet empty
    if (pallet.isEmpty) return;

    _popover.show(
      context: context,
      globalPosition: globalPosition,
      child: BahanBakuPalletPopover(
        pallet: pallet,
        onClose: () => _popover.hide(),
        onViewDetails: () => widget.onPalletTap(pallet),

        // ✅ biarkan popover pakai default print (PdfPrintService + reportName LabelPalletBB)
        // onPrint: null,  // boleh ditulis atau cukup dihapus param-nya

        apiBaseUrl: 'http://192.168.10.100:3000',
        // username: 'ADMIN', // opsional kalau kamu mau hardcode / inject
      ),


      preferAbove: true,
      verticalGap: 8,
      backdropOpacity: 0.06,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      startScale: 0.94,
    );
  }

  String _fmtInt(int v) => v.toString();

  String _fmtKg(double v) {
    // format sederhana tanpa intl (biar ringan)
    // kalau kamu pakai intl, bisa ganti ke NumberFormat('#,##0.##')
    final s = v.toStringAsFixed(2);
    // buang trailing .00
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
          final int palletSisa = pallets.where((p) => p.isEmpty == false).length;

          final int sakActual =
          pallets.fold<int>(0, (sum, p) => sum + (p.sakActual));
          final int sakSisa =
          pallets.fold<int>(0, (sum, p) => sum + (p.sakSisa));

          final double beratActual =
          pallets.fold<double>(0.0, (sum, p) => sum + (p.beratActual));
          final double beratSisa =
          pallets.fold<double>(0.0, (sum, p) => sum + (p.beratSisa));

          // masih boleh dipakai kalau kamu tetap ingin statistik status
          // final passPallets = pallets.where((p) => p.idStatus == 1).length;
          // final holdPallets = pallets.where((p) => p.idStatus == 0).length;

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
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      Expanded(child: _buildTableBody(vm)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
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
    return const Expanded(
      child: Center(child: CircularProgressIndicator()),
    );
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'PALLET',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'JENIS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'LOK',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(BahanBakuViewModel vm) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: vm.pallets.length,
      itemBuilder: (context, index) {
        final pallet = vm.pallets[index];
        final isSelected = vm.selectedNoPallet == pallet.noPallet;
        final isEven = index % 2 == 0;

        final bool isDisabled = pallet.isEmpty;

        final bgColor = isSelected
            ? Colors.blue.shade50
            : (isEven ? Colors.white : Colors.grey.shade50);

        final textColorMain = isDisabled
            ? Colors.grey.shade500
            : (isSelected ? Colors.blue.shade900 : Colors.black87);
        final textColorSub =
        isDisabled ? Colors.grey.shade500 : Colors.grey.shade800;

        return Opacity(
          opacity: isDisabled ? 0.55 : 1.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: isDisabled
                ? null
                : (details) =>
                _showPalletPopover(pallet, details.globalPosition),
            onSecondaryTapDown: isDisabled
                ? null
                : (details) => _showPalletPopover(pallet, details.globalPosition),
            child: InkWell(
              onTap: isDisabled ? null : () => widget.onPalletTap(pallet),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 4,
                    ),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pallet.noPallet,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: textColorMain,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDisabled) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.block,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        pallet.namaJenisPlastik,
                        style: TextStyle(fontSize: 13, color: textColorSub),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatBlokLokasi(pallet.blok, pallet.idLokasi),
                        style: TextStyle(fontSize: 13, color: textColorSub),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatBlokLokasi(String? blok, int? idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi > 0;

    if (!hasBlok && !hasLokasi) return '-';
    return '${blok ?? ''}${idLokasi ?? ''}';
  }
}
