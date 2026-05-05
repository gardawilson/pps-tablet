import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/stock_opname_family_view_model.dart';
import '../view_model/stock_opname_ascend_view_model.dart';
import '../../../common/widgets/loading_dialog.dart';
import 'widgets/list_sections/ascend_filter_section.dart';
import 'widgets/list_sections/ascend_family_section.dart';
import 'widgets/list_sections/ascend_item_section.dart';

class StockOpnameAscendDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;
  final List<int> idWarehouses;

  const StockOpnameAscendDetailScreen({
    super.key,
    required this.noSO,
    required this.tgl,
    required this.idWarehouses,
  });

  @override
  State<StockOpnameAscendDetailScreen> createState() =>
      _StockOpnameAscendDetailScreenState();
}

class _StockOpnameAscendDetailScreenState
    extends State<StockOpnameAscendDetailScreen> {
  static const _bgPage = Color(0xFFF8F9FB);
  static const _surface = Color(0xFFFFFFFF);
  static const _border = Color(0xFFE2E6EE);

  int? _selectedFamilyID;

  // cache controller tetap di parent agar lifecycle-nya aman
  final Map<int, TextEditingController> _qtyFoundControllers = {};
  final Map<int, TextEditingController> _remarkControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        "ASCEND DETAIL → noSO=${widget.noSO}, idWarehouses=${widget.idWarehouses}",
      );

      context.read<StockOpnameAscendViewModel>().reset();
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
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    if (ascendVM.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk disimpan")),
      );
      return;
    }

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Menyimpan data..."),
    );

    bool success = false;
    String? errorMsg;
    try {
      success = await ascendVM.saveAscendItems(widget.noSO);
    } catch (e) {
      errorMsg = e.toString();
    }

    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }
    if (!mounted) return;

    if (success) {
      await familyVM.fetchFamilies(widget.noSO);
      if (_selectedFamilyID != null) {
        await ascendVM.fetchAscendItems(widget.noSO, _selectedFamilyID!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Data berhasil disimpan & di-refresh")),
      );
    } else if (errorMsg != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Gagal menyimpan: $errorMsg")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Gagal menyimpan data")));
    }
  }

  void _onFamilySelected(int familyID) {
    setState(() => _selectedFamilyID = familyID);
    context.read<StockOpnameAscendViewModel>().fetchAscendItems(
      widget.noSO,
      familyID,
    );
    _qtyFoundControllers.clear();
    _remarkControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [
          AscendFilterSection(
            noSO: widget.noSO,
            tgl: widget.tgl,
            selectedFamilyID: _selectedFamilyID,
            onSavePressed: _onSavePressed,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
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
