import '../../shared/models/broker_item.dart';
import '../../shared/models/bonggolan_item.dart';
import '../../shared/models/crusher_item.dart';
import '../../shared/models/reject_item.dart';
import '../../shared/models/model_helpers.dart';

// ✅ Export semua item models agar bisa diakses lewat satu import
export '../../shared/models/broker_item.dart';
export '../../shared/models/bonggolan_item.dart';
export '../../shared/models/crusher_item.dart';
export '../../shared/models/reject_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class GilinganInputs {
  final List<BrokerItem> broker;
  final List<BonggolanItem> bonggolan;
  final List<CrusherItem> crusher;
  final List<RejectItem> reject;

  final Map<String, int> summary;

  GilinganInputs({
    required this.broker,
    required this.bonggolan,
    required this.crusher,
    required this.reject,
    required this.summary,
  });

  factory GilinganInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return GilinganInputs(
      broker: _listOf(j['broker'], (m) => BrokerItem.fromJson(m)),
      bonggolan: _listOf(j['bonggolan'], (m) => BonggolanItem.fromJson(m)),
      crusher: _listOf(j['crusher'], (m) => CrusherItem.fromJson(m)),
      reject: _listOf(j['reject'], (m) => RejectItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals
  double totalBeratBroker() => broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBonggolan() => bonggolan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratCrusher() => crusher.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratReject() => reject.fold(0.0, (s, it) => s + (it.berat ?? 0));
}
