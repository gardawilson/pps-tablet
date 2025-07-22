import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/stock_opname_detail_view_model.dart';
import '../view_models/stock_opname_label_before_view_model.dart';
import '../view_models/lokasi_view_model.dart';
import '../view_models/socket_manager.dart';
import '../widgets/loading_skeleton.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:async';


class StockOpnameDetailScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameDetailScreen({Key? key, required this.noSO, required this.tgl}) : super(key: key);

  @override
  _StockOpnameDetailScreenState createState() => _StockOpnameDetailScreenState();
}

class _StockOpnameDetailScreenState extends State<StockOpnameDetailScreen> {
  final ScrollController _scrollControllerBefore = ScrollController();
  final ScrollController _scrollControllerAfter = ScrollController();
  String? _selectedFilter;
  String? _selectedIdLokasi;
  bool isLoadingMoreBefore = false;
  bool isLoadingMoreAfter = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
    final lokasiVM = Provider.of<LokasiViewModel>(context, listen: false);

    // ✅ Initialize SocketManager (hanya perlu sekali)
    final socketManager = SocketManager();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Initialize socket first (central socket management)
      socketManager.initSocket();

      // ✅ Initialize socket for both ViewModels (akan menggunakan SocketManager yang sama)
      detailVM.initSocket();
      beforeVM.initSocket(); // Tambahkan ini juga untuk beforeVM

      // Fetch initial data
      detailVM.fetchInitialData(widget.noSO);
      beforeVM.fetchInitialData(widget.noSO);
      lokasiVM.fetchLokasi();
    });

    _setupScrollListeners();
  }

  void _setupScrollListeners() {
    _scrollControllerBefore.addListener(() {
      if (_scrollControllerBefore.position.pixels >= _scrollControllerBefore.position.maxScrollExtent - 100) {
        final beforeViewModel = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
        if (!isLoadingMoreBefore && beforeViewModel.hasMoreData) {
          isLoadingMoreBefore = true;
          beforeViewModel.loadMoreData().then((_) {
            isLoadingMoreBefore = false;
          });
        }
      }
    });

    _scrollControllerAfter.addListener(() {
      if (_scrollControllerAfter.position.pixels >= _scrollControllerAfter.position.maxScrollExtent - 100) {
        final viewModel = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
        if (!isLoadingMoreAfter && viewModel.hasMoreData) {
          isLoadingMoreAfter = true;
          viewModel.loadMoreData().then((_) {
            isLoadingMoreAfter = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollControllerBefore.dispose();
    _scrollControllerAfter.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Opname',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              '${widget.tgl} • ${widget.noSO}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: Row(
              children: [
                // Acuan (Left)
                Expanded(
                  child: Column(
                    children: [
                      Consumer<StockOpnameLabelBeforeViewModel>(
                        builder: (context, beforeVM, child) {
                          return _buildSectionHeaderWithTotal(
                            'DATA STOCK',
                            Colors.orange.shade600,
                            beforeVM.totalData,
                          );
                        },
                      ),
                      Expanded(child: _buildBeforeList()),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey.shade300),
                // Stock Opname (Right)
                Expanded(
                  child: Column(
                    children: [
                      Consumer<StockOpnameDetailViewModel>(
                        builder: (context, detailVM, child) {
                          return _buildSectionHeaderWithTotal(
                            'HASIL SCAN',
                            Colors.green.shade600,
                            detailVM.totalData,
                          );
                        },
                      ),
                      Expanded(child: _buildAfterList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildFilterDropdown()),
          const SizedBox(width: 12),
          Expanded(child: _buildLokasiDropdown()),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchLabel()),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderWithTotal(String title, Color color, int totalData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              totalData.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeList() {
    return Consumer<StockOpnameLabelBeforeViewModel>(
      builder: (context, beforeVM, child) {
        if (beforeVM.isInitialLoading && beforeVM.items.isEmpty) {
          return const LoadingSkeleton();
        }

        if (beforeVM.errorMessage.isNotEmpty) {
          return _buildErrorState(beforeVM.errorMessage);
        }

        if (beforeVM.items.isEmpty) {
          return _buildEmptyState('Data Stock Tidak Ditemukan');
        }

        return ListView.builder(
          controller: _scrollControllerBefore,
          padding: const EdgeInsets.all(8),
          itemCount: beforeVM.items.length + (beforeVM.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == beforeVM.items.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final label = beforeVM.items[index];
            return _buildCompactCard(
              nomorLabel: label.nomorLabel,
              labelType: label.labelType,
              jmlhSak: label.jmlhSak,
              berat: label.berat,
              idLokasi: label.idLokasi,
              isReference: true,
            );
          },
        );
      },
    );
  }

  Widget _buildAfterList() {
    return Consumer<StockOpnameDetailViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isInitialLoading && viewModel.labels.isEmpty) {
          return const LoadingSkeleton();
        }

        if (viewModel.errorMessage.isNotEmpty) {
          return _buildErrorState(viewModel.errorMessage);
        }

        if (viewModel.labels.isEmpty) {
          return _buildEmptyState('Data Hasil Scan Tidak Ditemukan');
        }

        return ListView.builder(
          controller: _scrollControllerAfter,
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

            return InkWell(
              onLongPress: () async {
                final bottomSheetContext = context; // Simpan context yang masih aktif

                showModalBottomSheet(
                  context: bottomSheetContext,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Hapus Data'),
                          onTap: () async {
                            Navigator.pop(context); // Tutup bottom sheet dulu

                            await Future.delayed(const Duration(milliseconds: 100)); // Hindari race condition

                            final confirm = await showDialog<bool>(
                              context: bottomSheetContext,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: Text('Apakah Anda yakin ingin menghapus label ${label.nomorLabel}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final viewModel = Provider.of<StockOpnameDetailViewModel>(
                                bottomSheetContext,
                                listen: false,
                              );

                              final success = await viewModel.deleteLabel(label.nomorLabel);

                              // Tampilkan snackbar
                              ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Label ${label.nomorLabel} berhasil dihapus'
                                        : 'Gagal menghapus label ${label.nomorLabel}',
                                  ),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );

                              // 👉 Fetch ulang data viewmodel setelah hapus
                              if (success) {
                                final labelBeforeViewModel = Provider.of<StockOpnameLabelBeforeViewModel>(
                                  bottomSheetContext,
                                  listen: false,
                                );
                                await labelBeforeViewModel.fetchInitialData(
                                  labelBeforeViewModel.noSO,
                                  filterBy: labelBeforeViewModel.currentFilter ?? 'all',
                                  idLokasi: labelBeforeViewModel.currentIdLokasi,
                                );
                              }
                            }

                          },
                        ),
                      ],
                    ),
                  ),
                );
              },

              child: _buildCompactCard(
                nomorLabel: label.nomorLabel,
                labelType: label.labelType,
                jmlhSak: label.jmlhSak,
                berat: label.berat,
                idLokasi: label.idLokasi ?? '',
                username: label.username,
                isReference: false,
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildCompactCard({
    required String nomorLabel,
    required String labelType,
    required int jmlhSak,
    required double berat,
    required String idLokasi,
    String? username,
    required bool isReference,
  }) {
    final Color accentColor = isReference ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nomor Label + Type
            Row(
              children: [
                Icon(Icons.qr_code_2, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nomorLabel,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    labelType,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Info baris horizontal dengan icon
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _infoIconText(Icons.inventory_2, "Sak", "$jmlhSak"),
                _infoIconText(Icons.monitor_weight, "Berat", "${berat.toStringAsFixed(2)} kg"),
                _infoIconText(Icons.location_on, "Lokasi", idLokasi),
                if (username != null && username.isNotEmpty)
                  _infoIconText(Icons.person, "User", username),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIconText(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6, // Atau sesuai kebutuhan
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Data Kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterDropdown() {
    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        hint: const Text('Filter', style: TextStyle(fontSize: 14)),
        isExpanded: true,
        onChanged: (value) {
          setState(() {
            _selectedFilter = value;
          });
          _refreshData();
        },
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Semua')),
          DropdownMenuItem(value: 'bahanbaku', child: Text('Bahan Baku')),
          DropdownMenuItem(value: 'washing', child: Text('Washing')),
          DropdownMenuItem(value: 'broker', child: Text('Broker')),
          DropdownMenuItem(value: 'crusher', child: Text('Crusher')),
          DropdownMenuItem(value: 'bonggolan', child: Text('Bonggolan')),
          DropdownMenuItem(value: 'gilingan', child: Text('Gilingan')),
        ],
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLokasiDropdown() {
    return Consumer<LokasiViewModel>(
      builder: (context, lokasiVM, child) {
        if (lokasiVM.isLoading) {
          return Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final lokasiItems = [
          const MapEntry('all', 'Semua'),
          ...lokasiVM.lokasiList.map((e) => MapEntry(e.idLokasi, e.idLokasi)),
        ];

        final selectedEntry = lokasiItems.firstWhere(
              (item) => item.key == (_selectedIdLokasi ?? 'all'),
          orElse: () => lokasiItems.first,
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownSearch<MapEntry<String, String>>(
            items: lokasiItems,
            selectedItem: selectedEntry,
            itemAsString: (item) => item.value,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Cari lokasi...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            dropdownButtonProps: const DropdownButtonProps(
              icon: Icon(Icons.arrow_drop_down),
            ),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
                hintText: "Lokasi",
              ),
            ),
            onChanged: (selectedEntry) {
              final selectedId = selectedEntry?.key;
              setState(() {
                _selectedIdLokasi = selectedId;
              });
              _refreshData();
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchLabel() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: 53,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {}); // Refresh suffix

                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
                      final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);

                      if (value.isEmpty) {
                        detailVM.clearSearch();
                        beforeVM.clearSearch();
                      } else {
                        detailVM.search(value);
                        beforeVM.search(value);
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Cari label...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  color: Colors.grey,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    final detailVM = Provider.of<StockOpnameDetailViewModel>(context, listen: false);
                    final beforeVM = Provider.of<StockOpnameLabelBeforeViewModel>(context, listen: false);
                    detailVM.clearSearch();
                    beforeVM.clearSearch();
                  },
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
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