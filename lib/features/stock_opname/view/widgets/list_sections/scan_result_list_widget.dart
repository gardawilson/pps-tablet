// features/stock_opname/detail/widgets/list_sections/scan_result_list_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_detail_view_model.dart';
import '../../../view_model/stock_opname_label_before_view_model.dart';
import '../cards/compact_label_card_widget.dart';
import '../common/error_state_widget.dart';
import '../common/empty_state_widget.dart';
import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/bubble_tooltip.dart';
import '../../../../../../widgets/loading_skeleton.dart';

class ScanResultListWidget extends StatefulWidget {
  final String noSO;
  final String? selectedFilter;
  final String? selectedIdLokasi;
  final VoidCallback onDeleteSuccess;

  const ScanResultListWidget({
    Key? key,
    required this.noSO,
    this.selectedFilter,
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

  // Tambahkan variabel untuk tracking card yang aktif
  String? _activeCardLabel;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
  }

  @override
  void dispose() {
    // Pastikan tooltip ditutup saat widget di-dispose
    _closeTooltip();
    _scrollController.dispose();
    super.dispose();
  }

  // Method untuk menutup tooltip dan reset state
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
      if (_tooltipOverlay != null) {
        _closeTooltip();
      }

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
        if (!isLoadingMore && viewModel.hasMoreData) {
          isLoadingMore = true;
          viewModel.loadMoreData().then((_) {
            if (mounted) {
              isLoadingMore = false;
            }
          });
        }
      }
    });
  }

  // Modifikasi method _showTooltip dengan dynamic height calculation
  void _showTooltip(BuildContext context, TapDownDetails details, String nomorLabel) {
    // Jika tooltip sudah terbuka untuk card yang sama, tutup saja
    if (_activeCardLabel == nomorLabel) {
      _closeTooltip();
      return;
    }

    // Tutup tooltip yang sedang aktif jika ada
    _closeTooltip();

    // Set card yang aktif dan trigger rebuild untuk hover effect
    setState(() {
      _activeCardLabel = nomorLabel;
    });

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

    // HITUNG TINGGI TOOLTIP SECARA DINAMIS berdasarkan tipe label
    double tooltipHeight = _calculateTooltipHeight(nomorLabel);

    // Hitung posisi center card untuk referensi arrow
    double cardCenterY = cardPosition.dy + (cardSize.height / 2);
    double cardCenterX = cardPosition.dx + (cardSize.width / 2);

    // === COBA POSISI HORIZONTAL DULU ===
    double tooltipLeft = cardPosition.dx - tooltipWidth - tooltipCardGap - arrowWidth;
    double arrowLeft = tooltipLeft + tooltipWidth;
    bool showTooltipOnLeft = true;

    // Cek apakah tooltip keluar dari sisi kiri layar
    if (tooltipLeft < padding) {
      // Pindahkan ke kanan card
      tooltipLeft = cardPosition.dx + cardSize.width + tooltipCardGap + arrowWidth;
      arrowLeft = tooltipLeft - arrowWidth;
      showTooltipOnLeft = false;

      // Cek apakah tooltip keluar dari sisi kanan layar
      if (tooltipLeft + tooltipWidth > screenSize.width - padding) {
        // Fallback ke posisi vertikal (atas/bawah)
        _showVerticalTooltip(context, cardPosition, cardSize, screenSize, nomorLabel, tooltipHeight);
        return;
      }
    }

    // === POSISI HORIZONTAL MEMUNGKINKAN, ATUR POSITIONING ===

    // Posisi vertikal tooltip - coba center dengan card dulu
    double tooltipTop = cardCenterY - (tooltipHeight / 2);

    // PERBAIKAN UTAMA: Cek dan sesuaikan jika tooltip keluar dari layar
    bool tooltipAdjusted = false;
    double originalTooltipTop = tooltipTop;

    if (tooltipTop < padding) {
      tooltipTop = padding;
      tooltipAdjusted = true;
    } else if (tooltipTop + tooltipHeight > screenSize.height - padding) {
      tooltipTop = screenSize.height - tooltipHeight - padding;
      tooltipAdjusted = true;
    }

    // Posisi arrow - SELALU menunjuk ke center card
    double arrowTop = cardCenterY - (arrowHeight / 2);

    // PENTING: Batasi arrow agar tidak keluar dari batas tooltip
    double minArrowTop = tooltipTop + 15; // Margin dari atas tooltip
    double maxArrowTop = tooltipTop + tooltipHeight - arrowHeight - 15; // Margin dari bawah

    // Clamp arrow position dalam batas tooltip
    if (arrowTop < minArrowTop) {
      arrowTop = minArrowTop;
    } else if (arrowTop > maxArrowTop) {
      arrowTop = maxArrowTop;
    }

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss area - tutup tooltip saat tap di area lain
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _closeTooltip();
            },
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.transparent,
            ),
          ),

          // Arrow - horizontal positioning
          Positioned(
            left: arrowLeft,
            top: arrowTop,
            child: CustomPaint(
              size: Size(arrowWidth.toDouble(), arrowHeight.toDouble()),
            ),
          ),

          // Tooltip content dengan height constraint yang dinamis
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: BubbleTooltip(
              message: nomorLabel,
              maxWidth: tooltipWidth,
              maxHeight: tooltipHeight, // Gunakan tinggi yang sudah dihitung
              isHorizontalLayout: true,
            ),
          ),
        ],
      ),
    );

    overlay.insert(_tooltipOverlay!);
  }

  // Method untuk menghitung tinggi tooltip berdasarkan tipe label
  double _calculateTooltipHeight(String nomorLabel) {
    // Base height untuk header
    double baseHeight = 80; // Header height

    // Height per info item
    double itemHeight = 50; // Setiap baris info

    // Tentukan jumlah item berdasarkan kode awal label
    final kodeAwal = nomorLabel.split('.').first.toUpperCase();
    int itemCount = 0;

    switch (kodeAwal) {
      case 'A':
      case 'B':
      case 'D':
      case 'BB':
      case 'BA':
        itemCount = 6; // 6 info items (jenis, tanggal, jumlah sak, berat, gudang, lokasi)
        break;
      case 'F':
      case 'M':
      case 'V':
      case 'H':
      case 'BF':
        itemCount = 5; // 5 info items (jenis, tanggal, berat, gudang, lokasi)
        break;
      default:
        itemCount = 1; // Error case
    }

    // Tambahkan padding dan margin
    double padding = 32; // Top + bottom padding

    // Total height
    double totalHeight = baseHeight + (itemCount * itemHeight) + padding;

    // Batas minimum dan maksimum
    double minHeight = 120;
    double maxHeight = 400;

    return totalHeight.clamp(minHeight, maxHeight);
  }

  // Method terpisah untuk vertical tooltip dengan dynamic height
  void _showVerticalTooltip(BuildContext context, Offset cardPosition, Size cardSize, Size screenSize, String nomorLabel, double tooltipHeight) {
    final overlay = Overlay.of(context);

    const double tooltipWidth = 260;
    const double arrowWidth = 12;
    const double arrowHeight = 10;
    const double padding = 8;
    const double tooltipCardGap = 8;

    double cardCenterX = cardPosition.dx + (cardSize.width / 2);
    double cardCenterY = cardPosition.dy + (cardSize.height / 2);

    // Posisi horizontal tooltip (center dengan card)
    double tooltipLeft = cardCenterX - (tooltipWidth / 2);

    // Pastikan tooltip tidak keluar dari sisi kiri/kanan
    if (tooltipLeft < padding) {
      tooltipLeft = padding;
    } else if (tooltipLeft + tooltipWidth > screenSize.width - padding) {
      tooltipLeft = screenSize.width - tooltipWidth - padding;
    }

    // Arrow SELALU di center card horizontal
    double arrowLeft = cardCenterX - (arrowWidth / 2);

    // Batasi arrow agar tidak keluar dari batas tooltip horizontal
    double minArrowLeft = tooltipLeft + 15;
    double maxArrowLeft = tooltipLeft + tooltipWidth - arrowWidth - 15;

    if (arrowLeft < minArrowLeft) {
      arrowLeft = minArrowLeft;
    } else if (arrowLeft > maxArrowLeft) {
      arrowLeft = maxArrowLeft;
    }

    // Tentukan apakah tooltip di atas atau bawah card berdasarkan tinggi yang akurat
    bool showTooltipAbove = cardPosition.dy + cardSize.height + tooltipHeight + tooltipCardGap > screenSize.height - padding;

    double tooltipTop;
    double arrowTop;
    bool isPointingUp = false;

    if (showTooltipAbove && cardPosition.dy - tooltipHeight - tooltipCardGap >= padding) {
      // Tooltip di atas card
      tooltipTop = cardPosition.dy - tooltipHeight - tooltipCardGap;
      arrowTop = cardPosition.dy - arrowHeight;
      isPointingUp = false; // Arrow menunjuk ke bawah (ke card)
    } else {
      // Tooltip di bawah card
      tooltipTop = cardPosition.dy + cardSize.height + tooltipCardGap;
      arrowTop = cardPosition.dy + cardSize.height;
      isPointingUp = true; // Arrow menunjuk ke atas (ke card)

      // Pastikan tooltip tidak keluar dari bawah layar dengan tinggi yang akurat
      if (tooltipTop + tooltipHeight > screenSize.height - padding) {
        tooltipTop = screenSize.height - tooltipHeight - padding;
      }
    }

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss area
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _closeTooltip();
            },
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.transparent,
            ),
          ),

          // Tooltip content dengan height constraint yang dinamis
          Positioned(
            left: tooltipLeft,
            top: tooltipTop,
            child: BubbleTooltip(
              message: nomorLabel,
              maxWidth: tooltipWidth,
              maxHeight: tooltipHeight, // Gunakan tinggi yang sudah dihitung
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
      // Tutup tooltip saat user back
      onWillPop: () async {
        if (_tooltipOverlay != null) {
          _closeTooltip();
          return false; // Prevent back navigation first time
        }
        return true; // Allow back navigation
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
            return const EmptyStateWidget(message: 'Data Hasil Scan Tidak Ditemukan');
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
                  onTapDown: (details) => _showTooltip(itemContext, details, label.nomorLabel),
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
                      idLokasi: label.idLokasi ?? '',
                      username: label.username,
                      isReference: false,
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

  void _showDeleteBottomSheet(String nomorLabel) {
    // Tutup tooltip saat bottom sheet dibuka
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
    final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
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
        // Refresh data after successful deletion
        final labelBeforeViewModel = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
        await labelBeforeViewModel.fetchInitialData(
          labelBeforeViewModel.noSO,
          filterBy: labelBeforeViewModel.currentFilter ?? 'all',
          idLokasi: labelBeforeViewModel.currentIdLokasi,
        );
        widget.onDeleteSuccess();
      }
    }
  }
}