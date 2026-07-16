class LokasiJenis {
  final int idKategori;
  final int idJenis;
  final String kodeKategori;
  final String namaKategori;
  final String namaJenis;
  final int? idUOM;
  final String namaUOM;

  LokasiJenis({
    required this.idKategori,
    required this.idJenis,
    this.kodeKategori = '',
    this.namaKategori = '',
    this.namaJenis = '',
    this.idUOM,
    this.namaUOM = '',
  });

  factory LokasiJenis.fromJson(Map<String, dynamic> json) => LokasiJenis(
        idKategori: (json['IdKategori'] as num?)?.toInt() ?? 0,
        idJenis: (json['IdJenis'] as num?)?.toInt() ?? 0,
        kodeKategori: (json['KodeKategori'] ?? '').toString(),
        namaKategori: (json['NamaKategori'] ?? '').toString(),
        namaJenis: (json['NamaJenis'] ?? '').toString(),
        idUOM: (json['IdUOM'] as num?)?.toInt(),
        namaUOM: (json['NamaUOM'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'IdKategori': idKategori,
        'IdJenis': idJenis,
      };
}

class MappingLokasi {
  final int idLokasi;
  final String blok;
  final String description;
  final bool enable;
  final String label;
  final List<LokasiJenis> jenisList;
  final int totalLabel;
  final int totalQty;
  final double totalBerat;

  MappingLokasi({
    required this.idLokasi,
    required this.blok,
    required this.description,
    required this.enable,
    required this.label,
    this.jenisList = const [],
    this.totalLabel = 0,
    this.totalQty = 0,
    this.totalBerat = 0,
  });

  // Ringkasan nama jenis untuk tampilan singkat (gabungan semua jenis).
  String get namaJenis =>
      jenisList.map((j) => j.namaJenis).where((s) => s.isNotEmpty).join(', ');

  // UOM ditampilkan dari entry pertama yang punya nilai (lokasi bisa punya beberapa jenis dgn UOM berbeda).
  String get namaUOM => jenisList.firstWhere(
        (j) => j.namaUOM.isNotEmpty,
        orElse: () => LokasiJenis(idKategori: 0, idJenis: 0),
      ).namaUOM;

  factory MappingLokasi.fromJson(Map<String, dynamic> json) {
    final rawId = json['IdLokasi'];
    final rawEnable = json['Enable'];
    final rawJenisList = json['JenisList'];

    return MappingLokasi(
      idLokasi: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      blok: (json['Blok'] ?? '').toString(),
      description: (json['Description'] ?? '').toString(),
      enable: rawEnable is bool
          ? rawEnable
          : rawEnable?.toString().toLowerCase() == 'true',
      label: '${(json['Blok'] ?? '').toString()}${rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '') ?? 0}',
      jenisList: rawJenisList is List
          ? rawJenisList
              .map((e) => LokasiJenis.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      totalLabel: (json['TotalLabel'] as num?)?.toInt() ?? 0,
      totalQty: (json['TotalQty'] as num?)?.toInt() ?? 0,
      totalBerat: (json['TotalBerat'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MasterKategori {
  final int idKategori;
  final String namaKategori;

  MasterKategori({required this.idKategori, required this.namaKategori});

  factory MasterKategori.fromJson(Map<String, dynamic> json) => MasterKategori(
        idKategori: (json['IdKategori'] as num).toInt(),
        namaKategori: (json['NamaKategori'] ?? '').toString(),
      );
}

class MasterJenis {
  final int idJenis;
  final String namaJenis;

  MasterJenis({required this.idJenis, required this.namaJenis});

  factory MasterJenis.fromJson(Map<String, dynamic> json) => MasterJenis(
        idJenis: (json['IdJenis'] as num).toInt(),
        namaJenis: (json['NamaJenis'] ?? '').toString(),
      );
}
