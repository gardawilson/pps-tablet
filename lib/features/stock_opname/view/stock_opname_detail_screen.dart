// features/stock_opname/detail/view/stock_opname_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/stock_opname_detail_view_model.dart';
import '../view_model/stock_opname_label_before_view_model.dart';
import '../view_model/lokasi_view_model.dart';
import '../view_model/socket_manager.dart';
import 'widgets/filter_section/filter_dropdown_widget.dart';
import 'widgets/filter_section/lokasi_dropdown_widget.dart';
import 'widgets/filter_section/search_label_widget.dart';
import 'widgets/list_sections/stock_data_list_widget.dart';
import 'widgets/list_sections/scan_result_list_widget.dart';
import 'widgets/list_sections/section_header_widget.dart';
import 'widgets/dialogs/summary_dialog_widget.dart'; // Import dialog widget
import '../../../common/widgets/loading_dialog.dart';

class StockOpnameDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameDetailScreen({
    Key? key,
    required this.noSO,
    required this.tgl
  }) : super(key: key);

  @override
  State<StockOpnameDetailScreen> createState() => _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  String? _selectedFilter;
  String? _selectedIdLokasi;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
    final lokasiVM = Provider.of<LokasiViewModel>(context, listen: false);

    final socketManager = SocketManager();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      socketManager.initSocket();
      detailVM.initSocket();
      beforeVM.initSocket();

      detailVM.fetchInitialData(widget.noSO);
      beforeVM.fetchInitialData(widget.noSO);
      lokasiVM.fetchLokasi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Row(
              children: [
                _buildStockDataSection(),
                Container(width: 1, color: Colors.grey.shade300),
                _buildScanResultSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stock Opname',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            '${widget.tgl} • ${widget.noSO}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D47A1),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Tambahkan button summary di AppBar
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: _showSummaryDialog,
            icon: const Icon(Icons.assessment, color: Colors.white),
            tooltip: 'Lihat Ringkasan',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FilterDropdownWidget(
              selectedFilter: _selectedFilter,
              onChanged: _onFilterChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LokasiDropdownWidget(
              selectedIdLokasi: _selectedIdLokasi,
              onChanged: _onLokasiChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SearchLabelWidget(
              onSearch: _onSearch,
              onClear: _onSearchClear,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDataSection() {
    return Expanded(
      child: Column(
        children: [
          Consumer<StockOpnameLabelBeforeViewModel>(
            builder: (context, beforeVM, child) {
              return SectionHeaderWidget(
                title: 'DATA STOCK',
                color: Colors.orange.shade600,
                totalData: beforeVM.totalData,
              );
            },
          ),
          Expanded(
            child: StockDataListWidget(
              noSO: widget.noSO,
              selectedFilter: _selectedFilter,
              selectedIdLokasi: _selectedIdLokasi,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultSection() {
    return Expanded(
      child: Column(
        children: [
          Consumer<StockOpnameDetailViewModel>(
            builder: (context, detailVM, child) {
              return SectionHeaderWidget(
                title: 'HASIL SCAN',
                color: Colors.green.shade600,
                totalData: detailVM.totalData,
              );
            },
          ),
          Expanded(
            child: ScanResultListWidget(
              noSO: widget.noSO,
              selectedFilter: _selectedFilter,
              selectedIdLokasi: _selectedIdLokasi,
              onDeleteSuccess: _refreshData,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSummaryDialog() async {
    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);

    // Jika masih loading, tampilkan dialog loading dulu
    if (detailVM.isInitialLoading || beforeVM.isInitialLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingDialog(message: 'Menyiapkan ringkasan...'),
      );

      // Tunggu hingga keduanya selesai loading
      while (detailVM.isInitialLoading || beforeVM.isInitialLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Tutup dialog loading
      Navigator.of(context).pop();
    }

    // Setelah data siap, tampilkan dialog ringkasan
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SummaryDialogWidget(
          stockTotalDataGlobal: beforeVM.totalGlobal,
          stockTotalSakGlobal: beforeVM.totalSakGlobal,
          stockTotalBeratGlobal: beforeVM.totalBeratGlobal,
          stockTotalData: beforeVM.totalData,
          stockTotalSak: beforeVM.totalSak,
          stockTotalBerat: beforeVM.totalBerat,
          scanTotalData: detailVM.totalData,
          scanTotalSak: detailVM.totalSak,
          scanTotalBerat: detailVM.totalBerat,
          noSO: widget.noSO,
          tgl: widget.tgl,
          selectedCategory: _selectedFilter ?? 'all',
          selectedLocation: _selectedIdLokasi ?? 'all',
        );
      },
    );
  }


  void _onFilterChanged(String? value) {
    setState(() {
      _selectedFilter = value;
    });
    _refreshData();
  }

  void _onLokasiChanged(String? value) {
    setState(() {
      _selectedIdLokasi = value;
    });
    _refreshData();
  }

  void _onSearch(String query) {
    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);

    detailVM.search(query);
    beforeVM.search(query);
  }

  void _onSearchClear() {
    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);

    detailVM.clearSearch();
    beforeVM.clearSearch();
  }

  void _refreshData() {
    final detailViewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeViewModel = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);

    detailViewModel.fetchInitialData(
      widget.noSO,
      filterBy: _selectedFilter ?? 'all',
      idLokasi: _selectedIdLokasi == 'all' ? null : _selectedIdLokasi,
    );

    beforeViewModel.fetchInitialData(
      widget.noSO,
      filterBy: _selectedFilter ?? 'all',
      idLokasi: _selectedIdLokasi == 'all' ? null : _selectedIdLokasi,
    );
  }
}