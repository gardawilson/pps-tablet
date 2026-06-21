class InjectPcsPerLabelResult {
  final int idFurnitureWIP;
  final String namaBarang;
  final int pcsPerLabel;

  const InjectPcsPerLabelResult({
    required this.idFurnitureWIP,
    required this.namaBarang,
    required this.pcsPerLabel,
  });

  factory InjectPcsPerLabelResult.fromJson(Map<String, dynamic> j) {
    return InjectPcsPerLabelResult(
      idFurnitureWIP: (j['idFurnitureWIP'] as num?)?.toInt() ?? 0,
      namaBarang: j['namaBarang']?.toString() ?? '',
      pcsPerLabel: (j['pcsPerLabel'] as num?)?.toInt() ?? 100,
    );
  }
}

class InjectBatchLabels {
  final List<String> furnitureWip;
  final List<String> bonggolan;
  final List<String> reject;

  const InjectBatchLabels({
    required this.furnitureWip,
    required this.bonggolan,
    required this.reject,
  });

  factory InjectBatchLabels.fromJson(Map<String, dynamic> j) {
    List<String> asList(dynamic v) =>
        (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return InjectBatchLabels(
      furnitureWip: asList(j['furnitureWip']),
      bonggolan: asList(j['bonggolan']),
      reject: asList(j['reject']),
    );
  }

  static const empty = InjectBatchLabels(
    furnitureWip: [],
    bonggolan: [],
    reject: [],
  );
}

class InjectBatchItem {
  final int id;
  final String noProduksi;
  final String hourStart;
  final int carryOverIn;
  final int pcsInput;
  final int carryOverOut;
  final double? berat;
  final double? cycleTime;
  final int? counter;
  final DateTime? dateTimeCreate;
  final InjectBatchLabels labels;

  const InjectBatchItem({
    required this.id,
    required this.noProduksi,
    required this.hourStart,
    required this.carryOverIn,
    required this.pcsInput,
    required this.carryOverOut,
    this.berat,
    this.cycleTime,
    this.counter,
    this.dateTimeCreate,
    this.labels = InjectBatchLabels.empty,
  });

  factory InjectBatchItem.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

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

    final labelsRaw = j['labels'];
    final labels = labelsRaw is Map<String, dynamic>
        ? InjectBatchLabels.fromJson(labelsRaw)
        : InjectBatchLabels.empty;

    return InjectBatchItem(
      id: asInt(j['id']),
      noProduksi: j['noProduksi']?.toString() ?? '',
      hourStart: j['hourStart']?.toString() ?? '',
      carryOverIn: asInt(j['carryOverIn']),
      pcsInput: asInt(j['pcsInput']),
      carryOverOut: asInt(j['carryOverOut']),
      berat: asNullableDouble(j['berat']),
      cycleTime: asNullableDouble(j['cycleTime']),
      counter: asNullableInt(j['counter']),
      dateTimeCreate: DateTime.tryParse(
        j['dateTimeCreate']?.toString() ?? '',
      )?.toLocal(),
      labels: labels,
    );
  }
}

class InjectBatchSubmitResult {
  final int batchId;
  final String hourStart;
  final List<String> furnitureWIP;
  final String? bonggolan;
  final String? reject;

  const InjectBatchSubmitResult({
    required this.batchId,
    required this.hourStart,
    required this.furnitureWIP,
    this.bonggolan,
    this.reject,
  });

  factory InjectBatchSubmitResult.fromJson(Map<String, dynamic> j) {
    final batch = (j['batch'] as Map<String, dynamic>?) ?? {};
    final fwipRaw = (j['furnitureWIP'] as List<dynamic>?) ?? [];
    return InjectBatchSubmitResult(
      batchId: (batch['id'] as num?)?.toInt() ?? 0,
      hourStart: batch['hourStart']?.toString() ?? '',
      furnitureWIP: fwipRaw.map((e) => e.toString()).toList(),
      bonggolan: j['bonggolan']?.toString(),
      reject: j['reject']?.toString(),
    );
  }
}
