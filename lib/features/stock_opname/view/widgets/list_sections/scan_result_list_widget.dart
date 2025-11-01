import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_detail_view_model.dart';
import '../../../view_model/stock_opname_label_before_view_model.dart';
import '../cards/compact_label_card_widget.dart';
import '../common/error_state_widget.dart';
import '../common/empty_state_widget.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/bubble_tooltip.dart';
import '../../../../../../common/widgets/loading_skeleton.dart';

class ScanResultListWidget extends StatefulWidget {
  final String noSO;
  final String? selectedFilter;
  final String? selectedBlok;
  final int? selectedIdLokasi;
  final VoidCallback onDeleteSuccess;

  const ScanResultListWidget({
    Key? key,
    required this.noSO,
    this.selectedFilter,
    this.selectedBlok,
    this.selectedIdLokasi,
    required this.onDeleteSuccess,
  }) : super(key: key);

  @override
  State<ScanResultListWidget> createState() => _ScanResultListWidgetState();
}

class _ScanResultListWidgetState extends State<ScanResultListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;
  OverlayEntry? _tooltipOverlay;
  String? _activeCardLabel;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _closeTooltip();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    if (_activeCardLabel != null) {
      setState(() {
        _activeCardLabel = null;
      });
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_tooltipOverlay != null) _closeTooltip();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        final viewModel =
        Provider.of<StockOpnameDetailViewModel>(context, listen: false);
        if (!isLoadingMore && viewModel.hasMoreData) {
          isLoadingMore = true;
          viewModel.loadMoreData().then((_) {
            if (mounted) isLoadingMore = false;
          });
        }
      }
    });
  }

  void _showTooltip(BuildContext context, TapDownDetails details, String nomorLabel) {
    if (_activeCardLabel == nomorLabel) {
      _closeTooltip();
      return;
    }
    _closeTooltip();
    setState(() => _activeCardLabel = nomorLabel);

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final cardPosition = renderBox.localToGlobal(Offset.zero);
    final cardSize = renderBox.size;

    const tooltipWidth = 260.0;
    const arrowWidth = 12.0;
    const arrowHeight = 20.0;
    const padding = 8.0;
    const tooltipCardGap = 8.0;

    final tooltipHeight = _calculateTooltipHeight(nomorLabel);
    final cardCenterY = cardPosition.dy + (cardSize.height / 2);

    double tooltipLeft =
        cardPosition.dx - tooltipWidth - tooltipCardGap - arrowWidth;
    double arrowLeft = tooltipLeft + tooltipWidth;

    if (tooltipLeft < padding) {
      tooltipLeft =
          cardPosition.dx + cardSize.width + tooltipCardGap + arrowWidth;
      arrowLeft = tooltipLeft - arrowWidth;

      if (tooltipLeft + tooltipWidth > screenSize.width - padding) {
        _showVerticalTooltip(
          context,
          cardPosition,
          cardSize,
          screenSize,
          nomorLabel,
          tooltipHeight,
        );
        return;
      }
    }

    double tooltipTop = cardCenterY - (tooltipHeight / 2);
    tooltipTop = tooltipTop.clamp(
      padding,
      screenSize.height - tooltipHeight - padding,
    );

    double arrowTop = cardCenterY - (arrowHeight / 2);
    arrowTop = arrowTop.clamp(
      tooltipTop + 15,
      tooltipTop + tooltipHeight - arrowHeight - 15,
    );

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeTooltip,
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: BubbleTooltip(
              message: nomorLabel,
              maxWidth: tooltipWidth,
              maxHeight: tooltipHeight,
              isHorizontalLayout: true,
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tooltipOverlay!);
  }

  double _calculateTooltipHeight(String nomorLabel) {
    const baseHeight = 80.0;
    const itemHeight = 50.0;
    const padding = 32.0;

    final kodeAwal = nomorLabel.split('.').first.toUpperCase();
    int itemCount = switch (kodeAwal) {
      'A' || 'B' || 'D' || 'BB' || 'BA' => 6,
      'F' || 'M' || 'V' || 'H' || 'BF' => 5,
      _ => 1,
    };

    return (baseHeight + (itemCount * itemHeight) + padding)
        .clamp(120.0, 400.0);
  }

  void _showVerticalTooltip(BuildContext context, Offset cardPosition, Size cardSize,
      Size screenSize, String nomorLabel, double tooltipHeight) {
    final overlay = Overlay.of(context);
    const tooltipWidth = 260.0;
    const tooltipCardGap = 8.0;
    const padding = 8.0;

    double cardCenterX = cardPosition.dx + (cardSize.width / 2);

    double tooltipLeft = cardCenterX - (tooltipWidth / 2);
    tooltipLeft = tooltipLeft.clamp(
      padding,
      screenSize.width - tooltipWidth - padding,
    );

    bool showAbove =
        cardPosition.dy + cardSize.height + tooltipHeight + tooltipCardGap >
            screenSize.height - padding;

    double tooltipTop = showAbove
        ? (cardPosition.dy - tooltipHeight - tooltipCardGap)
        .clamp(padding, screenSize.height - tooltipHeight - padding)
        : (cardPosition.dy + cardSize.height + tooltipCardGap)
        .clamp(padding, screenSize.height - tooltipHeight - padding);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeTooltip,
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.transparent,
            ),
          ),
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: BubbleTooltip(
              message: nomorLabel,
              maxWidth: tooltipWidth,
              maxHeight: tooltipHeight,
              isHorizontalLayout: false,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_tooltipOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_tooltipOverlay != null) {
          _closeTooltip();
          return false;
        }
        return true;
      },
      child: Consumer<StockOpnameDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isInitialLoading && viewModel.labels.isEmpty) {
            return const LoadingSkeleton();
          }

          if (viewModel.errorMessage.isNotEmpty) {
            return ErrorStateWidget(message: viewModel.errorMessage);
          }

          if (viewModel.labels.isEmpty) {
            return const EmptyStateWidget(
                message: 'Data Hasil Scan Tidak Ditemukan');
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: viewModel.labels.length + (viewModel.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == viewModel.labels.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final label = viewModel.labels[index];
              final isActive = _activeCardLabel == label.nomorLabel;

              return Builder(
                builder: (itemContext) => GestureDetector(
                  onTapDown: (details) =>
                      _showTooltip(itemContext, details, label.nomorLabel),
                  onLongPress: () => _showDeleteBottomSheet(label.nomorLabel),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                          : null,
                      border: isActive
                          ? Border.all(
                        color: const Color(0xFF2196F3),
                        width: 2,
                      )
                          : null,
                    ),
                    child: CompactLabelCardWidget(
                      nomorLabel: label.nomorLabel,
                      labelType: label.labelType,
                      jmlhSak: label.jmlhSak,
                      berat: label.berat,
                      blok: label.blok,            // <— baru
                      idLokasi: label.idLokasi,    // <— baru (int?)
                      username: label.username,
                      isReference: false,
                    )
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteBottomSheet(String nomorLabel) {
    _closeTooltip();

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Data'),
              onTap: () async {
                Navigator.pop(context);
                await _showDeleteConfirmation(nomorLabel);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(String nomorLabel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(nomorLabel: nomorLabel),
    );

    if (confirm == true && mounted) {
      await _deleteLabel(nomorLabel);
    }
  }

  Future<void> _deleteLabel(String nomorLabel) async {
    final viewModel =
    Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final success = await viewModel.deleteLabel(nomorLabel);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Label $nomorLabel berhasil dihapus'
                : 'Gagal menghapus label $nomorLabel',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        final beforeVM =
        Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
        await beforeVM.fetchInitialData(
          beforeVM.noSO,
          filterBy: beforeVM.currentFilter ?? 'all',
          blok: beforeVM.currentBlok,
          idLokasi: beforeVM.currentIdLokasi,
        );
        widget.onDeleteSuccess();
      }
    }
  }
}
