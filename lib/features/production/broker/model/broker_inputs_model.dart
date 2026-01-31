// lib/features/production/broker/model/bongkar_susun_inputs_model.dart

import '../../shared/models/broker_item.dart';
import '../../shared/models/bb_item.dart';
import '../../shared/models/washing_item.dart';
import '../../shared/models/crusher_item.dart';
import '../../shared/models/gilingan_item.dart';
import '../../shared/models/mixer_item.dart';
import '../../shared/models/reject_item.dart';
import '../../../../core/utils/model_helpers.dart';

// ✅ Export semua item models agar bisa diakses lewat satu import
export '../../shared/models/broker_item.dart';
export '../../shared/models/bb_item.dart';
export '../../shared/models/washing_item.dart';
export '../../shared/models/crusher_item.dart';
export '../../shared/models/gilingan_item.dart';
export '../../shared/models/mixer_item.dart';
export '../../shared/models/reject_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class BrokerInputs {
  final List<BrokerItem> broker;
  final List<BbItem> bb;
  final List<WashingItem> washing;
  final List<CrusherItem> crusher;
  final List<GilinganItem> gilingan;
  final List<MixerItem> mixer;
  final List<RejectItem> reject;

  final Map<String, int> summary;

  BrokerInputs({
    required this.broker,
    required this.bb,
    required this.washing,
    required this.crusher,
    required this.gilingan,
    required this.mixer,
    required this.reject,
    required this.summary,
  });

  factory BrokerInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return BrokerInputs(
      broker: _listOf(j['broker'], (m) => BrokerItem.fromJson(m)),
      bb: _listOf(j['bb'], (m) => BbItem.fromJson(m)),
      washing: _listOf(j['washing'], (m) => WashingItem.fromJson(m)),
      crusher: _listOf(j['crusher'], (m) => CrusherItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      mixer: _listOf(j['mixer'], (m) => MixerItem.fromJson(m)),
      reject: _listOf(j['reject'], (m) => RejectItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals
  double totalBeratBb() => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() => gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratMixer() => mixer.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratReject() => reject.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBroker() => broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratWashing() => washing.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratCrusher() => crusher.fold(0.0, (s, it) => s + (it.berat ?? 0));
}