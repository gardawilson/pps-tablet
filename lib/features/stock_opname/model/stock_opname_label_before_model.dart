class StockOpnameLabelBeforeModel {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;     // sudah dinormalisasi jadi int
  final double berat;    // sudah dinormalisasi jadi double

  // ⬇️ baru: pisah lokasi
  final String? blok;    // contoh: "A", "H2", dst.
  final int? idLokasi;   // contoh: 10, 3, dst.

  StockOpnameLabelBeforeModel({
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    this.blok,
    this.idLokasi,
  });

  /// Helper: gabungkan blok + id lokasi untuk ditampilkan.
  /// - blok & id ada  -> "A10"
  /// - hanya blok     -> "A"
  /// - hanya id       -> "10"
  /// - tidak ada      -> "-"
  String get lokasiDisplay {
    final b = (blok ?? '').trim();
    final i = idLokasi;
    if (b.isEmpty && i == null) return '-';
    if (b.isNotEmpty && i != null) return '$b$i';
    if (b.isNotEmpty) return b;
    return i?.toString() ?? '-';
  }

  factory StockOpnameLabelBeforeModel.fromJson(Map<String, dynamic> json) {
    // --- nomor label & tipe ---
    final nomorLabel = (json['NomorLabel'] ?? json['nomorLabel'] ?? '').toString();
    final labelType  = (json['LabelType']  ?? json['labelType']  ?? '').toString();

    // --- jmlhSak & berat (toleran tipe) ---
    final jmlhSak = _toInt(json['JmlhSak'] ?? json['jmlhSak'] ?? 0);
    final berat   = _toDouble(json['Berat'] ?? json['berat'] ?? 0);

    // --- blok (String?) ---
    String? blok;
    final rawBlok = json['Blok'] ?? json['blok'];
    if (rawBlok != null) {
      final s = rawBlok.toString().trim();
      blok = s.isEmpty ? null : s;
    }

    // --- idLokasi (int?) ---
    int? idLokasi;
    final rawId = json['IdLokasi'] ?? json['idLokasi'] ?? json['idlokasi'];
    if (rawId == null) {
      idLokasi = null;
    } else if (rawId is int) {
      idLokasi = rawId == 0 ? null : rawId;
    } else if (rawId is num) {
      final v = rawId.toInt();
      idLokasi = v == 0 ? null : v;
    } else {
      final s = rawId.toString().trim();
      if (s.isEmpty || s == '0' || s.toLowerCase() == 'null') {
        idLokasi = null;
      } else {
        idLokasi = int.tryParse(s);
      }
    }

    return StockOpnameLabelBeforeModel(
      nomorLabel: nomorLabel,
      labelType: labelType,
      jmlhSak: jmlhSak,
      berat: berat,
      blok: blok,
      idLokasi: idLokasi,
    );
  }

  Map<String, dynamic> toJson() => {
    'NomorLabel': nomorLabel,
    'LabelType': labelType,
    'JmlhSak': jmlhSak,
    'Berat': berat,
    'Blok': blok,
    'IdLokasi': idLokasi,
  };

  // ==== utils parsing aman ====
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    if (s.isEmpty) return 0;
    return int.tryParse(s) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll(',', '.');
    if (s.isEmpty) return 0.0;
    return double.tryParse(s) ?? 0.0;
  }
}
