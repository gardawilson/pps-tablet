class MappingLokasi {
  final int idLokasi;
  final String blok;
  final String description;
  final String namaJenis;
  final bool enable;
  final String label;
  final int idKategori;
  final int idJenis;
  final int? idUOM;
  final String namaUOM;
  final int totalLabel;
  final int totalQty;
  final double totalBerat;

  MappingLokasi({
    required this.idLokasi,
    required this.blok,
    required this.description,
    required this.namaJenis,
    required this.enable,
    required this.label,
    this.idKategori = 0,
    this.idJenis = 0,
    this.idUOM,
    this.namaUOM = '',
    this.totalLabel = 0,
    this.totalQty = 0,
    this.totalBerat = 0,
  });

  factory MappingLokasi.fromJson(Map<String, dynamic> json) {
    final rawId = json['IdLokasi'];
    final rawEnable = json['Enable'];

    return MappingLokasi(
      idLokasi: rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '') ?? 0,
      blok: (json['Blok'] ?? '').toString(),
      description: (json['Description'] ?? '').toString(),
      namaJenis: (json['NamaJenis'] ?? '').toString(),
      enable: rawEnable is bool
          ? rawEnable
          : rawEnable?.toString().toLowerCase() == 'true',
      label: '${(json['Blok'] ?? '').toString()}${rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '') ?? 0}',
      idKategori: (json['IdKategori'] as num?)?.toInt() ?? 0,
      idJenis: (json['IdJenis'] as num?)?.toInt() ?? 0,
      idUOM: (json['IdUOM'] as num?)?.toInt(),
      namaUOM: (json['NamaUOM'] ?? '').toString(),
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
