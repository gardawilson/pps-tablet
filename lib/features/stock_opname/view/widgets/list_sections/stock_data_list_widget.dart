import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_label_before_view_model.dart';
import '../cards/compact_label_card_widget.dart';
import '../common/error_state_widget.dart';
import '../common/empty_state_widget.dart';
import '../dialogs/bubble_tooltip.dart';
import '../../../../../../common/widgets/loading_skeleton.dart';

class StockDataListWidget extends StatefulWidget {
  final String noSO;
  final String? selectedFilter;
  final String? selectedBlok;
  final int? selectedIdLokasi;

  const StockDataListWidget({
    Key? key,
    required this.noSO,
    this.selectedFilter,
    this.selectedBlok,
    this.selectedIdLokasi,
  }) : super(key: key);

  @override
  State<StockDataListWidget> createState() => _StockDataListWidgetState();
}

class _StockDataListWidgetState extends State<StockDataListWidget> {
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
      // Tutup tooltip saat scroll
      if (_tooltipOverlay != null) _closeTooltip();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        final beforeVM =
        Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
        if (!isLoadingMore && beforeVM.hasMoreData) {
          isLoadingMore = true;
          beforeVM.loadMoreData().then((_) {
            if (mounted) isLoadingMore = false;
          });
        }
      }
    });
  }

  void _showTooltip(
      BuildContext context, TapDownDetails details, String nomorLabel) {
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

    const double tooltipWidth = 260;
    const double arrowWidth = 12;
    const double arrowHeight = 20;
    const double padding = 8;
    const double tooltipCardGap = 8;

    final tooltipHeight = _calculateTooltipHeight(nomorLabel);
    final cardCenterY = cardPosition.dy + (cardSize.height / 2);
    final cardCenterX = cardPosition.dx + (cardSize.width / 2);

    double tooltipLeft =
        cardPosition.dx - tooltipWidth - tooltipCardGap - arrowWidth;
    double arrowLeft = tooltipLeft + tooltipWidth;
    bool showTooltipOnLeft = true;

    if (tooltipLeft < padding) {
      tooltipLeft = cardPosition.dx + cardSize.width + tooltipCardGap + arrowWidth;
      arrowLeft = tooltipLeft - arrowWidth;
      showTooltipOnLeft = false;

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
    if (tooltipTop < padding) tooltipTop = padding;
    if (tooltipTop + tooltipHeight > screenSize.height - padding) {
      tooltipTop = screenSize.height - tooltipHeight - padding;
    }

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

    final totalHeight = baseHeight + (itemCount * itemHeight) + padding;
    return totalHeight.clamp(120.0, 400.0);
  }

  void _showVerticalTooltip(BuildContext context, Offset cardPosition, Size cardSize,
      Size screenSize, String nomorLabel, double tooltipHeight) {
    final overlay = Overlay.of(context);
    const double tooltipWidth = 260;
    const double tooltipCardGap = 8;
    const double padding = 8;

    double cardCenterX = cardPosition.dx + (cardSize.width / 2);

    double tooltipLeft = cardCenterX - (tooltipWidth / 2);
    tooltipLeft = tooltipLeft.clamp(padding, screenSize.width - tooltipWidth - padding);

    bool showAbove =
        cardPosition.dy + cardSize.height + tooltipHeight + tooltipCardGap >
            screenSize.height - padding;

    double tooltipTop = showAbove
        ? (cardPosition.dy - tooltipHeight - tooltipCardGap).clamp(
        padding, screenSize.height - tooltipHeight - padding)
        : (cardPosition.dy + cardSize.height + tooltipCardGap).clamp(
        padding, screenSize.height - tooltipHeight - padding);

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
      child: Consumer<StockOpnameLabelBeforeViewModel>(
        builder: (context, beforeVM, child) {
          if (beforeVM.isInitialLoading && beforeVM.items.isEmpty) {
            return const LoadingSkeleton();
          }

          if (beforeVM.errorMessage.isNotEmpty) {
            return ErrorStateWidget(message: beforeVM.errorMessage);
          }

          if (beforeVM.items.isEmpty) {
            return const EmptyStateWidget(message: 'Data Stock Tidak Ditemukan');
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: beforeVM.items.length + (beforeVM.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == beforeVM.items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final label = beforeVM.items[index];
              final isActive = _activeCardLabel == label.nomorLabel;

              return Builder(
                builder: (itemContext) => GestureDetector(
                  onTapDown: (details) =>
                      _showTooltip(itemContext, details, label.nomorLabel),
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
                      blok: label.blok,
                      idLokasi: label.idLokasi,
                      isReference: true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
