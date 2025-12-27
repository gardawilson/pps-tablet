// lib/features/production/mixer/model/mixer_inputs_model.dart

import '../../shared/models/broker_item.dart';
import '../../shared/models/bb_item.dart';
import '../../shared/models/gilingan_item.dart';
import '../../shared/models/mixer_item.dart';
import '../../shared/models/model_helpers.dart';

// ✅ Export item models agar bisa diakses lewat satu import
export '../../shared/models/broker_item.dart';
export '../../shared/models/bb_item.dart';
export '../../shared/models/gilingan_item.dart';
export '../../shared/models/mixer_item.dart';

/* ===================== ROOT AGGREGATOR ===================== */

class MixerInputs {
  final List<BrokerItem> broker;
  final List<BbItem> bb;
  final List<GilinganItem> gilingan;
  final List<MixerItem> mixer;

  final Map<String, int> summary;

  MixerInputs({
    required this.broker,
    required this.bb,
    required this.gilingan,
    required this.mixer,
    required this.summary,
  });

  factory MixerInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list.map<T>((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return MixerInputs(
      broker: _listOf(j['broker'], (m) => BrokerItem.fromJson(m)),
      bb: _listOf(j['bb'], (m) => BbItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      mixer: _listOf(j['mixer'], (m) => MixerItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals
  double totalBeratBroker() => broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBb() => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() => gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratMixer() => mixer.fold(0.0, (s, it) => s + (it.berat ?? 0));

  // Total semua input
  double totalBerat() =>
      totalBeratBroker() +
          totalBeratBb() +
          totalBeratGilingan() +
          totalBeratMixer();

  // Total items count
  int totalItems() =>
      broker.length +
          bb.length +
          gilingan.length +
          mixer.length;

  // Check if has any inputs
  bool get isEmpty =>
      broker.isEmpty &&
          bb.isEmpty &&
          gilingan.isEmpty &&
          mixer.isEmpty;

  bool get isNotEmpty => !isEmpty;

  // Copy with method untuk state management
  MixerInputs copyWith({
    List<BrokerItem>? broker,
    List<BbItem>? bb,
    List<GilinganItem>? gilingan,
    List<MixerItem>? mixer,
    Map<String, int>? summary,
  }) {
    return MixerInputs(
      broker: broker ?? this.broker,
      bb: bb ?? this.bb,
      gilingan: gilingan ?? this.gilingan,
      mixer: mixer ?? this.mixer,
      summary: summary ?? this.summary,
    );
  }

  // Empty factory
  factory MixerInputs.empty() {
    return MixerInputs(
      broker: [],
      bb: [],
      gilingan: [],
      mixer: [],
      summary: {},
    );
  }

  // Get summary by category
  int countBroker() => summary['broker'] ?? broker.length;
  int countBb() => summary['bb'] ?? bb.length;
  int countGilingan() => summary['gilingan'] ?? gilingan.length;
  int countMixer() => summary['mixer'] ?? mixer.length;
}