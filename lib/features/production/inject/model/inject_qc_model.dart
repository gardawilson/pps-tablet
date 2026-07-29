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
