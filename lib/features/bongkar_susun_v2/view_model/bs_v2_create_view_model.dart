import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../model/bs_v2_label_info.dart';
import '../model/bs_v2_transaction.dart';
import '../repository/bs_v2_repository.dart';

class SakEntry {
  final String id;
  int noSak;
  double berat;

  SakEntry({required this.id, required this.noSak, this.berat = 0.0});
}

class OutputEntry {
  final String id;
  int idJenis;
  String namaJenis;
  List<SakEntry> saks; // washing only
  double berat; // bonggolan only

  OutputEntry({
    required this.id,
    required this.idJenis,
    required this.namaJenis,
    List<SakEntry>? saks,
    this.berat = 0.0,
  }) : saks = saks ?? [];

  double get totalBerat {
    if (saks.isNotEmpty) {
      return saks.fold(0.0, (s, e) => s + e.berat);
    }
    return berat;
  }
}

class BsV2CreateViewModel extends ChangeNotifier {
  final BsV2Repository repository;

  BsV2CreateViewModel({BsV2Repository? repository})
    : repository = repository ?? BsV2Repository();

  // === Input state ===
  final List<BsV2LabelInfo> inputs = [];
  bool isLookingUp = false;
  String? lookupError;

  // === Output state ===
  final List<OutputEntry> outputs = [];

  // === Form state ===
  String note = '';
  bool isSubmitting = false;
  String? submitError;
  BsV2Transaction? lastResult;

  // === Derived ===
  String? get category => inputs.isEmpty ? null : inputs.first.category;
  bool get isWashing => category == 'washing';
  bool get isBroker => category == 'broker';
  bool get isBonggolan => category == 'bonggolan';
  bool get isCrusher => category == 'crusher';
  bool get isGilingan => category == 'gilingan';
  bool get isMixer => category == 'mixer';
  bool get isFurnitureWip => category == 'furnitureWip';
  bool get isBarangJadi => category == 'barangJadi';
  bool get isBahanBaku => category == 'bahanBaku';
  bool get isPcsCategory => isFurnitureWip || isBarangJadi;
  String get quantityUnit => isPcsCategory ? 'pcs' : 'kg';

  /// Categories that use saks structure (washing, broker, mixer, bahanBaku)
  bool get hasSaks => isWashing || isBroker || isMixer || isBahanBaku;

  /// Unique jenis options derived from scanned inputs
  List<({int idJenis, String namaJenis})> get jenisOptions {
    final seen = <int>{};
    final result = <({int idJenis, String namaJenis})>[];
    for (final lbl in inputs) {
      if (seen.add(lbl.idJenis)) {
        result.add((idJenis: lbl.idJenis, namaJenis: lbl.namaJenis));
      }
    }
    return result;
  }

  /// Total berat input per idJenis
  Map<int, double> get inputBeratByJenis {
    final m = <int, double>{};
    for (final lbl in inputs) {
      m[lbl.idJenis] = (m[lbl.idJenis] ?? 0.0) + lbl.totalBerat;
    }
    return m;
  }

  /// Total berat output per idJenis (from output entries)
  Map<int, double> get outputBeratByJenis {
    final m = <int, double>{};
    for (final out in outputs) {
      m[out.idJenis] = (m[out.idJenis] ?? 0.0) + out.totalBerat;
    }
    return m;
  }

  /// Remaining berat to allocate per idJenis (input - output)
  Map<int, double> get remainingByJenis {
    final m = <int, double>{};
    for (final entry in inputBeratByJenis.entries) {
      final allocated = outputBeratByJenis[entry.key] ?? 0.0;
      m[entry.key] = entry.value - allocated;
    }
    return m;
  }

  /// True if an output entry has ≥1 sak with berat > 0 (saks-based) or berat > 0 (bonggolan)
  bool outputIsValid(OutputEntry out) {
    if (hasSaks)
      return out.saks.isNotEmpty && out.saks.every((s) => s.berat > 0);
    return out.berat > 0;
  }

  bool get allOutputsValid =>
      outputs.isNotEmpty && outputs.every(outputIsValid);

  /// True when all jenis are fully allocated (remaining == 0) and every output is valid
  bool get isBalanced {
    if (inputs.isEmpty) return false;
    if (outputs.isEmpty) return false;
    if (!allOutputsValid) return false;
    for (final rem in remainingByJenis.values) {
      if (rem.abs() > 0.001) return false;
    }
    return true;
  }

  // === Actions ===

  Future<void> lookupLabel(String labelCode) async {
    final code = labelCode.trim();
    if (code.isEmpty) return;

    // Duplicate check
    if (inputs.any((l) => l.labelCode == code)) {
      lookupError = 'Label $code sudah ditambahkan';
      notifyListeners();
      return;
    }

    isLookingUp = true;
    lookupError = null;
    notifyListeners();

    try {
      final info = await repository.fetchLabelInfo(code);

      // Category consistency check
      if (inputs.isNotEmpty && info.category != category) {
        lookupError =
            'Semua label harus kategori sama '
            '(${_categoryLabel(category!)} vs ${_categoryLabel(info.category)})';
        return;
      }

      // Bahan Baku: semua label harus memiliki noBahanBaku yang sama
      if (info.isBahanBaku && inputs.isNotEmpty) {
        final existingNo = inputs.first.noBahanBaku;
        if (existingNo != null &&
            info.noBahanBaku != null &&
            info.noBahanBaku != existingNo) {
          lookupError =
              'Label bahan baku harus dari nomor yang sama '
              '($existingNo). Label ${info.labelCode} tidak diizinkan.';
          return;
        }
      }

      inputs.add(info);
    } catch (e) {
      lookupError = apiErrorMessage(e);
    } finally {
      isLookingUp = false;
      notifyListeners();
    }
  }

  void removeInput(String labelCode) {
    inputs.removeWhere((l) => l.labelCode == labelCode);
    if (inputs.isEmpty) outputs.clear();
    notifyListeners();
  }

  void addOutput() {
    if (jenisOptions.isEmpty) return;
    final first = jenisOptions.first;
    final id = '${DateTime.now().millisecondsSinceEpoch}_${outputs.length}';
    final entry = OutputEntry(
      id: id,
      idJenis: first.idJenis,
      namaJenis: first.namaJenis,
    );
    if (hasSaks) {
      entry.saks.add(SakEntry(id: '${id}_sak_0', noSak: 1, berat: 0.0));
    }
    outputs.add(entry);
    notifyListeners();
  }

  void removeOutput(String outputId) {
    outputs.removeWhere((o) => o.id == outputId);
    notifyListeners();
  }

  void updateOutputJenis(String outputId, int idJenis, String namaJenis) {
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    out.idJenis = idJenis;
    out.namaJenis = namaJenis;
    notifyListeners();
  }

  void updateOutputBerat(String outputId, double berat) {
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    out.berat = berat;
    notifyListeners();
  }

  void addSak(String outputId) {
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    final nextNo = out.saks.isEmpty
        ? 1
        : out.saks.map((s) => s.noSak).reduce((a, b) => a > b ? a : b) + 1;
    out.saks.add(
      SakEntry(
        id: '${outputId}_sak_${out.saks.length}',
        noSak: nextNo,
        berat: 0.0,
      ),
    );
    notifyListeners();
  }

  void addSakBulk(String outputId, int count, double beratPerSak) {
    if (count <= 0) return;
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    final nextNo = out.saks.isEmpty
        ? 1
        : out.saks.map((s) => s.noSak).reduce((a, b) => a > b ? a : b) + 1;
    final base = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < count; i++) {
      out.saks.add(
        SakEntry(
          id: '${outputId}_sak_bulk_${base}_$i',
          noSak: nextNo + i,
          berat: beratPerSak,
        ),
      );
    }
    notifyListeners();
  }

  void removeSak(String outputId, String sakId) {
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    out.saks.removeWhere((s) => s.id == sakId);
    for (int i = 0; i < out.saks.length; i++) {
      out.saks[i].noSak = i + 1;
    }
    notifyListeners();
  }

  void updateSak(String outputId, String sakId, {int? noSak, double? berat}) {
    final out = outputs.firstWhere(
      (o) => o.id == outputId,
      orElse: () => throw StateError('not found'),
    );
    final sak = out.saks.firstWhere(
      (s) => s.id == sakId,
      orElse: () => throw StateError('not found'),
    );
    if (noSak != null) sak.noSak = noSak;
    if (berat != null) sak.berat = berat;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
  }

  Future<BsV2Transaction?> submit() async {
    if (!isBalanced) return null;
    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      final inputCodes = inputs.map((l) => l.labelCode).toList();
      final outputsJson = outputs.map((out) {
        if (hasSaks) {
          return <String, dynamic>{
            'idJenis': out.idJenis,
            'saks': out.saks
                .map((s) => {'noSak': s.noSak, 'berat': s.berat})
                .toList(),
          };
        } else if (isGilingan) {
          return <String, dynamic>{
            'idGilingan': out.idJenis,
            'berat': out.berat,
          };
        } else if (isPcsCategory) {
          return <String, dynamic>{
            'idJenis': out.idJenis,
            'pcs': out.berat.toInt(),
          };
        } else {
          return <String, dynamic>{'idJenis': out.idJenis, 'berat': out.berat};
        }
      }).toList();

      final result = await repository.submit(
        note: note,
        inputs: inputCodes,
        outputs: outputsJson,
      );
      lastResult = result;
      _reset();
      return result;
    } catch (e) {
      submitError = apiErrorMessage(e);
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void _reset() {
    inputs.clear();
    outputs.clear();
    note = '';
    lookupError = null;
    submitError = null;
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'washing':
        return 'Washing (B.)';
      case 'broker':
        return 'Broker (D.)';
      case 'crusher':
        return 'Crusher (F.)';
      case 'gilingan':
        return 'Gilingan (V.)';
      case 'mixer':
        return 'Mixer (H.)';
      case 'furnitureWip':
        return 'Furniture WIP (BB.)';
      case 'barangJadi':
        return 'Barang Jadi (BA.)';
      case 'bahanBaku':
        return 'Bahan Baku (A.)';
      default:
        return 'Bonggolan (M.)';
    }
  }
}
