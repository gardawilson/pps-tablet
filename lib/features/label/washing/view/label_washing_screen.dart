import 'package:flutter/material.dart';
import '../model/detail_item.dart'; // Import model yang sudah dipisah

class WashingFormScreen extends StatefulWidget {
  const WashingFormScreen({super.key});

  @override
  State<WashingFormScreen> createState() => _WashingFormScreenState();
}

class _WashingFormScreenState extends State<WashingFormScreen> {
  // HEADER STATE
  String? selectedPlastik;
  String? selectedWarehouse;
  String? selectedStatus;
  DateTime? selectedDate;
  String? createdNoWashing;
  int selectedMode = 0; // 0 = Mesin Washing, 1 = Bongkar Susun
  String? selectedMesin;
  String? selectedBongkar;

  // DETAIL STATE
  final noSakController = TextEditingController();
  final beratController = TextEditingController();
  final jumlahSakController = TextEditingController(); // untuk mode bundel
  bool isModeBundel = false; // mode switch: false = manual, true = bundel

  // STATE UNTUK BUTTON MANAGEMENT
  bool isEditingMode = false; // false = view mode, true = editing mode

  // LIST UNTUK MENYIMPAN DATA TABEL
  List<DetailItem> detailItems = [];

  // Fungsi untuk button "Data Baru"
  void startNewData() {
    setState(() {
      isEditingMode = true;
    });
    showSnackbar('Mode edit dimulai - Lengkapi form dan detail');
  }

  // Fungsi untuk button "Batal"
  void cancelEdit() {
    setState(() {
      // Reset semua form
      selectedPlastik = null;
      selectedWarehouse = null;
      selectedStatus = null;
      selectedDate = null;
      selectedMode = 0;
      selectedMesin = null;
      selectedBongkar = null;
      detailItems.clear();
      noSakController.clear();
      beratController.clear();
      jumlahSakController.clear();
      isEditingMode = false;
      createdNoWashing = null;
    });
    showSnackbar('Edit dibatalkan - Form direset');
  }

  // Fungsi untuk button "Print"
  void printData() {
    if (detailItems.isEmpty) {
      showSnackbar('Tidak ada data untuk dicetak');
      return;
    }
    // Simulasi print
    showSnackbar('Print berhasil - ${detailItems.length} item dicetak');
  }

  // Dummy NoWashing generator
  String generateNoWashingDummy() {
    return 'B.${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
  }

  // Fungsi untuk menambah item ke tabel
  void addDetailItem() {
    if (!isEditingMode) {
      showSnackbar('Klik "Data Baru" terlebih dahulu untuk mulai input');
      return;
    }

    if (isModeBundel) {
      // Mode Bundel
      if (beratController.text.isEmpty || jumlahSakController.text.isEmpty) {
        showSnackbar('Lengkapi Berat dan Jumlah Sak untuk mode bundel');
        return;
      }

      int jumlahSak = int.tryParse(jumlahSakController.text) ?? 0;
      if (jumlahSak <= 0) {
        showSnackbar('Jumlah sak harus lebih dari 0');
        return;
      }

      // Generate multiple items berdasarkan jumlah sak
      int currentMaxNo = 0;
      if (detailItems.isNotEmpty) {
        // Cari nomor terbesar yang ada
        for (var item in detailItems) {
          int noSak = int.tryParse(item.noSak) ?? 0;
          if (noSak > currentMaxNo) {
            currentMaxNo = noSak;
          }
        }
      }

      setState(() {
        for (int i = 1; i <= jumlahSak; i++) {
          detailItems.add(DetailItem(
            noSak: (currentMaxNo + i).toString(),
            berat: beratController.text,
          ));
        }

        // Clear form setelah menambah
        beratController.clear();
        jumlahSakController.clear();
      });

      showSnackbar('$jumlahSak sak berhasil ditambahkan ke tabel');
    } else {
      // Mode Manual
      if (noSakController.text.isEmpty || beratController.text.isEmpty) {
        showSnackbar('Lengkapi No Sak dan Berat');
        return;
      }

      setState(() {
        detailItems.add(DetailItem(
          noSak: noSakController.text,
          berat: beratController.text,
        ));

        // Clear form setelah menambah
        noSakController.clear();
        beratController.clear();
      });

      showSnackbar('Detail berhasil ditambahkan ke tabel');
    }
  }

  // Fungsi untuk menghapus item dari tabel
  void removeDetailItem(int index) {
    setState(() {
      detailItems.removeAt(index);
    });
    showSnackbar('Item berhasil dihapus');
  }

  void saveAll() {
    if (!isEditingMode) {
      showSnackbar('Tidak ada data untuk disimpan');
      return;
    }

    // Validasi header
    if (selectedPlastik == null ||
        selectedWarehouse == null ||
        selectedDate == null) {
      showSnackbar('Lengkapi semua field header');
      return;
    }

    // Validasi apakah ada detail items
    if (detailItems.isEmpty) {
      showSnackbar('Tambahkan minimal satu detail item');
      return;
    }

    // Simulasi penyimpanan
    setState(() {
      createdNoWashing = generateNoWashingDummy();
      isEditingMode = false; // Kembali ke view mode setelah simpan
    });

    showSnackbar('Header & ${detailItems.length} Detail disimpan dengan No: $createdNoWashing');
  }

  void showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Input Washing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // PANEL KIRI - HEADER
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🧾 Header', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      const Text('NoWashing : B.XXXXXXXXXX', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Jenis Plastik'),
                        value: selectedPlastik,
                        items: ['PET', 'HDPE', 'LDPE']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: isEditingMode ? (val) => setState(() => selectedPlastik = val) : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Warehouse'),
                        value: selectedWarehouse,
                        items: ['WH1', 'WH2']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: isEditingMode ? (val) => setState(() => selectedWarehouse = val) : null,
                      ),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Status'),
                        value: selectedStatus,
                        items: ['Pass', 'Good']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: isEditingMode ? (val) => setState(() => selectedStatus = val) : null,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(selectedDate == null
                            ? 'Pilih Tanggal'
                            : 'Tanggal: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          if (!isEditingMode) return;

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      // Mode Mesin Washing / Bongkar Susun
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: 0,
                                      groupValue: selectedMode,
                                      onChanged: isEditingMode ? (val) {
                                        setState(() => selectedMode = val!);
                                      } : null,
                                    ),
                                    const Text('Mesin'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedMesin,
                                  hint: const Text('Pilih Mesin'),
                                  items: ['MESIN 1', 'MESIN 2', 'MESIN 3']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (selectedMode == 0 && isEditingMode)
                                      ? (val) => setState(() => selectedMesin = val)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: 1,
                                      groupValue: selectedMode,
                                      onChanged: isEditingMode ? (val) {
                                        setState(() => selectedMode = val!);
                                      } : null,
                                    ),
                                    const Text('B. Susun'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedBongkar,
                                  hint: const Text('Pilih Menu'),
                                  items: ['Menu A', 'Menu B', 'Menu C']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (selectedMode == 1 && isEditingMode)
                                      ? (val) => setState(() => selectedBongkar = val)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // PANEL KANAN - DETAIL & TABEL
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // FORM INPUT DETAIL
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('📦 Input Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              // Toggle Switch Mode
                              Row(
                                children: [
                                  Text('Manual', style: TextStyle(
                                    color: !isModeBundel ? Colors.blue : Colors.grey,
                                    fontWeight: !isModeBundel ? FontWeight.bold : FontWeight.normal,
                                  )),
                                  Switch(
                                    value: isModeBundel,
                                    onChanged: isEditingMode ? (value) {
                                      setState(() {
                                        isModeBundel = value;
                                        // Clear semua controller saat ganti mode
                                        noSakController.clear();
                                        beratController.clear();
                                        jumlahSakController.clear();
                                      });
                                    } : null,
                                  ),
                                  Text('Bundel', style: TextStyle(
                                    color: isModeBundel ? Colors.blue : Colors.grey,
                                    fontWeight: isModeBundel ? FontWeight.bold : FontWeight.normal,
                                  )),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Form input berdasarkan mode
                          if (!isModeBundel) ...[
                            // MODE MANUAL
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: noSakController,
                                    decoration: const InputDecoration(labelText: 'No Sak'),
                                    enabled: isEditingMode,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: beratController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Berat (kg)'),
                                    enabled: isEditingMode,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: isEditingMode ? addDetailItem : null,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah'),
                                ),
                              ],
                            ),
                          ] else ...[
                            // MODE BUNDEL
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: beratController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Berat per Sak (kg)',
                                      helperText: 'Berat untuk setiap sak',
                                    ),
                                    enabled: isEditingMode,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: jumlahSakController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Jumlah Sak',
                                      helperText: 'Berapa sak yang akan dibuat',
                                    ),
                                    enabled: isEditingMode,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: isEditingMode ? addDetailItem : null,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Generate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            // Info helper untuk mode bundel
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Mode Bundel: Akan membuat beberapa sak dengan berat yang sama secara otomatis',
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TABEL DETAIL
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('📋 Daftar Detail (${detailItems.length} item)',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                if (detailItems.isNotEmpty)
                                  Text('Total Berat: ${detailItems.fold<double>(0, (sum, item) => sum + item.beratAsDouble).toStringAsFixed(1)} kg',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: detailItems.isEmpty
                                  ? const Center(
                                child: Text(
                                  'Belum ada data detail.\nTambahkan item menggunakan form di atas.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              )
                                  : SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('No Sak', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Berat (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: detailItems.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    DetailItem item = entry.value;
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(item.noSak)),
                                        DataCell(Text(item.berat)),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: isEditingMode ? () => removeDetailItem(index) : null,
                                            tooltip: 'Hapus item',
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Button Data Baru / Simpan (dinamis)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isEditingMode ? saveAll : startNewData,
                icon: Icon(isEditingMode ? Icons.save : Icons.add),
                label: Text(isEditingMode ? 'Simpan' : 'Data Baru'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  backgroundColor: isEditingMode ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Button Batal
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isEditingMode ? cancelEdit : null,
                icon: const Icon(Icons.cancel),
                label: const Text('Batal'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  backgroundColor: isEditingMode ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Button Print
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (detailItems.isNotEmpty && !isEditingMode) ? printData : null,
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  backgroundColor: (detailItems.isNotEmpty && !isEditingMode) ? Colors.purple : Colors.grey,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}