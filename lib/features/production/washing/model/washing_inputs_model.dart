// lib/features/production/washing/model/washing_inputs_model.dart

import '../../shared/models/bb_item.dart';
import '../../shared/models/washing_item.dart';
import '../../shared/models/gilingan_item.dart';
import '../../../../core/utils/model_helpers.dart';

// ✅ Export semua item models agar bisa diakses lewat satu import
export '../../shared/models/bb_item.dart';
export '../../shared/models/washing_item.dart';
export '../../shared/models/gilingan_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class WashingInputs {
  final List<BbItem> bb;
  final List<WashingItem> washing;
  final List<GilinganItem> gilingan;

  final Map<String, int> summary;

  WashingInputs({
    required this.bb,
    required this.washing,
    required this.gilingan,
    required this.summary,
  });

  factory WashingInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return WashingInputs(
      bb: _listOf(j['bb'], (m) => BbItem.fromJson(m)),
      washing: _listOf(j['washing'], (m) => WashingItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals
  double totalBeratBb() => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratWashing() => washing.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() => gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
}