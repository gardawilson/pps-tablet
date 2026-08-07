class InjectQcItem {
  final int id;
  final String noProduksi;
  final String hourStart;
  final int jumlahBS;
  final double? cycleTime;
  final int? counter;
  final double? berat;
  final String? keterangan;
  final bool isDowntime;
  final DateTime? dateTimeCreate;

  const InjectQcItem({
    required this.id,
    required this.noProduksi,
    required this.hourStart,
    required this.jumlahBS,
    this.cycleTime,
    this.counter,
    this.berat,
    this.keterangan,
    this.isDowntime = false,
    this.dateTimeCreate,
  });

  factory InjectQcItem.fromJson(Map<String, dynamic> j) {
    double? asNullableDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? asNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return InjectQcItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      noProduksi: j['noProduksi']?.toString() ?? '',
      hourStart: j['hourStart']?.toString() ?? '',
      jumlahBS: asNullableInt(j['jumlahBS']) ?? 0,
      cycleTime: asNullableDouble(j['cycleTime']),
      counter: asNullableInt(j['counter']),
      berat: asNullableDouble(j['berat']),
      keterangan: j['keterangan']?.toString(),
      isDowntime: j['isDowntime'] == true,
      dateTimeCreate: DateTime.tryParse(
        j['dateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class InjectQcHeader {
  final String noProduksi;
  final DateTime? tglProduksi;
  // Timestamp server saat header ini dibuat — dipakai sebagai acuan tanggal
  // "current" untuk perhitungan bucket jam QC, karena tglProduksi hanya
  // mencatat tanggal mulai shift (bisa beda hari dengan jam-jam setelah
  // tengah malam pada shift yang melewati tengah malam).
  final DateTime? createdAt;

  const InjectQcHeader({
    required this.noProduksi,
    this.tglProduksi,
    this.createdAt,
  });

  factory InjectQcHeader.fromJson(Map<String, dynamic> j) {
    return InjectQcHeader(
      noProduksi: j['noProduksi']?.toString() ?? '',
      tglProduksi: DateTime.tryParse(
        j['tglProduksi']?.toString() ?? '',
      )?.toLocal(),
      createdAt: DateTime.tryParse(
        j['createdAt']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

/// Satu window jam QC (mis. "13:00 - 14:00"), dihitung backend dari
/// tglProduksi + hourStart/hourEnd produksi asli — bukan ditebak dari jam
/// device seperti versi lama. `opensAt`/`closesAt` dikirim sebagai string
/// naive tanpa offset/"Z" (mis. "2026-07-27T14:00:00") supaya `DateTime.parse`
/// membacanya apa adanya sebagai local time, tanpa konversi timezone —
/// kebenaran "sekarang" tetap dari jam device, backend hanya menentukan
/// tanggal & jam kalender yang benar untuk tiap bucket (menghindari
/// ketidakcocokan timezone server vs tablet).
class InjectQcBucket {
  final String label;
  final String hourStart;
  final String hourEnd;
  final DateTime opensAt;
  final DateTime closesAt;

  const InjectQcBucket({
    required this.label,
    required this.hourStart,
    required this.hourEnd,
    required this.opensAt,
    required this.closesAt,
  });

  static InjectQcBucket? fromJson(Map<String, dynamic> j) {
    final opensAt = DateTime.tryParse(j['opensAt']?.toString() ?? '');
    final closesAt = DateTime.tryParse(j['closesAt']?.toString() ?? '');
    if (opensAt == null || closesAt == null) return null;
    return InjectQcBucket(
      label: j['label']?.toString() ?? '',
      hourStart: j['hourStart']?.toString() ?? '',
      hourEnd: j['hourEnd']?.toString() ?? '',
      opensAt: opensAt,
      closesAt: closesAt,
    );
  }
}

class InjectQcDetail {
  final InjectQcHeader header;
  final List<InjectQcItem> items;
  final List<InjectQcBucket> buckets;

  const InjectQcDetail({
    required this.header,
    required this.items,
    this.buckets = const [],
  });

  factory InjectQcDetail.fromJson(Map<String, dynamic> j) {
    final headerJson = j['header'] as Map<String, dynamic>? ?? {};
    final itemsJson = j['items'] as List<dynamic>? ?? [];
    final bucketsJson = j['buckets'] as List<dynamic>? ?? [];
    return InjectQcDetail(
      header: InjectQcHeader.fromJson(headerJson),
      items: itemsJson
          .whereType<Map>()
          .map((e) => InjectQcItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      buckets: bucketsJson
          .whereType<Map>()
          .map((e) => InjectQcBucket.fromJson(Map<String, dynamic>.from(e)))
          .whereType<InjectQcBucket>()
          .toList(),
    );
  }
}
