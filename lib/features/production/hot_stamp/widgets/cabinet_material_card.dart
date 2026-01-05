// lib/features/production/hot_stamping/widgets/cabinet_material_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/hot_stamp_production_input_view_model.dart';
import '../model/hot_stamping_inputs_model.dart';
import 'add_cabinet_material_dialog.dart';

class CabinetMaterialCard extends StatelessWidget {
  final String noProduksi;
  final bool locked;
  final bool canDelete;
  final int idWarehouse;

  const CabinetMaterialCard({
    super.key,
    required this.noProduksi,
    required this.idWarehouse,
    this.locked = false,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HotStampingProductionInputViewModel>(
      builder: (context, vm, _) {
        final inputs = vm.inputsOf(noProduksi);

        // ✅ TEMP + DB (tanpa reversed supaya isTemp logic aman)
        final tempList = vm.tempCabinetMaterial;
        final dbList = inputs?.cabinetMaterial ?? const <CabinetMaterialItem>[];

        final materialAll = <CabinetMaterialItem>[
          ...tempList,
          ...dbList,
        ];

        // ✅ Create Set of temp IDs untuk check isTemp
        final tempIds = tempList
            .map((item) => item.IdCabinetMaterial ?? 0)
            .where((id) => id > 0)
            .toSet();

        // ✅ total = Jumlah (num)
        final totalJumlah = materialAll.fold<num>(
          0,
              (sum, item) => sum + (item.Jumlah ?? 0),
        );

        final totalUnit = _bestUnit(materialAll);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== HEADER =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cabinet Material',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${materialAll.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== BODY =====
              if (materialAll.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada material',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: materialAll.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = materialAll[index];

                      // ✅ Check isTemp by ID (bukan by index)
                      final isTemp = tempIds.contains(item.IdCabinetMaterial ?? 0);

                      return _MaterialItemCard(
                        item: item,
                        isTemp: isTemp,
                        locked: locked,
                        canDelete: canDelete,
                        onDelete: isTemp
                            ? () => _handleDeleteTemp(context, vm, item)
                            : () => _handleDeleteExisting(context, vm, item),
                      );
                    },
                  ),
                ),

              // ===== FOOTER =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    // Summary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmtNum(totalJumlah)} ${totalUnit ?? ""}'.trim(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add button
                    FilledButton.icon(
                      onPressed: locked ? null : () => _showAddMaterialDialog(context),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Tambah Material'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== HELPERS =====

  static String _fmtNum(num v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toString();
  }

  static String? _bestUnit(List<CabinetMaterialItem> items) {
    for (final it in items) {
      final u = (it.NamaUOM ?? '').trim();
      if (u.isNotEmpty) return u;
    }
    return null;
  }

  // ===== HANDLERS =====

  void _handleDeleteTemp(
      BuildContext context,
      HotStampingProductionInputViewModel vm,
      CabinetMaterialItem item,
      ) {
    vm.deleteTempCabinetMaterialItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Material TEMP dihapus'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleDeleteExisting(
      BuildContext context,
      HotStampingProductionInputViewModel vm,
      CabinetMaterialItem item,
      ) async {
    final name = item.Nama ?? 'Material';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Material?'),
        content: Text('Yakin ingin menghapus $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await vm.deleteItems(noProduksi, [item]);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Material berhasil dihapus'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.deleteError ?? 'Gagal menghapus material'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddMaterialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddCabinetMaterialDialog(
        idWarehouse: idWarehouse,
      ),
    );
  }
}

// ===== MATERIAL ITEM CARD =====

class _MaterialItemCard extends StatelessWidget {
  final CabinetMaterialItem item;
  final bool isTemp;
  final bool locked;
  final bool canDelete;
  final VoidCallback onDelete;

  const _MaterialItemCard({
    required this.item,
    required this.isTemp,
    required this.locked,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Show delete button if:
    // - Item is TEMP, OR
    // - Item is from DB AND not locked AND canDelete permission
    final showDelete = isTemp || (!locked && canDelete);

    final name = item.Nama ?? '-';
    final qty = item.Jumlah ?? 0;
    final unit = item.NamaUOM ?? 'unit';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTemp ? Colors.amber.shade50 : Colors.white,
        border: Border.all(
          color: isTemp ? Colors.amber.shade200 : Colors.grey.shade200,
          width: isTemp ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTemp
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 20,
              color: isTemp ? Colors.amber.shade700 : Colors.deepPurple.shade600,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$qty $unit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ),
                    if (isTemp) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Text(
                          'TEMP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          if (showDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade600,
              tooltip: isTemp ? 'Hapus TEMP' : 'Hapus Material',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            )
          else
            const SizedBox(width: 48), // Placeholder untuk alignment
        ],
      ),
    );
  }
}