import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/washing_view_model.dart';
import '../model/washing_header_model.dart';
import '../model/washing_detail_model.dart';

class WashingTableScreen extends StatefulWidget {
  const WashingTableScreen({super.key});

  @override
  State<WashingTableScreen> createState() => _WashingTableScreenState();
}

class _WashingTableScreenState extends State<WashingTableScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WashingViewModel>().fetchWashingHeaders();
    });

    _scrollController.addListener(() {
      final vm = context.read<WashingViewModel>();

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!_isLoadingMore && vm.hasMore) {
          _isLoadingMore = true;
          vm.loadMore().then((_) {
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
              });
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// 🔎 Trigger pencarian dengan debounce
  void _onSearchChanged(String query, WashingViewModel vm) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      vm.fetchWashingHeaders(search: query);
      _scrollController.jumpTo(0);
    });
  }

  /// 🔹 Form Tambah / Edit
  void _showFormDialog(BuildContext context, WashingViewModel vm,
      {WashingHeader? header}) {
    final jenisCtrl =
    TextEditingController(text: header?.namaJenisPlastik ?? '');
    final warehouseCtrl =
    TextEditingController(text: header?.namaWarehouse ?? '');
    final densityCtrl =
    TextEditingController(text: header?.density?.toString() ?? '');
    final moistureCtrl =
    TextEditingController(text: header?.moisture?.toString() ?? '');

    final isEdit = header != null;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit : Icons.add,
                  color: isEdit ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              Text(isEdit ? 'Edit Washing' : 'Tambah Washing'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: jenisCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Jenis Plastik')),
                TextField(
                    controller: warehouseCtrl,
                    decoration:
                    const InputDecoration(labelText: 'Warehouse')),
                TextField(
                    controller: densityCtrl,
                    decoration: const InputDecoration(labelText: 'Density'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: moistureCtrl,
                    decoration: const InputDecoration(labelText: 'Moisture'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                // final data = WashingHeader(
                //   noWashing: header?.noWashing ?? "",
                //   namaJenisPlastik: jenisCtrl.text,
                //   namaWarehouse: warehouseCtrl.text,
                //   density: double.tryParse(densityCtrl.text),
                //   moisture: double.tryParse(moistureCtrl.text),
                // );
                //
                // if (isEdit) {
                //   vm.updateHeader(data);
                // } else {
                //   vm.createHeader(data);
                // }

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WashingHeader header, WashingViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Yakin ingin hapus ${header.noWashing}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // vm.deleteHeader(header.noWashing);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// 🔎 SearchBar
  Widget _buildSearchBar(WashingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Cari No Washing / Plastik / Warehouse",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => _onSearchChanged(value, vm),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              searchCtrl.clear();
              vm.fetchWashingHeaders(search: "");
              _scrollController.jumpTo(0);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<WashingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Washing Master–Detail'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFormDialog(context, vm),
          )
        ],
      ),
      body: Row(
        children: [
          // === MASTER LIST ===
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSearchBar(vm),
                Expanded(
                  child: Consumer<WashingViewModel>(
                    builder: (context, vm, _) {
                      if (vm.isLoading && vm.items.isEmpty) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (vm.errorMessage.isNotEmpty && vm.items.isEmpty) {
                        return Center(child: Text(vm.errorMessage));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: vm.items.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.blue.shade50,
                              child: const Row(
                                children: [
                                  Expanded(flex: 3, child: Text("No Washing", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 3, child: Text("Jenis Plastik", style: TextStyle(fontWeight: FontWeight.bold))),
                                  Expanded(flex: 2, child: Text("Warehouse", style: TextStyle(fontWeight: FontWeight.bold))),
                                  SizedBox(width: 80, child: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                          }

                          if (index == vm.items.length + 1) {
                            return vm.isFetchingMore
                                ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                  child: CircularProgressIndicator()),
                            )
                                : const SizedBox(height: 60);
                          }

                          final item = vm.items[index - 1];
                          final isSelected =
                              vm.selectedNoWashing == item.noWashing;
                          return _buildHeaderRow(item, isSelected, vm);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1, thickness: 1),

          // === DETAIL ===
          Expanded(
            flex: 3,
            child: Consumer<WashingViewModel>(
              builder: (context, vm, _) {
                if (vm.isDetailLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.details.isEmpty) {
                  return const Center(
                      child: Text("Pilih header untuk lihat detail"));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                    WidgetStateProperty.all(Colors.grey.shade200),
                    columns: const [
                      DataColumn(label: Text("NoSak")),
                      DataColumn(label: Text("Berat")),
                      DataColumn(label: Text("DateUsage")),
                      DataColumn(label: Text("IdLokasi")),
                      DataColumn(label: Text("Aksi")),
                    ],
                    rows: vm.details.map((d) {
                      return DataRow(cells: [
                        DataCell(Text(d.noSak.toString())),
                        DataCell(Text(d.berat?.toStringAsFixed(2) ?? "-")),
                        DataCell(Text(d.dateUsage ?? "-")),
                        DataCell(Text(d.idLokasi ?? "-")),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.orange),
                              onPressed: () =>
                                  _showDetailFormDialog(context, vm, detail: d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmDeleteDetail(context, vm, d.noSak),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailFormDialog(BuildContext context, WashingViewModel vm,
      {WashingDetail? detail}) {
    final noSakCtrl = TextEditingController(text: detail?.noSak.toString() ?? '');
    final beratCtrl =
    TextEditingController(text: detail?.berat?.toString() ?? '');
    final dateUsageCtrl =
    TextEditingController(text: detail?.dateUsage ?? '');
    final lokasiCtrl =
    TextEditingController(text: detail?.idLokasi ?? '');

    final isEdit = detail != null;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Detail' : 'Tambah Detail'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: noSakCtrl,
                    decoration: const InputDecoration(labelText: 'No Sak')),
                TextField(
                    controller: beratCtrl,
                    decoration: const InputDecoration(labelText: 'Berat'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: dateUsageCtrl,
                    decoration: const InputDecoration(labelText: 'Date Usage')),
                TextField(
                    controller: lokasiCtrl,
                    decoration: const InputDecoration(labelText: 'Id Lokasi')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                // final data = WashingDetail(
                //   noSak: int.tryParse(noSakCtrl.text) ?? 0,
                //   berat: double.tryParse(beratCtrl.text),
                //   dateUsage: dateUsageCtrl.text,
                //   idLokasi: lokasiCtrl.text,
                // );

                // if (isEdit) {
                //   vm.updateDetail(data);
                // } else {
                //   vm.createDetail(vm.selectedNoWashing!, data);
                // }

                Navigator.pop(context);
              },
              child: Text(isEdit ? "Simpan" : "Tambah"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteDetail(
      BuildContext context, WashingViewModel vm, int noSak) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Detail"),
        content: Text("Yakin ingin hapus detail NoSak $noSak?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // vm.deleteDetail(noSak);
              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }


  Widget _buildHeaderRow(
      WashingHeader item, bool isSelected, WashingViewModel vm) {
    return Container(
      color: isSelected ? Colors.blue.shade100 : null,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(item.noWashing)),
          Expanded(flex: 3, child: Text(item.namaJenisPlastik)),
          Expanded(flex: 2, child: Text(item.namaWarehouse)),
          SizedBox(
            width: 80,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showFormDialog(context, vm, header: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, item, vm),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

}
