// lib/features/production/shared/models/mixer_item.dart

import '../../../../core/utils/model_helpers.dart';

class MixerItem {
  final String? noMixer;
  final int? noSak;
  final String? noMixerPartial;
  final double? berat;
  final double? beratAct;
  final bool? isPartial;
  final int? idJenis;
  final String? namaJenis;

  bool get isPartialRow =>
      (noMixerPartial?.trim().isNotEmpty ?? false) || (isPartial == true);

  MixerItem({
    this.noMixer,
    this.noSak,
    this.noMixerPartial,
    this.berat,
    this.beratAct,
    this.isPartial,
    this.idJenis,
    this.namaJenis,
  });

  factory MixerItem.fromJson(Map<String, dynamic> j) => MixerItem(
    noMixer: pickS(j, ['noMixer', 'NoMixer', 'no_mixer']),
    noSak: pickI(j, ['noSak', 'NoSak', 'no_sak']),
    noMixerPartial:
    pickS(j, ['noMixerPartial', 'NoMixerPartial', 'no_mixer_partial']),
    berat: pickD(j, ['berat', 'Berat']),
    beratAct: pickD(j, ['beratAct', 'BeratAct', 'berat_act']),
    isPartial: pickB(j, ['isPartial', 'IsPartial', 'is_partial']),
    idJenis: pickI(j, ['idJenis', 'IdJenis']),
    namaJenis: pickS(j, ['namaJenis', 'NamaJenis']),
  );

  MixerItem copyWith({
    String? noMixer,
    int? noSak,
    String? noMixerPartial,
    double? berat,
    double? beratAct,
    bool? isPartial,
    int? idJenis,
    String? namaJenis,
  }) {
    return MixerItem(
      noMixer: noMixer ?? this.noMixer,
      noSak: noSak ?? this.noSak,
      noMixerPartial: noMixerPartial ?? this.noMixerPartial,
      berat: berat ?? this.berat,
      beratAct: beratAct ?? this.beratAct,
      isPartial: isPartial ?? this.isPartial,
      idJenis: idJenis ?? this.idJenis,
      namaJenis: namaJenis ?? this.namaJenis,
    );
  }

  String toDebugString() {
    final part = (noMixerPartial ?? '').trim();
    final title = part.isNotEmpty ? part : (noMixer ?? '-');
    final tag = isPartialRow ? '[MIX•PART]' : '[MIX]';
    return '$tag $title • sak ${noSak ?? 0} • ${(berat ?? 0).toStringAsFixed(2)}kg';
  }
}