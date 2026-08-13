/// Kode kategori item Retur v3 — sesuai kontrak backend
/// (`kodeKategori`: 'barangjadi' | 'furniturewip').
class ReturV3Kategori {
  static const barangJadi = 'barangjadi';
  static const furnitureWip = 'furniturewip';
}

/// Input kategori pilihan user saat menambah item — 'BAGUS' | 'REJECT'.
class ReturV3KategoriInput {
  static const bagus = 'BAGUS';
  static const reject = 'REJECT';
}

class ReturV3Item {
  final int idItem;
  final String kodeKategori;
  final int idJenis;
  final String? namaJenis;
  final int pcs;
  final String kategoriInput;
  final double? berat;
  final int? idReject;
  final String? namaReject;
  final String? generatedLabelCode;

  const ReturV3Item({
    required this.idItem,
    required this.kodeKategori,
    required this.idJenis,
    this.namaJenis,
    required this.pcs,
    required this.kategoriInput,
    this.berat,
    this.idReject,
    this.namaReject,
    this.generatedLabelCode,
  });

  bool get isBagus => kategoriInput.toUpperCase() == ReturV3KategoriInput.bagus;
  bool get isReject =>
      kategoriInput.toUpperCase() == ReturV3KategoriInput.reject;
  bool get isBarangJadi => kodeKategori == ReturV3Kategori.barangJadi;
  bool get isFurnitureWip => kodeKategori == ReturV3Kategori.furnitureWip;
  bool get hasGeneratedLabel =>
      generatedLabelCode != null && generatedLabelCode!.trim().isNotEmpty;

  static String _s(dynamic v) => v?.toString() ?? '';
  static dynamic _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k) && j[k] != null) return j[k];
    }
    return null;
  }

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _iOpt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _dOpt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory ReturV3Item.fromJson(Map<String, dynamic> j) {
    return ReturV3Item(
      idItem: _i(_pick(j, ['idItem', 'IdItem', 'id'])),
      kodeKategori: _s(
        _pick(j, ['kodeKategori', 'KodeKategori']),
      ).toLowerCase(),
      idJenis: _i(_pick(j, ['idJenis', 'IdJenis'])),
      namaJenis: _pick(j, ['namaJenis', 'NamaJenis'])?.toString(),
      pcs: _i(_pick(j, ['pcs', 'Pcs'])),
      kategoriInput: _s(
        _pick(j, ['kategoriInput', 'KategoriInput']),
      ).toUpperCase(),
      berat: _dOpt(_pick(j, ['berat', 'Berat'])),
      idReject: _iOpt(_pick(j, ['idReject', 'IdReject'])),
      namaReject: _pick(j, ['namaReject', 'NamaReject'])?.toString(),
      generatedLabelCode: _pick(j, [
        'generatedLabelCode',
        'GeneratedLabelCode',
        'labelCode',
        'LabelCode',
      ])?.toString(),
    );
  }
}
