class LabelDetailModel {
  final String? labelType;
  final String? nomorLabel;
  final String? namaJenisPlastik;
  final String? namaWarehouse;
  final String? keterangan;
  final double? berat;
  final int? jumlahSak;
  final double? totalBerat;
  final double? moisture;
  final double? meltingIndex;
  final double? elasticity;
  final bool? tenggelam;
  final String? namaCrusher;
  final String? namaBonggolan;
  final String? namaGilingan;
  final String? namaMixer;
  final String? namaFurnitureWIP;
  final String? namaBJ;
  final String? namaReject;
  final int? pcs;
  final bool? isPartial;
  final String? dateCreate;
  final String? idLokasi;

  LabelDetailModel({
    this.labelType,
    this.nomorLabel,
    this.namaJenisPlastik,
    this.namaWarehouse,
    this.keterangan,
    this.berat,
    this.jumlahSak,
    this.totalBerat,
    this.moisture,
    this.meltingIndex,
    this.elasticity,
    this.tenggelam,
    this.namaCrusher,
    this.namaBonggolan,
    this.namaGilingan,
    this.namaMixer,
    this.namaFurnitureWIP,
    this.namaBJ,
    this.namaReject,
    this.pcs,
    this.isPartial,
    this.dateCreate,
    this.idLokasi,
  });

  factory LabelDetailModel.fromJson(Map<String, dynamic> json) {
    return LabelDetailModel(
      labelType: json['LabelType'],
      nomorLabel: json['NomorLabel'],
      namaJenisPlastik: json['NamaJenisPlastik'],
      namaWarehouse: json['NamaWarehouse'],
      keterangan: json['Keterangan'],
      berat: (json['Berat'] as num?)?.toDouble() ??
          (json['TotalBerat'] as num?)?.toDouble(),
      jumlahSak: (json['JumlahSak'] as num?)?.toInt(),
      totalBerat: (json['TotalBerat'] as num?)?.toDouble(),
      moisture: (json['Moisture'] as num?)?.toDouble(),
      meltingIndex: (json['MeltingIndex'] as num?)?.toDouble(),
      elasticity: (json['Elasticity'] as num?)?.toDouble(),
      tenggelam: json['Tenggelam'] != null ? json['Tenggelam'] == 1 : null,
      namaCrusher: json['NamaCrusher'],
      namaBonggolan: json['NamaBonggolan'],
      namaGilingan: json['NamaGilingan'],
      namaMixer: json['NamaMixer'],
      namaFurnitureWIP: json['Nama'],
      namaBJ: json['NamaBJ'],
      namaReject: json['NamaReject'],
      pcs: (json['Pcs'] as num?)?.toInt(),
      isPartial: json['IsPartial'] != null
          ? (json['IsPartial'] == true || json['IsPartial'] == 1)
          : null,
      dateCreate: json['DateCreate'],
      idLokasi: json['IdLokasi'],
    );
  }
}
