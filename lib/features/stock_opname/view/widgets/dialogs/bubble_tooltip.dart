import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/label_detail_view_model.dart';

// Modifikasi BubbleTooltip Widget untuk mendukung horizontal layout
class BubbleTooltip extends StatefulWidget {
  final String message;
  final double maxWidth;
  final bool isHorizontalLayout;
  final double? maxHeight; // Parameter baru untuk membatasi tinggi

  const BubbleTooltip({
    Key? key,
    required this.message,
    this.maxWidth = 260.0,
    this.isHorizontalLayout = true,
    this.maxHeight,
  }) : super(key: key);

  @override
  State<BubbleTooltip> createState() => _BubbleTooltipState();
}

class _BubbleTooltipState extends State<BubbleTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animasi berbeda untuk horizontal dan vertical
    if (widget.isHorizontalLayout) {
      _scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));
    } else {
      _scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ));
    }

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<LabelDetailViewModel>(context, listen: false);
      viewModel.fetchLabelDetail(widget.message);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LabelDetailViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: widget.maxWidth,
                    constraints: BoxConstraints(
                      maxWidth: widget.maxWidth,
                      maxHeight: widget.maxHeight ?? double.infinity,
                      minHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(viewModel),
                          _buildContent(viewModel),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getGradientColor() {
    return const Color(0xFF2196F3);
  }

  IconData _getIcon() {
    return Icons.qr_code;
  }

  String _getTypeNameByCode(String kodeAwal) {
    switch (kodeAwal) {
      case 'A':
        return 'Bahan Baku';
      case 'B':
        return 'Washing';
      case 'D':
        return 'Broker';
      case 'F':
        return 'Crusher';
      case 'M':
        return 'Bonggolan';
      case 'V':
        return 'Gilingan';
      case 'H':
        return 'Mixer';
      case 'BB':
        return 'Furniture WIP';
      case 'BA':
        return 'Barang Jadi';
      case 'BF':
        return 'Reject';
      default:
        return 'Unknown';
    }
  }

  Widget _buildHeader(LabelDetailViewModel viewModel) {
    final kodeAwal = widget.message.split('.').first.toUpperCase();
    final gradientColor = _getGradientColor();
    final icon = _getIcon();
    final typeName = _getTypeNameByCode(kodeAwal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColor,
            gradientColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  typeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LabelDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        height: 80,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        ),
      );
    }

    if (viewModel.detail == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Data tidak ditemukan',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final detail = viewModel.detail!;
    final kodeAwal = widget.message.split('.').first.toUpperCase();

    List<_InfoItem> items = [];

    switch (kodeAwal) {
      case 'A':
      case 'B':
      case 'D':
        items = [
          _InfoItem(Icons.category, 'Jenis', detail.namaJenisPlastik ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.inventory, 'Jumlah Sak', '${detail.jumlahSak ?? "-"}'),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'F':
        items = [
          _InfoItem(Icons.build_circle, 'Jenis', detail.namaCrusher ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'M':
        items = [
          _InfoItem(Icons.category, 'Jenis', detail.namaBonggolan ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'V':
        items = [
          _InfoItem(Icons.precision_manufacturing, 'Jenis', detail.namaGilingan ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'H':
        items = [
          _InfoItem(Icons.precision_manufacturing, 'Jenis', detail.namaMixer ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'BB':
        items = [
          _InfoItem(Icons.precision_manufacturing, 'Jenis', detail.namaFurnitureWIP ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.inventory, 'Pcs', '${detail.pcs ?? "-"}'),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'BA':
        items = [
          _InfoItem(Icons.precision_manufacturing, 'Jenis', detail.namaBJ ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.inventory, 'Pcs', '${detail.pcs ?? "-"}'),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      case 'BF':
        items = [
          _InfoItem(Icons.precision_manufacturing, 'Jenis', detail.namaReject ?? "-"),
          _InfoItem(Icons.calendar_today, 'Tanggal', _formatDate(detail.dateCreate) ?? "-"),
          _InfoItem(Icons.scale, 'Berat', '${detail.berat ?? "-"} kg'),
          _InfoItem(Icons.warehouse, 'Gudang', detail.namaWarehouse ?? "-"),
          _InfoItem(Icons.location_on, 'Lokasi', detail.idLokasi ?? "-"),
        ];
        break;

      default:
        items = [
          _InfoItem(Icons.error, 'Error', 'Tipe label tidak dikenali'),
        ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) => _buildInfoRow(item)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item.icon,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? dateString) {
    if (dateString == null) return null;
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem(this.icon, this.label, this.value);
}