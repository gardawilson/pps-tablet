class MixerDetail {
  final String noMixer;      // NoMixer
  final int noSak;           // NoSak
  final double? berat;       // Berat
  final String? dateUsage;   // DateUsage (already formatted by API)
  final bool? isPartial;     // IsPartial

  const MixerDetail({
    required this.noMixer,
    required this.noSak,
    this.berat,
    this.dateUsage,
    this.isPartial,
  });

  // ---- helpers ----
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'y' || s == 'yes';
    }
    return null;
  }

  factory MixerDetail.fromJson(Map<String, dynamic> json) {
    return MixerDetail(
      noMixer: json['NoMixer']?.toString() ?? '',
      noSak: _toInt(json['NoSak']),
      berat: _toDouble(json['Berat']),
      dateUsage: json['DateUsage']?.toString(),
      isPartial: _toBool(json['IsPartial']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NoMixer': noMixer,
      'NoSak': noSak,
      'Berat': berat,
      'DateUsage': dateUsage,
      'IsPartial': isPartial,
    };
  }

  MixerDetail copyWith({
    String? noMixer,
    int? noSak,
    double? berat,
    String? dateUsage,
    bool? isPartial,
  }) {
    return MixerDetail(
      noMixer: noMixer ?? this.noMixer,
      noSak: noSak ?? this.noSak,
      berat: berat ?? this.berat,
      dateUsage: dateUsage ?? this.dateUsage,
      isPartial: isPartial ?? this.isPartial,
    );
  }
}
