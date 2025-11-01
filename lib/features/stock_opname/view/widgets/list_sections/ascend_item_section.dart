import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_model/stock_opname_ascend_view_model.dart';

class AscendItemSection extends StatelessWidget {
  final String noSO;
  final String tgl;
  final Map<int, TextEditingController> qtyFoundControllers;
  final Map<int, TextEditingController> remarkControllers;

  const AscendItemSection({
    super.key,
    required this.noSO,
    required this.tgl,
    required this.qtyFoundControllers,
    required this.remarkControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.inventory_outlined, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text('Detail Item',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1F2937))),
              const Spacer(),
              Consumer<StockOpnameAscendViewModel>(
                builder: (context, vm, _) {
                  if (vm.items.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${vm.items.length} items',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                  );
                },
              ),
            ]),
          ),
          Expanded(
            child: Consumer<StockOpnameAscendViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 3),
                      SizedBox(height: 12),
                      Text('Memuat item...', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ]),
                  );
                }
                if (vm.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (vm.items.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_outlined, color: Color(0xFF9CA3AF), size: 48),
                      SizedBox(height: 8),
                      Text("Pilih family untuk lihat items", style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                    ]),
                  );
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: const BoxDecoration(color: Color(0xFF1F2937)),
                      child: const Row(children: [
                        Expanded(flex: 1, child: Text("No", style: _th)),
                        Expanded(flex: 2, child: Text("Item Code", style: _th)),
                        Expanded(flex: 2, child: Text("Shelf Code", style: _th)),
                        Expanded(flex: 4, child: Text("Nama Item", style: _th)),
                        Expanded(flex: 1, child: Text("PCS", style: _th, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text("Qty Usage", style: _th, textAlign: TextAlign.center)),
                        Expanded(flex: 2, child: Text("Qty Found", style: _th, textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text("Remark", style: _th)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: vm.items.length,
                        itemExtent: 50,
                        itemBuilder: (context, index) {
                          final item = vm.items[index];
                          final isEven = index % 2 == 0;

                          final qtyCtrl = qtyFoundControllers.putIfAbsent(
                            item.itemID,
                                () => TextEditingController(text: item.qtyFisik != null ? item.qtyFisik.toString() : ""),
                          );
                          final remarkCtrl = remarkControllers.putIfAbsent(
                            item.itemID,
                                () => TextEditingController(text: item.usageRemark ?? ""),
                          );

                          return Container(
                            color: isEven ? const Color(0xFFFAFAFA) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            child: Row(children: [
                              Expanded(flex: 1, child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)))),
                              Expanded(
                                flex: 2,
                                child: Text(item.itemCode,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(item.shelfCode!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(item.itemName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text("${item.pcs}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                              ),
                              // Qty Usage
                              Expanded(
                                flex: 2,
                                child: Builder(
                                  builder: (cellCtx) {
                                    if (vm.isUsageLoading(item.itemID)) {
                                      return const Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onLongPress: () async {
                                        // ✅ Dapatkan posisi widget Qty Usage
                                        final renderBox = cellCtx.findRenderObject() as RenderBox;
                                        final offset = renderBox.localToGlobal(Offset.zero);
                                        final size = renderBox.size;

                                        final selected = await showMenu<String>(
                                          context: cellCtx,
                                          position: RelativeRect.fromLTRB(
                                            offset.dx,                // posisi kiri
                                            offset.dy - 80,            // munculkan 80px di atas widget
                                            offset.dx + size.width,    // kanan
                                            offset.dy,                 // bawah
                                          ),
                                          constraints: const BoxConstraints(minWidth: 140),
                                          items: [
                                            const PopupMenuItem<String>(
                                              value: 'info',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Info'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
                                              value: 'clear',
                                              height: 36,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.refresh, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Clear'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );

                                        if (selected == 'clear') {
                                          final success = await vm.deleteAscendItem(noSO, item.itemID, qtyCtrl: qtyCtrl);
                                          if (success) {
                                            ScaffoldMessenger.of(cellCtx).showSnackBar(
                                              const SnackBar(
                                                content: Text('Item berhasil dihapus'),
                                                duration: Duration(milliseconds: 1200),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(cellCtx).showSnackBar(
                                              const SnackBar(
                                                content: Text('Gagal menghapus item'),
                                                duration: Duration(milliseconds: 1200),
                                              ),
                                            );
                                          }
                                        }
                                        else if (selected == 'info') {
                                          final usageText = item.qtyUsage == null
                                              ? 'belum dihitung'
                                              : item.qtyUsage.toString();
                                          ScaffoldMessenger.of(cellCtx).showSnackBar(
                                            SnackBar(
                                              content: Text('Qty Usage: $usageText (start: $tgl)'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Builder(
                                          builder: (_) {
                                            String displayText;
                                            if (!item.isUpdateUsage) {
                                              displayText = "?";
                                              debugPrint("QtyUsage LOG → itemID=${item.itemID}, qtyUsage=${item.qtyUsage}, isUpdateUsage=${item.isUpdateUsage} → tampil '?'");
                                            } else {
                                              displayText = "${item.qtyUsage}";
                                              debugPrint("QtyUsage LOG → itemID=${item.itemID}, qtyUsage=${item.qtyUsage}, isUpdateUsage=${item.isUpdateUsage} → tampil nilai");
                                            }

                                            return Text(
                                              displayText,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                    );
                                  },
                                ),
                              ),


                              // Qty Found
                              Expanded(
                                flex: 2,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: TextField(
                                    controller: qtyCtrl,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (val) async {
                                      final parsed = double.tryParse(val) ?? 0;
                                      vm.updateQtyFisik(item.itemID, parsed);

                                      if (val.isEmpty) {
                                        debugPrint("QtyUsage LOG → kondisi reset karena val kosong");
                                        vm.resetQtyUsage(item.itemID);
                                      } else {
                                        if (!item.isUpdateUsage) {
                                          debugPrint("QtyUsage LOG → fetch dipanggil, itemID=${item.itemID}, tgl=$tgl");
                                          await vm.fetchQtyUsage(item.itemID, tgl);
                                        }
                                      }
                                    },


                                  ),
                                ),
                              ),

                              // Remark
                              Expanded(
                                flex: 3,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: TextField(
                                    controller: remarkCtrl,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: 'Catatan...',
                                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                    ),
                                    onChanged: (val) => vm.updateUsage(item.itemID, item.qtyUsage ?? -1, val),
                                  ),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _th = TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12);
