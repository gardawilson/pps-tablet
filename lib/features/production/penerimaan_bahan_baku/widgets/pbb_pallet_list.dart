// lib/features/production/penerimaan_bahan_baku/widgets/pbb_pallet_list.dart
//
// Varian tablet-friendly dari `BahanBakuPalletTable` — kartu besar,
// fungsional identik (tap untuk lihat detail sak, tap-kosong/long-press
// untuk popover Print & Input QC via `BahanBakuPalletPopover` yang di-reuse
// apa adanya).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/interactive_popover.dart';
import '../../../../core/view_model/label_print_lock_socket_manager.dart';
import '../../../label/bahan_baku/model/bahan_baku_pallet.dart';
import '../../../label/bahan_baku/view_model/bahan_baku_view_model.dart';
import '../../../label/bahan_baku/widgets/bahan_baku_pallet_popover.dart';

class PbbPalletList extends StatefulWidget {
  final ScrollController scrollController;
  final ValueChanged<BahanBakuPallet> onPalletTap;
  final ValueChanged<BahanBakuPallet> onInputQcTap;

  const PbbPalletList({
    super.key,
    required this.scrollController,
    required this.onPalletTap,
    required this.onInputQcTap,
  });

  @override
  State<PbbPalletList> createState() => _PbbPalletListState();
}

class _PbbPalletListState extends State<PbbPalletList> {
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
    if (_popover.isShown && widget.scrollController.position.isScrollingNotifier.value) {
      _popover.hide();
    }
  }

  void _showPalletPopover(BahanBakuPallet pallet, Offset globalPosition) {
    final screenHeight = MediaQuery.of(context).size.height;
    final adaptiveMaxHeight = (screenHeight - 32).clamp(480.0, 820.0).toDouble();

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
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BahanBakuViewModel>(
      builder: (context, vm, _) {
        final pallets = vm.pallets;

        final palletActual = pallets.length;
        final palletSisa = pallets.where((p) => p.isEmpty == false).length;
        final sakActual = pallets.fold<int>(0, (sum, p) => sum + p.sakActual);
        final sakSisa = pallets.fold<int>(0, (sum, p) => sum + p.sakSisa);
        final beratActual = pallets.fold<double>(0.0, (sum, p) => sum + p.beratActual);
        final beratSisa = pallets.fold<double>(0.0, (sum, p) => sum + p.beratSisa);

        return Column(
          children: [
            _buildSummaryHeader(
              palletSisa: palletSisa,
              palletActual: palletActual,
              sakSisa: sakSisa,
              sakActual: sakActual,
              beratSisa: beratSisa,
              beratActual: beratActual,
            ),
            if (vm.isPalletLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (vm.pallets.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Pilih bahan baku untuk melihat pallet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: vm.pallets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final pallet = vm.pallets[index];
                    final isSelected = vm.selectedNoPallet == pallet.noPallet;
                    return _PalletCard(
                      pallet: pallet,
                      isSelected: isSelected,
                      onTap: () {
                        if (pallet.isEmpty) return;
                        widget.onPalletTap(pallet);
                      },
                      onTapWithPosition: (pos) {
                        if (!pallet.isEmpty) return;
                        _showPalletPopover(pallet, pos);
                      },
                      onLongPress: (pos) => _showPalletPopover(pallet, pos),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryHeader({
    required int palletSisa,
    required int palletActual,
    required int sakSisa,
    required int sakActual,
    required double beratSisa,
    required double beratActual,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PALLET',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _SummaryStat(
                icon: Icons.view_module_outlined,
                label: 'Pallet',
                value: '${_fmtInt(palletSisa)} / ${_fmtInt(palletActual)}',
              ),
              _SummaryStat(
                icon: Icons.inventory_2_outlined,
                label: 'Sak',
                value: '${_fmtInt(sakSisa)} / ${_fmtInt(sakActual)}',
              ),
              _SummaryStat(
                icon: Icons.scale_outlined,
                label: 'Berat (kg)',
                value: '${_fmtKg(beratSisa)} / ${_fmtKg(beratActual)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)),
        ),
      ],
    );
  }
}

class _PalletCard extends StatelessWidget {
  final BahanBakuPallet pallet;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<Offset> onTapWithPosition;
  final ValueChanged<Offset> onLongPress;

  const _PalletCard({
    required this.pallet,
    required this.isSelected,
    required this.onTap,
    required this.onTapWithPosition,
    required this.onLongPress,
  });

  String _formatBlokLokasi(String? blok, int? idLokasi) {
    final hasBlok = blok != null && blok.trim().isNotEmpty;
    final hasLokasi = idLokasi != null && idLokasi > 0;
    if (!hasBlok && !hasLokasi) return '-';
    return '${blok ?? ''}${idLokasi ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = pallet.isEmpty;
    Offset? tapDownPosition;

    return Selector<LabelPrintLockSocketManager, _PrintCellState>(
      selector: (_, locks) => _PrintCellState(
        lock: locks.lockOf(pallet.noPallet),
        count: locks.printCountOf(pallet.noPallet),
      ),
      builder: (context, printState, __) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapDownPosition = details.globalPosition,
          onLongPressStart: (details) => onLongPress(details.globalPosition),
          onSecondaryTapDown: (details) => onLongPress(details.globalPosition),
          child: Material(
            color: isSelected ? const Color(0xFFE9F2FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                onTap();
                if (isDisabled) onTapWithPosition(tapDownPosition ?? Offset.zero);
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0C66E4) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey.shade100
                            : const Color(0xFF0C66E4).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pallet.noPallet,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDisabled ? Colors.grey.shade500 : const Color(0xFF0C66E4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pallet.namaJenisPlastik,
                            // Biarkan membungkus 2 baris & kartu ikut
                            // meninggi — dipotong ellipsis hanya kalau
                            // sungguh sangat panjang, bukan di baris 1.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDisabled ? Colors.grey.shade500 : const Color(0xFF172B4D),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade500),
                              Text(
                                _formatBlokLokasi(pallet.blok, pallet.idLokasi),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (isDisabled) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.block, size: 13, color: Colors.grey.shade500),
                                Text(
                                  'Kosong',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPrintBadge(printState, pallet),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintBadge(_PrintCellState state, BahanBakuPallet pallet) {
    final lock = state.lock;
    if (lock != null) {
      return Tooltip(
        message: 'Sedang diprint oleh ${lock.displayUser}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFB26A00).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFB26A00).withValues(alpha: 0.30)),
          ),
          child: const Text(
            'Printing',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB26A00)),
          ),
        ),
      );
    }

    final count = state.count ?? pallet.hasBeenPrinted;
    if (count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text('-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C66E4).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0C66E4).withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.print_rounded, size: 13, color: Color(0xFF0C66E4)),
          const SizedBox(width: 4),
          Text(
            '${count}x',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0C66E4)),
          ),
        ],
      ),
    );
  }
}

class _PrintCellState {
  final LabelPrintLockInfo? lock;
  final int? count;

  const _PrintCellState({required this.lock, required this.count});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PrintCellState && other.lock == lock && other.count == count;
  }

  @override
  int get hashCode => Object.hash(lock, count);
}
