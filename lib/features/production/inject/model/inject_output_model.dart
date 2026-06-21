class InjectBonggolanOutputItem {
  final String noProduksi;
  final String noBonggolan;
  final int idBonggolan;
  final String namaBonggolan;
  final double berat;
  final int hasBeenPrinted;
  final DateTime? dateTimeCreate;

  const InjectBonggolanOutputItem({
    required this.noProduksi,
    required this.noBonggolan,
    required this.idBonggolan,
    required this.namaBonggolan,
    required this.berat,
    required this.hasBeenPrinted,
    this.dateTimeCreate,
  });

  bool get isPrinted => hasBeenPrinted > 0;

  factory InjectBonggolanOutputItem.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return InjectBonggolanOutputItem(
      noProduksi: j['NoProduksi']?.toString() ?? '',
      noBonggolan: j['NoBonggolan']?.toString() ?? '',
      idBonggolan: asInt(j['IdBonggolan']),
      namaBonggolan: j['NamaBonggolan']?.toString() ?? '',
      berat: asDouble(j['Berat']),
      hasBeenPrinted: asInt(j['HasBeenPrinted']),
      dateTimeCreate: DateTime.tryParse(
        j['DateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class InjectRejectOutputItem {
  final String noProduksi;
  final String noReject;
  final int idJenis;
  final String namaJenis;
  final int hasBeenPrinted;
  final double berat;
  final int? pcs;
  final DateTime? dateTimeCreate;

  const InjectRejectOutputItem({
    required this.noProduksi,
    required this.noReject,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.berat,
    this.pcs,
    this.dateTimeCreate,
  });

  bool get isPrinted => hasBeenPrinted > 0;

  factory InjectRejectOutputItem.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int? asNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return InjectRejectOutputItem(
      noProduksi: j['NoProduksi']?.toString() ?? '',
      noReject: j['NoReject']?.toString() ?? '',
      idJenis: asInt(j['IdJenis']),
      namaJenis: j['NamaJenis']?.toString() ?? '',
      hasBeenPrinted: asInt(j['HasBeenPrinted']),
      berat: asDouble(j['Berat']),
      pcs: asNullableInt(j['Pcs']),
      dateTimeCreate: DateTime.tryParse(
        j['DateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class InjectBjOutputItem {
  final String noProduksi;
  final String noBj;
  final int idJenis;
  final String namaJenis;
  final int hasBeenPrinted;
  final int pcs;
  final DateTime? dateTimeCreate;

  const InjectBjOutputItem({
    required this.noProduksi,
    required this.noBj,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.pcs,
    this.dateTimeCreate,
  });

  bool get isPrinted => hasBeenPrinted > 0;

  factory InjectBjOutputItem.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return InjectBjOutputItem(
      noProduksi: j['NoProduksi']?.toString() ?? '',
      noBj: j['NoBJ']?.toString() ?? '',
      idJenis: asInt(j['IdJenis']),
      namaJenis: j['NamaJenis']?.toString() ?? '',
      hasBeenPrinted: asInt(j['HasBeenPrinted']),
      pcs: asInt(j['Pcs']),
      dateTimeCreate: DateTime.tryParse(
        j['DateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class InjectOutputItem {
  final String noProduksi;
  final String noFurnitureWip;
  final int idJenis;
  final String namaJenis;
  final int hasBeenPrinted;
  final double berat;
  final int pcs;
  final DateTime? dateTimeCreate;

  const InjectOutputItem({
    required this.noProduksi,
    required this.noFurnitureWip,
    required this.idJenis,
    required this.namaJenis,
    required this.hasBeenPrinted,
    required this.berat,
    required this.pcs,
    this.dateTimeCreate,
  });

  bool get isPrinted => hasBeenPrinted > 0;

  factory InjectOutputItem.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return InjectOutputItem(
      noProduksi: j['NoProduksi']?.toString() ?? '',
      noFurnitureWip: j['NoFurnitureWIP']?.toString() ?? '',
      idJenis: asInt(j['IdJenis']),
      namaJenis: j['NamaJenis']?.toString() ?? '',
      hasBeenPrinted: asInt(j['HasBeenPrinted']),
      berat: asDouble(j['Berat']),
      pcs: asInt(j['Pcs']),
      dateTimeCreate: DateTime.tryParse(
        j['DateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}
