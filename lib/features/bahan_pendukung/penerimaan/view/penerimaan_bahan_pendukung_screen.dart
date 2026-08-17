// lib/features/bahan_pendukung/penerimaan/view/penerimaan_bahan_pendukung_screen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../common/widgets/app_date_field.dart';
import '../../../../common/widgets/atlas_data_table.dart';
import '../../../../core/utils/pdf_print_service.dart';

/// Layar Penerimaan Bahan Pendukung — mengikuti standar desain fitur label
/// Broker (Atlas table + action bar). Data masih dummy lokal (belum ada
/// endpoint backend untuk bahan pendukung). "Penerimaan Baru" & "Detail"
/// dibuka sebagai dialog. Print label memanfaatkan PDF viewer yang sama
/// dengan broker (`PdfPrintService` + `PdfViewerScreen` + Bluetooth print),
/// hanya saja PDF-nya digenerate lokal karena belum ada endpoint server.
class PenerimaanBahanPendukungScreen extends StatefulWidget {
  const PenerimaanBahanPendukungScreen({super.key});

  @override
  State<PenerimaanBahanPendukungScreen> createState() =>
      _PenerimaanBahanPendukungScreenState();
}

// ── Atlas design tokens (samakan dengan fitur label broker) ────────────────
const _atlasBlue = Color(0xFF0C66E4);
const _atlasCreate = Color(0xFF00897B);
const _atlasBorder = Color(0xFFDCDFE4);
const _atlasHeaderBg = Color(0xFFF7F8F9);
const _atlasTextDark = Color(0xFF172B4D);
const _atlasTextMuted = Color(0xFF44546F);
const _atlasTextFaint = Color(0xFF6B778C);

// ── Data model dummy ────────────────────────────────────────────────────────

class _Product {
  final String kategori;
  final String nama;
  final String spesifikasi;
  const _Product(this.kategori, this.nama, this.spesifikasi);
}

class _ReceiptItem {
  final _Product product;
  final int qty;
  int printCount;
  _ReceiptItem(this.product, this.qty, {this.printCount = 0});
}

class _NewItem {
  final _Product product;
  int qty;
  _NewItem(this.product, this.qty);
}

class _ReceiptHistory {
  final String no;
  final DateTime date;
  final String supplier;
  final String note;
  final List<_ReceiptItem> items;
  const _ReceiptHistory({
    required this.no,
    required this.date,
    required this.supplier,
    required this.note,
    required this.items,
  });
}

final _dateFmt = DateFormat('dd/MM/yyyy');

const _products = <_Product>[
  _Product(
    'Pipa',
    'PIPA SS - D20 X P675 X TH0,35 MM',
    'D20 X P675 X TH0,35 MM',
  ),
  _Product('Baut', 'BAUT NP1 - D3 X P6 MM', 'D3 X P6 MM'),
  _Product(
    'Pipa',
    'PIPA SS - D25 X P370 X TH0,65 MM',
    'D25 X P370 X TH0,65 MM',
  ),
  _Product(
    'Pipa',
    'PIPA SS - D25 X P430 X TH0,65 MM',
    'D25 X P430 X TH0,65 MM',
  ),
  _Product(
    'Kotak PK',
    'KOTAK PK 3024 4TX6P - P800 X L530 X T501 MM',
    'P800 X L530 X T501 MM',
  ),
  _Product(
    'Kotak MS',
    'KOTAK MS 2802 INNER - P410 X L80 X T510 MM',
    'P410 X L80 X T510 MM',
  ),
  _Product(
    'Kotak MS',
    'KOTAK MS 2802 OUTER - P525 X L415 X T520 MM',
    'P525 X L415 X T520 MM',
  ),
  _Product(
    'Kotak PK',
    'KOTAK PK 3003 3TX6P - P712 X L405 X T510 MM',
    'P712 X L405 X T510 MM',
  ),
  _Product(
    'Kotak PK',
    'KOTAK PK 3004 4TX8P - P712 X L534 X T510 MM',
    'P712 X L534 X T510 MM',
  ),
  _Product('Kunci & Magnet', 'KUNCI LEMARI LF-303 - D16 MM', 'D16 MM'),
  _Product(
    'Kunci & Magnet',
    'MAGNET N52 - P20 X L10 X T1,7 MM',
    'P20 X L10 X T1,7 MM',
  ),
  _Product('Plat', 'PLAT PANEN PETAK - P60 X L25 MM', 'P60 X L25 MM'),
  _Product('Plat', 'PLAT PANEN OVAL - P60 X L15 MM', 'P60 X L15 MM'),
  _Product('Roda', 'RODA PUTAR PLASTIK AKTIF - D40 X T45 MM', 'D40 X T45 MM'),
  _Product('Roda', 'RODA PUTAR PUTIH REM - D40 X T45 MM', 'D40 X T45 MM'),
];

const _suppliers = <String>[
  'PT. Sumber Jaya Abadi',
  'CV. Mitra Teknik',
  'CV. Sukses Mandiri',
];

InputDecoration _fieldDecoration({String? hint, bool dense = false}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 10,
      vertical: dense ? 8 : 12,
    ),
    filled: true,
    fillColor: const Color(0xFFFAFBFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _atlasBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _atlasBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: _atlasBlue, width: 1.5),
    ),
  );
}

// ── PDF label generator (lokal, karena belum ada endpoint backend) ─────────

Future<Uint8List> _buildLabelPdf(
  List<_ReceiptItem> items,
  String no,
  DateTime date,
) async {
  final doc = pw.Document();
  const pageWidth = 80 * PdfPageFormat.mm;
  const pageHeight = 50 * PdfPageFormat.mm;
  final dateStr = _dateFmt.format(date);

  for (final item in items) {
    // Dummy payload — belum ada endpoint backend untuk barcode/label bahan
    // pendukung, jadi QR hanya mengenkode data yang sudah ada di lokal.
    final qrData = 'PBPD|$no|${item.product.nama}|${item.qty}|$dateStr';
    final qrBytes = await _buildQrPng(qrData);
    final qrImage = pw.MemoryImage(qrBytes);

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pageWidth, pageHeight),
        margin: const pw.EdgeInsets.all(10),
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    no,
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    item.product.nama,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 3,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Kategori: ${item.product.kategori}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    'Qty: ${item.qty} PCS',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    dateStr,
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 72,
              height: 72,
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Image(qrImage),
            ),
          ],
        ),
      ),
    );
  }
  return doc.save();
}

/// Render QR code ke PNG bytes lewat `QrPainter` (dart:ui), tanpa perlu
/// widget tree — sehingga bisa dipanggil langsung dari generator PDF.
Future<Uint8List> _buildQrPng(String data, {double size = 300}) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
  );
  final byteData = await painter.toImageData(size);
  return byteData!.buffer.asUint8List();
}

/// Generate label lokal lalu buka lewat PDF viewer yang sama dengan broker
/// (`PdfPrintService.previewFromBytes` → `PdfViewerScreen` → Bluetooth print).
Future<void> _printReceiptLabels(
  BuildContext context,
  List<_ReceiptItem> items,
  String no,
  DateTime date, {
  VoidCallback? onPrinted,
}) async {
  if (items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Belum ada label untuk dicetak.')),
    );
    return;
  }
  final pdfBytes = await _buildLabelPdf(items, no, date);
  if (!context.mounted) return;
  await PdfPrintService(defaultSystem: 'pps').previewFromBytes(
    context: context,
    pdfBytes: pdfBytes,
    title: no,
    onPrinted: onPrinted,
  );
}

// ── Screen ───────────────────────────────────────────────────────────────

class _PenerimaanBahanPendukungScreenState
    extends State<PenerimaanBahanPendukungScreen> {
  final _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late final List<_ReceiptHistory> _history = [
    _ReceiptHistory(
      no: 'PBPD-2026-08-0009',
      date: DateTime(2026, 8, 16),
      supplier: 'PT. Sumber Jaya Abadi',
      note: 'Penerimaan rutin',
      items: [
        _ReceiptItem(_products[0], 25),
        _ReceiptItem(_products[1], 200),
        _ReceiptItem(_products[4], 10),
        _ReceiptItem(_products[5], 8),
      ],
    ),
    _ReceiptHistory(
      no: 'PBPD-2026-08-0008',
      date: DateTime(2026, 8, 14),
      supplier: 'CV. Mitra Teknik',
      note: 'Pengiriman bahan pendukung',
      items: [
        _ReceiptItem(_products[2], 30),
        _ReceiptItem(_products[3], 20),
        _ReceiptItem(_products[8], 15),
      ],
    ),
    _ReceiptHistory(
      no: 'PBPD-2026-08-0007',
      date: DateTime(2026, 8, 12),
      supplier: 'CV. Sukses Mandiri',
      note: 'Penerimaan sesuai PO',
      items: [_ReceiptItem(_products[9], 12), _ReceiptItem(_products[11], 25)],
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _nextNo =>
      'PBPD-2026-08-${(_history.length + 10).toString().padLeft(4, '0')}';

  List<_ReceiptHistory> get _filteredHistory {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _history;
    return _history
        .where(
          (r) =>
              r.no.toLowerCase().contains(q) ||
              r.supplier.toLowerCase().contains(q) ||
              r.note.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openNewReceiptDialog() async {
    final receipt = await showDialog<_ReceiptHistory>(
      context: context,
      builder: (_) => _NewReceiptDialog(no: _nextNo),
    );
    if (receipt == null) return;
    setState(() => _history.insert(0, receipt));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Penerimaan berhasil disimpan.')),
    );
    _openDetailDialog(receipt);
  }

  void _openDetailDialog(_ReceiptHistory receipt) {
    showDialog(
      context: context,
      builder: (_) => _DetailDialog(receipt: receipt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewReceiptDialog,
        backgroundColor: _atlasCreate,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Penerimaan Baru'),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildHistoryTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final hasText = _searchCtrl.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                focusNode: _searchFocus,
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _searchFocus.unfocus(),
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari nomor penerimaan / supplier / keterangan…',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (hasText)
              IconButton(
                tooltip: 'Bersihkan',
                icon: const Icon(Icons.close_rounded, size: 20),
                color: Colors.grey.shade500,
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {});
                  _searchFocus.requestFocus();
                },
              ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: _atlasBlue,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _searchFocus.unfocus,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    final rows = _filteredHistory;
    return AtlasDataTable<_ReceiptHistory>(
      items: rows,
      onRowTap: _openDetailDialog,
      columns: [
        AtlasTableColumn<_ReceiptHistory>(
          title: 'NO. PENERIMAAN',
          flex: 2,
          cellBuilder: (context, item, rowState) => Text(
            item.no,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _atlasTextDark,
            ),
            softWrap: true,
          ),
        ),
        AtlasTableColumn<_ReceiptHistory>(
          title: 'TANGGAL',
          width: 108,
          cellBuilder: (context, item, rowState) => Text(
            _dateFmt.format(item.date),
            style: TextStyle(fontSize: 14, color: rowState.textColor),
          ),
        ),
        AtlasTableColumn<_ReceiptHistory>(
          title: 'SUPPLIER',
          flex: 2,
          cellBuilder: (context, item, rowState) => Text(
            item.supplier,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          ),
        ),
        AtlasTableColumn<_ReceiptHistory>(
          title: 'KETERANGAN',
          flex: 3,
          cellBuilder: (context, item, rowState) => Text(
            item.note,
            style: TextStyle(fontSize: 14, color: rowState.textColor),
            softWrap: true,
          ),
        ),
        AtlasTableColumn<_ReceiptHistory>(
          title: 'TOTAL ITEM',
          width: 104,
          showDivider: false,
          cellBuilder: (context, item, rowState) =>
              _Badge('${item.items.length} Jenis'),
        ),
      ],
      errorBuilder: (message) => Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}

/// Dialog input penerimaan baru — form header + daftar barang + qty,
/// mengembalikan [_ReceiptHistory] lewat Navigator.pop saat disimpan.
class _NewReceiptDialog extends StatefulWidget {
  final String no;
  const _NewReceiptDialog({required this.no});

  @override
  State<_NewReceiptDialog> createState() => _NewReceiptDialogState();
}

class _NewReceiptDialogState extends State<_NewReceiptDialog> {
  final _noteCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final List<_NewItem> _newItems = [];
  String? _supplier;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = _dateFmt.format(DateTime.now());
    _supplier = _suppliers.first;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _openProductPicker() async {
    final picked = await showDialog<_Product>(
      context: context,
      builder: (_) => const _ProductPickerDialog(),
    );
    if (picked != null) {
      setState(() => _newItems.add(_NewItem(picked, 0)));
    }
  }

  void _removeItem(int index) {
    setState(() => _newItems.removeAt(index));
  }

  void _save() {
    if (_newItems.isEmpty) {
      _showSnack('Tambahkan minimal satu barang.');
      return;
    }
    if (_newItems.any((e) => e.qty <= 0)) {
      _showSnack('Isi Qty Terima untuk semua barang.');
      return;
    }
    DateTime date;
    try {
      date = _dateFmt.parseStrict(_dateCtrl.text);
    } catch (_) {
      date = DateTime.now();
    }
    final receipt = _ReceiptHistory(
      no: widget.no,
      date: date,
      supplier: _supplier ?? _suppliers.first,
      note: _noteCtrl.text.trim().isEmpty
          ? 'Penerimaan bahan pendukung'
          : _noteCtrl.text.trim(),
      items: _newItems.map((e) => _ReceiptItem(e.product, e.qty)).toList(),
    );
    Navigator.of(context).pop(receipt);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Desain dialog mengikuti format `BrokerFormDialog` (fitur label broker):
  // Container berpadding 24 dengan header ikon+judul, form section berlatar
  // abu-abu, daftar barang dalam card putih berborder, dan tombol aksi
  // BATAL/SIMPAN bergaya sama.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _buildFormBody())),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add, color: Colors.green.shade700, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'Penerimaan Baru',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFormBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              AppDateField(
                controller: _dateCtrl,
                label: 'Tanggal',
                leadingIcon: Icons.calendar_today_outlined,
                format: _dateFmt,
                locale: const Locale('id', 'ID'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _supplier,
                decoration: _formFieldDecoration(
                  label: 'Nama Supplier',
                  icon: Icons.local_shipping_outlined,
                ),
                items: _suppliers
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _supplier = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: _formFieldDecoration(
                  label: 'Keterangan',
                  icon: Icons.notes_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Bahan Pendukung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openProductPicker,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildItemsTable(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _formFieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('BATAL', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
          child: const Text(
            'SIMPAN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    if (_newItems.isEmpty) {
      return const _EmptyBox(
        message:
            'Belum ada barang. Klik "Tambah Barang" untuk memilih bahan pendukung.',
      );
    }
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(40),
        1: FlexColumnWidth(2),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(40),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: _atlasHeaderBg),
          children: [
            _Th('No.'),
            _Th('Nama Barang'),
            _Th('UOM'),
            _Th('Qty'),
            _Th(''),
          ],
        ),
        for (int i = 0; i < _newItems.length; i++)
          TableRow(
            children: [
              _Td(Text('${i + 1}', style: const TextStyle(fontSize: 12))),
              _Td(
                Text(
                  _newItems[i].product.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const _Td(Text('PCS', style: TextStyle(fontSize: 12))),
              _Td(
                SizedBox(
                  height: 34,
                  child: TextFormField(
                    initialValue: _newItems[i].qty == 0
                        ? ''
                        : '${_newItems[i].qty}',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: _fieldDecoration(dense: true),
                    onChanged: (v) => _newItems[i].qty = int.tryParse(v) ?? 0,
                  ),
                ),
              ),
              _Td(
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFC9372C),
                  ),
                  onPressed: () => _removeItem(i),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Dialog detail penerimaan — tabel barang diterima, tiap baris punya
/// tombol cetak sendiri + badge jumlah cetak (gaya sama dengan kolom PRINT
/// pada fitur label broker).
class _DetailDialog extends StatefulWidget {
  final _ReceiptHistory receipt;
  const _DetailDialog({required this.receipt});

  @override
  State<_DetailDialog> createState() => _DetailDialogState();
}

class _DetailDialogState extends State<_DetailDialog> {
  Future<void> _printItem(_ReceiptItem item) async {
    await _printReceiptLabels(
      context,
      [item],
      widget.receipt.no,
      widget.receipt.date,
      onPrinted: () => setState(() => item.printCount++),
    );
  }

  // Desain disamakan dengan `_NewReceiptDialog` (mengikuti format
  // `BrokerFormDialog`): Container berpadding 24 dengan header ikon+judul,
  // kartu info berlatar abu-abu, daftar barang dalam card putih berborder,
  // dan tombol aksi bergaya sama.
  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(receipt),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(child: _buildBody(receipt))),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_ReceiptHistory receipt) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _atlasBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: _atlasBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Penerimaan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                receipt.no,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _atlasTextFaint,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(_ReceiptHistory receipt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.local_shipping_outlined,
                label: 'Supplier',
                value: receipt.supplier,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Tanggal',
                value: _dateFmt.format(receipt.date),
              ),
              if (receipt.note.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.notes_outlined,
                  label: 'Keterangan',
                  value: receipt.note,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Barang Diterima',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    _Badge('${receipt.items.length} Jenis'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: receipt.items.isEmpty
                    ? const _EmptyBox(message: 'Belum ada barang.')
                    : Table(
                        columnWidths: const {
                          0: FixedColumnWidth(40),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(0.8),
                          3: FlexColumnWidth(0.8),
                          4: FixedColumnWidth(90),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: _atlasHeaderBg),
                            children: [
                              _Th('No.'),
                              _Th('Nama Barang'),
                              _Th('UOM'),
                              _Th('Qty'),
                              _Th('Print'),
                            ],
                          ),
                          for (int i = 0; i < receipt.items.length; i++)
                            TableRow(
                              children: [
                                _Td(
                                  Text(
                                    '${i + 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                _Td(
                                  Text(
                                    receipt.items[i].product.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const _Td(
                                  Text('PCS', style: TextStyle(fontSize: 12)),
                                ),
                                _Td(
                                  Text(
                                    '${receipt.items[i].qty}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                _Td(
                                  _PrintButton(
                                    count: receipt.items[i].printCount,
                                    onTap: () => _printItem(receipt.items[i]),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _atlasTextFaint),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _atlasTextFaint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _atlasTextDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('TUTUP', style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _atlasTextMuted,
        ),
      ),
    );
  }
}

class _Td extends StatelessWidget {
  final Widget child;
  const _Td(this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _atlasBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _atlasBlue.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _atlasBlue,
        ),
      ),
    );
  }
}

/// Tombol cetak per barang — gaya sama dengan kolom PRINT pada
/// `BrokerHeaderTable` (badge abu-abu "-" belum pernah cetak, badge biru
/// "Nx" setelah dicetak), hanya saja di sini badge-nya juga berfungsi
/// sebagai tombol cetak.
class _PrintButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PrintButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final printed = count > 0;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: printed
              ? _atlasBlue.withValues(alpha: 0.10)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: printed
                ? _atlasBlue.withValues(alpha: 0.30)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              printed ? Icons.print_rounded : Icons.print_outlined,
              size: 13,
              color: printed ? _atlasBlue : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              printed ? '${count}x' : 'Cetak',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: printed ? _atlasBlue : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerDialog extends StatefulWidget {
  const _ProductPickerDialog();

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  final _ctrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Desain disamakan dengan dialog Penerimaan Baru & Detail (mengikuti
  // format `BrokerFormDialog`): Container berpadding 24 dengan header
  // ikon+judul, search field, daftar barang dalam card putih berborder,
  // dan tombol aksi TUTUP bergaya sama.
  @override
  Widget build(BuildContext context) {
    final filtered = _products
        .where(
          (p) => (p.nama + p.kategori + p.spesifikasi).toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(filtered)),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _atlasBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.search, color: _atlasBlue, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Bahan Pendukung',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2),
              Text(
                'Cari dan tambahkan barang ke daftar penerimaan',
                style: TextStyle(fontSize: 13, color: _atlasTextFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Pill search bar — desain sama dengan search bar di layar daftar
  // Penerimaan Bahan Pendukung.
  Widget _buildSearchBar() {
    final hasText = _ctrl.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              focusNode: _searchFocus,
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) => _searchFocus.unfocus(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari nama barang...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              tooltip: 'Bersihkan',
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey.shade500,
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
                _searchFocus.requestFocus();
              },
            ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Material(
              color: _atlasBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _searchFocus.unfocus,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<_Product> filtered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: filtered.isEmpty
                ? const _EmptyBox(message: 'Barang tidak ditemukan.')
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: _atlasTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${p.kategori} · ${p.spesifikasi}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _atlasTextFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pop(p),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Tambah'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: BorderSide(color: Colors.grey.shade400),
          ),
          child: const Text('TUTUP', style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
