// lib/features/shared/inject_production/widgets/furniture_wip_by_inject_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/furniture_wip_by_inject_production_model.dart';
import '../view_model/inject_production_view_model.dart';

class FurnitureWipByInjectSection extends StatefulWidget {
  /// NoProduksi Inject yang dipilih
  final String? noProduksi;

  /// Judul section
  final String title;

  /// Icon di depan title
  final IconData icon;

  const FurnitureWipByInjectSection({
    super.key,
    required this.noProduksi,
    this.title = 'Jenis Furniture WIP (Inject)',
    this.icon = Icons.chair_alt_outlined,
  });

  @override
  State<FurnitureWipByInjectSection> createState() =>
      _FurnitureWipByInjectSectionState();
}

class _FurnitureWipByInjectSectionState
    extends State<FurnitureWipByInjectSection> {
  String? _lastNoProduksi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchIfNeeded());
  }

  @override
  void didUpdateWidget(covariant FurnitureWipByInjectSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noProduksi != widget.noProduksi) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchIfNeeded());
    }
  }

  Future<void> _fetchIfNeeded() async {
    final vm = context.read<InjectProductionViewModel>();
    final noProd = widget.noProduksi?.trim();

    // Kalau NoProduksi kosong → kosongkan state di VM
    if (noProd == null || noProd.isEmpty) {
      vm.clearFurnitureWip();
      _lastNoProduksi = null;
      return;
    }

    // NoProduksi sama dengan sebelumnya → tidak usah fetch ulang
    if (_lastNoProduksi == noProd) return;

    _lastNoProduksi = noProd;
    await vm.fetchFurnitureWipByInjectProduction(noProd);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InjectProductionViewModel>(
      builder: (context, vm, _) {
        final bool isLoading = vm.isLoadingFurnitureWip;
        final String error = vm.furnitureWipError;
        final List<FurnitureWipByInjectItem> items = vm.furnitureWipItems;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(widget.icon, size: 22, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (items.isNotEmpty && !isLoading && error.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Content (TANPA berat, hanya jenis)
              if (widget.noProduksi == null ||
                  widget.noProduksi!.trim().isEmpty)
                _buildEmptyMessage(
                  'Pilih proses inject untuk melihat furniture WIP',
                )
              else if (isLoading)
                _buildLoadingIndicator()
              else if (error.isNotEmpty)
                  _buildErrorMessage(error)
                else if (items.isEmpty)
                    _buildEmptyMessage(
                      'Tidak ada furniture WIP untuk NoProduksi ${widget.noProduksi}',
                    )
                  else
                    _buildFurnitureChips(items),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Memuat...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.red.shade700),
            ),
          ),
          TextButton(
            onPressed: _fetchIfNeeded,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildFurnitureChips(List<FurnitureWipByInjectItem> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.label,
                size: 14,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                item.namaFurnitureWip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
