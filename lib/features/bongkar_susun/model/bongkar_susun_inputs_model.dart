// lib/features/production/bongkar_susun/model/bongkar_susun_inputs_model.dart


/* ===================== ROOT AGGREGATOR ===================== */

import '../../production/shared/models/barang_jadi_item.dart';
import '../../production/shared/models/bb_item.dart';
import '../../production/shared/models/bonggolan_item.dart';
import '../../production/shared/models/broker_item.dart';
import '../../production/shared/models/crusher_item.dart';
import '../../production/shared/models/furniture_wip_item.dart';
import '../../production/shared/models/gilingan_item.dart';
import '../../production/shared/models/mixer_item.dart';
import '../../../core/utils/model_helpers.dart';
import '../../production/shared/models/washing_item.dart';

class BongkarSusunInputs {
  final List<BrokerItem> broker;
  final List<BbItem> bb;
  final List<WashingItem> washing;
  final List<CrusherItem> crusher;
  final List<GilinganItem> gilingan;
  final List<MixerItem> mixer;
  final List<BonggolanItem> bonggolan;
  final List<FurnitureWipItem> furnitureWip;
  final List<BarangJadiItem> barangJadi;

  final Map<String, int> summary;

  BongkarSusunInputs({
    required this.broker,
    required this.bb,
    required this.washing,
    required this.crusher,
    required this.gilingan,
    required this.mixer,
    required this.bonggolan,
    required this.furnitureWip,
    required this.barangJadi,
    required this.summary,
  });

  factory BongkarSusunInputs.fromJson(Map<String, dynamic> j) {
    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      final list = (v ?? []) as List;
      return list
          .map<T>((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    Map<String, int> _toSummary(dynamic v) {
      final m = Map<String, dynamic>.from((v ?? {}) as Map);
      return m.map((k, v) => MapEntry(k, asInt(v) ?? 0));
    }

    return BongkarSusunInputs(
      broker: _listOf(j['broker'], (m) => BrokerItem.fromJson(m)),
      bb: _listOf(j['bb'], (m) => BbItem.fromJson(m)),
      washing: _listOf(j['washing'], (m) => WashingItem.fromJson(m)),
      crusher: _listOf(j['crusher'], (m) => CrusherItem.fromJson(m)),
      gilingan: _listOf(j['gilingan'], (m) => GilinganItem.fromJson(m)),
      mixer: _listOf(j['mixer'], (m) => MixerItem.fromJson(m)),
      bonggolan: _listOf(j['bonggolan'], (m) => BonggolanItem.fromJson(m)),
      furnitureWip:
      _listOf(j['furnitureWip'], (m) => FurnitureWipItem.fromJson(m)),
      barangJadi:
      _listOf(j['barangJadi'], (m) => BarangJadiItem.fromJson(m)),
      summary: _toSummary(j['summary']),
    );
  }

  // Quick totals
  double totalBeratBb() => bb.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratGilingan() =>
      gilingan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratMixer() => mixer.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBroker() =>
      broker.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratWashing() =>
      washing.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratCrusher() =>
      crusher.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBonggolan() =>
      bonggolan.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratFurnitureWip() =>
      furnitureWip.fold(0.0, (s, it) => s + (it.berat ?? 0));
  double totalBeratBarangJadi() =>
      barangJadi.fold(0.0, (s, it) => s + (it.berat ?? 0));

  int totalPcsFurnitureWip() =>
      furnitureWip.fold(0, (s, it) => s + (it.pcs ?? 0));
  int totalPcsBarangJadi() => barangJadi.fold(0, (s, it) => s + (it.pcs ?? 0));
}