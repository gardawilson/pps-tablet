// lib/features/gilingan/model/gilingan_header_model.dart

class GilinganHeader {
  // Core
  final String noGilingan;     // NoGilingan
  final String dateCreate;     // DateCreate (ISO/string dari API)
  final int idGilingan;        // IdGilingan
  final String? namaGilingan;  // NamaGilingan (join MstGilingan)
  final String? blok;          // Blok
  final String? idLokasi;      // IdLokasi (stringified)
  final double? berat;         // Berat (sudah dikurangi partial sesuai service)
  final int idStatus;          // IdStatus (0 / 1)
  final int isPartial;         // IsPartial (0 / 1)
  final String statusText;     // PASS/HOLD

  // Join ke produksi
  final String? gilinganNoProduksi; // dari GilinganProduksiOutput.NoProduksi
  final String? gilinganNamaMesin;  // dari MstMesin.NamaMesin via GilinganProduksi_h
  final String? noBongkarSusun;     // dari BongkarSusunOutputGilingan.NoBongkarSusun

  const GilinganHeader({
    required this.noGilingan,
    required this.dateCreate,
    required this.idGilingan,
    this.namaGilingan,
    this.blok,
    this.idLokasi,
    this.berat,
    required this.idStatus,
    required this.isPartial,
    this.statusText = '',
    this.gilinganNoProduksi,
    this.gilinganNamaMesin,
    this.noBongkarSusun,
  });

  // Convenience getters (optional, buat dipakai UI)
  bool get isPartialBool => isPartial == 1;
  bool get isPass => idStatus == 1;

  String? get refNoProduksi => gilinganNoProduksi;
  String? get refNamaMesin  => gilinganNamaMesin;

  factory GilinganHeader.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;

      // 👉 handle boolean dari API: true/false
      if (v is bool) {
        return v ? 1 : 0;
      }

      if (v is num) return v.toInt();

      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true') return 1;
        if (lower == 'false') return 0;
        return int.tryParse(v) ?? 0;
      }

      return 0;
    }

    return GilinganHeader(
      noGilingan: json['NoGilingan'] ?? '',
      dateCreate: json['DateCreate'] ?? '',
      idGilingan: _toInt(json['IdGilingan']),
      namaGilingan: json['NamaGilingan'],
      blok: json['Blok'],
      idLokasi: json['IdLokasi']?.toString(),
      berat: _toDouble(json['Berat']),
      idStatus: _toInt(json['IdStatus']),
      isPartial: _toInt(json['IsPartial']),
      statusText: (json['StatusText'] ?? '').toString(),

      gilinganNoProduksi: json['GilinganNoProduksi'],
      gilinganNamaMesin: json['GilinganNamaMesin'],
      noBongkarSusun: json['NoBongkarSusun'],
    );
  }

  Map<String, dynamic> toJson() => {
    'NoGilingan': noGilingan,
    'DateCreate': dateCreate,
    'IdGilingan': idGilingan,
    'NamaGilingan': namaGilingan,
    'Blok': blok,
    'IdLokasi': idLokasi,
    'Berat': berat,
    'IdStatus': idStatus,
    'IsPartial': isPartial,
    'StatusText': statusText,
    'GilinganNoProduksi': gilinganNoProduksi,
    'GilinganNamaMesin': gilinganNamaMesin,
    'NoBongkarSusun': noBongkarSusun,
  };

  GilinganHeader copyWith({
    String? noGilingan,
    String? dateCreate,
    int? idGilingan,
    String? namaGilingan,
    String? blok,
    String? idLokasi,
    double? berat,
    int? idStatus,
    int? isPartial,
    String? statusText,
    String? gilinganNoProduksi,
    String? gilinganNamaMesin,
    String? noBongkarSusun,
  }) {
    return GilinganHeader(
      noGilingan: noGilingan ?? this.noGilingan,
      dateCreate: dateCreate ?? this.dateCreate,
      idGilingan: idGilingan ?? this.idGilingan,
      namaGilingan: namaGilingan ?? this.namaGilingan,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      berat: berat ?? this.berat,
      idStatus: idStatus ?? this.idStatus,
      isPartial: isPartial ?? this.isPartial,
      statusText: statusText ?? this.statusText,
      gilinganNoProduksi:
      gilinganNoProduksi ?? this.gilinganNoProduksi,
      gilinganNamaMesin:
      gilinganNamaMesin ?? this.gilinganNamaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
    );
  }
}
