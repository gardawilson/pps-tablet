import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_family_view_model.dart';

class AscendAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String noSO;
  final String tgl;
  const AscendAppBar({super.key, required this.noSO, required this.tgl});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stock Opname Ascend',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              Text('$tgl • $noSO',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Consumer<StockOpnameFamilyViewModel>(
            builder: (context, vm, _) {
              final totalItems = vm.families.fold(0, (s, f) => s + f.totalItem);
              final completeItems = vm.families.fold(0, (s, f) => s + f.completeItem);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$completeItems/$totalItems',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
