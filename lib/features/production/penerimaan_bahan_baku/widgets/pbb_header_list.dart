// lib/features/production/penerimaan_bahan_baku/widgets/pbb_header_list.dart
//
// Varian tablet-friendly dari `BahanBakuHeaderTable` (yang didesain sebagai
// tabel desktop padat) — kartu besar dengan touch target yang lebih lega,
// dipakai khusus oleh modul Penerimaan Bahan Baku. State tetap dari
// `BahanBakuViewModel` yang sama (fungsional identik dengan Label Bahan
// Baku), hanya tampilannya yang berbeda.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../label/bahan_baku/model/bahan_baku_header.dart';
import '../../../label/bahan_baku/view_model/bahan_baku_view_model.dart';

class PbbHeaderList extends StatelessWidget {
  final ScrollController scrollController;
  final ValueChanged<BahanBakuHeader> onItemTap;
  final Future<void> Function()? onRefresh;

  const PbbHeaderList({
    super.key,
    required this.scrollController,
    required this.onItemTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BahanBakuViewModel>(
      builder: (context, vm, _) {
        Widget list;
        if (vm.isLoading && vm.items.isEmpty) {
          list = const Center(child: CircularProgressIndicator());
        } else if (vm.errorMessage.isNotEmpty && vm.items.isEmpty) {
          list = _ErrorState(message: vm.errorMessage);
        } else if (vm.items.isEmpty) {
          list = const _EmptyState();
        } else {
          list = ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: vm.items.length + (vm.isFetchingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == vm.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final item = vm.items[index];
              final isSelected = vm.selectedNoBahanBaku == item.noBahanBaku;
              return _HeaderCard(
                item: item,
                isSelected: isSelected,
                onTap: () => onItemTap(item),
              );
            },
          );
        }

        if (onRefresh != null) {
          return RefreshIndicator(onRefresh: onRefresh!, child: list);
        }
        return list;
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final BahanBakuHeader item;
  final bool isSelected;
  final VoidCallback onTap;

  const _HeaderCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFE9F2FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0C66E4) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.noBahanBaku,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF0C66E4) : const Color(0xFF172B4D),
                      ),
                    ),
                  ),
                  if (item.used)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFB71C1C).withValues(alpha: 0.35)),
                      ),
                      child: const Text(
                        'Terpakai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB71C1C),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: formatDateToShortId(item.dateCreate),
                  ),
                  _InfoChip(
                    icon: Icons.local_shipping_outlined,
                    text: item.namaSupplier.isEmpty ? '-' : item.namaSupplier,
                  ),
                  _InfoChip(
                    icon: Icons.directions_car_filled_outlined,
                    text: (item.noPlat ?? '').isEmpty ? '-' : item.noPlat!,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF44546F),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Belum ada data', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
