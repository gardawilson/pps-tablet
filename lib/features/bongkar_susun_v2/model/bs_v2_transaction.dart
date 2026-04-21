import 'package:intl/intl.dart';
import 'bs_v2_label_info.dart';

class BsV2SakItem {
  final int noSak;
  final double berat;

  const BsV2SakItem({required this.noSak, required this.berat});

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory BsV2SakItem.fromJson(Map<String, dynamic> j) {
    return BsV2SakItem(
      noSak: (j['noSak'] is int) ? j['noSak'] as int : int.tryParse(j['noSak']?.toString() ?? '0') ?? 0,
      berat: _d(j['berat']),
    );
  }

  Map<String, dynamic> toJson() => {'noSak': noSak, 'berat': berat};
}

class BsV2OutputLabel {
  final String? labelCode;
  final int idJenis;
  final String namaJenis;
  final double totalBerat;
  final String category;
  final List<BsV2SakItem> saks;
  final double? berat;

  const BsV2OutputLabel({
    this.labelCode,
    required this.idJenis,
    required this.namaJenis,
    required this.totalBerat,
    required this.category,
    this.saks = const [],
    this.berat,
  });

  bool get isWashing => category == 'washing';

  static String _s(dynamic v) => v?.toString() ?? '';
  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory BsV2OutputLabel.fromJson(Map<String, dynamic> j) {
    final saksRaw = (j['saks'] ?? []) as List;
    // Submit response: labelCode is noWashing (washing) or noBonggolan (bonggolan)
    final labelCode = j['labelCode'] ?? j['noWashing'] ?? j['noBonggolan'];
    // totalBerat can be totalBerat (washing) or berat (bonggolan)
    final totalBerat = _d(j['totalBerat'] ?? j['berat']);
    return BsV2OutputLabel(
      labelCode: labelCode == null ? null : _s(labelCode),
      idJenis: (j['idJenis'] is int) ? j['idJenis'] as int : int.tryParse(j['idJenis']?.toString() ?? '0') ?? 0,
      namaJenis: _s(j['namaJenis']),
      totalBerat: totalBerat,
      category: _s(j['category']),
      saks: saksRaw.map((e) => BsV2SakItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      berat: j['berat'] == null ? null : _d(j['berat']),
    );
  }
}

class BsV2Transaction {
  final String noBongkarSusun;
  final DateTime? tanggal;
  final String? note;
  final String? username;
  final String? category;
  final List<BsV2LabelInfo> inputs;
  final List<BsV2OutputLabel> outputs;

  const BsV2Transaction({
    required this.noBongkarSusun,
    this.tanggal,
    this.note,
    this.username,
    this.category,
    this.inputs = const [],
    this.outputs = const [],
  });

  static String _s(dynamic v) => v?.toString() ?? '';
  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory BsV2Transaction.fromJson(Map<String, dynamic> j) {
    final inputsRaw = (j['inputs'] ?? j['Inputs'] ?? []) as List;
    final outputsRaw = (j['outputs'] ?? j['Outputs'] ?? []) as List;
    final noteRaw = j['note'] ?? j['Note'];
    final categoryRaw = _s(j['category'] ?? j['Category']);

    // inputs can be List<String> (submit response) or List<Map> (detail response)
    final inputs = inputsRaw.map<BsV2LabelInfo>((e) {
      if (e is String) {
        return BsV2LabelInfo(
          labelCode: e,
          category: categoryRaw,
          idJenis: 0,
          namaJenis: '',
          totalBerat: 0,
        );
      }
      return BsV2LabelInfo.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();

    return BsV2Transaction(
      noBongkarSusun: _s(j['noBongkarSusun'] ?? j['NoBongkarSusun']),
      tanggal: _dt(j['tanggal'] ?? j['Tanggal']),
      note: noteRaw == null || noteRaw.toString().trim().isEmpty ? null : _s(noteRaw),
      username: j['username'] != null ? _s(j['username']) : (j['Username'] != null ? _s(j['Username']) : null),
      category: categoryRaw.isEmpty ? null : categoryRaw,
      inputs: inputs,
      outputs: outputsRaw.map((e) => BsV2OutputLabel.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  String get tanggalText {
    if (tanggal == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal!.toLocal());
  }

  bool get isWashing => category == 'washing';

  String get categoryLabel {
    if (category != null) return isWashing ? 'Washing' : 'Bonggolan';
    if (inputs.isEmpty) return '-';
    return inputs.first.isWashing ? 'Washing' : 'Bonggolan';
  }
}
