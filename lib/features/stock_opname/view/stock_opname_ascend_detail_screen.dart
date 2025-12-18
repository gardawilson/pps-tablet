import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/stock_opname_family_view_model.dart';
import '../view_model/stock_opname_ascend_view_model.dart';
import '../../../common/widgets/loading_dialog.dart';

import 'widgets/list_sections/ascend_appbar.dart';
import 'widgets/list_sections/ascend_filter_section.dart';
import 'widgets/list_sections/ascend_family_section.dart';
import 'widgets/list_sections/ascend_item_section.dart';

class StockOpnameAscendDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;
  final List<int> idWarehouses;


  const StockOpnameAscendDetailScreen({super.key, required this.noSO, required this.tgl, required this.idWarehouses,
  });

  @override
  State<StockOpnameAscendDetailScreen> createState() => _StockOpnameAscendDetailScreenState();
}

class _StockOpnameAscendDetailScreenState extends State<StockOpnameAscendDetailScreen> {
  int? _selectedFamilyID;

  // cache controller tetap di parent agar lifecycle-nya aman
  final Map<int, TextEditingController> _qtyFoundControllers = {};
  final Map<int, TextEditingController> _remarkControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("ASCEND DETAIL → noSO=${widget.noSO}, idWarehouses=${widget.idWarehouses}");

      context.read<StockOpnameFamilyViewModel>().fetchFamilies(widget.noSO);
    });
  }

  @override
  void dispose() {
    for (final c in _qtyFoundControllers.values) c.dispose();
    for (final c in _remarkControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed() async {
    final ascendVM = context.read<StockOpnameAscendViewModel>();
    final familyVM = context.read<StockOpnameFamilyViewModel>();

    if (ascendVM.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada data untuk disimpan")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Menyimpan data..."),
    );

    final success = await ascendVM.saveAscendItems(widget.noSO);

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      await familyVM.fetchFamilies(widget.noSO);
      if (_selectedFamilyID != null) {
        await ascendVM.fetchAscendItems(widget.noSO, _selectedFamilyID!);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Data berhasil disimpan & di-refresh")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Gagal menyimpan data")));
    }
  }

  void _onFamilySelected(int familyID) {
    setState(() => _selectedFamilyID = familyID);
    context.read<StockOpnameAscendViewModel>().fetchAscendItems(widget.noSO, familyID);
    _qtyFoundControllers.clear();
    _remarkControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AscendAppBar(noSO: widget.noSO, tgl: widget.tgl),
      body: Column(
        children: [
          AscendFilterSection(
            noSO: widget.noSO,
            selectedFamilyID: _selectedFamilyID,
            onSavePressed: _onSavePressed,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  AscendFamilySection(
                    selectedFamilyID: _selectedFamilyID,
                    onFamilySelected: _onFamilySelected,
                  ),
                  Container(width: 1, color: Colors.grey.shade200),
                  AscendItemSection(
                    noSO: widget.noSO,
                    tgl: widget.tgl,
                    idWarehouses: widget.idWarehouses,

                    qtyFoundControllers: _qtyFoundControllers,
                    remarkControllers: _remarkControllers,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
