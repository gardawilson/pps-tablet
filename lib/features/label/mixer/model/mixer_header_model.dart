class MixerHeader {
  final String noMixer;          // NoMixer
  final int idMixer;            // IdMixer
  final String namaMixer;       // NamaMixer (from MstMixer.Jenis)
  final String dateCreate;      // DateCreate (string as sent by API)

  /// Server gives 'PASS' / 'HOLD'
  final String statusText;      // StatusText
  /// Derived from statusText (PASS=true, HOLD=false, else null)
  final bool? idStatus;

  // Location
  final String? blok;           // Blok
  final int? idLokasi;          // IdLokasi (INT in DB)

  // Quality / process fields (optional)
  final double? moisture;       // Moisture
  final double? maxMeltTemp;    // MaxMeltTemp
  final double? minMeltTemp;    // MinMeltTemp
  final double? mfi;            // MFI
  final double? moisture2;      // Moisture2
  final double? moisture3;      // Moisture3

  // Production / machine / bongkar susun joins
  final String? noProduksi;     // NoProduksi
  final String? namaMesin;      // NamaMesin (from MstMesin)
  final String? noBongkarSusun; // NoBongkarSusun

  // Audit (optional)
  final String? createBy;       // CreateBy
  final String? dateTimeCreate; // DateTimeCreate

  const MixerHeader({
    required this.noMixer,
    required this.idMixer,
    required this.namaMixer,
    required this.dateCreate,
    required this.statusText,
    this.idStatus,
    this.blok,
    this.idLokasi,
    this.moisture,
    this.maxMeltTemp,
    this.minMeltTemp,
    this.mfi,
    this.moisture2,
    this.moisture3,
    this.noProduksi,
    this.namaMesin,
    this.noBongkarSusun,
    this.createBy,
    this.dateTimeCreate,
  });

  // ---- helpers ----
  static bool? _statusToBool(String? s) {
    if (s == null) return null;
    final v = s.trim().toUpperCase();
    if (v == 'PASS') return true;
    if (v == 'HOLD') return false;
    return null;
  }

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

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory MixerHeader.fromJson(Map<String, dynamic> json) {
    final statusText = json['StatusText']?.toString() ?? '';

    return MixerHeader(
      noMixer: json['NoMixer']?.toString() ?? '',
      idMixer: _toInt(json['IdMixer']),
      // make sure your SQL aliases MstMixer.Jenis AS NamaMixer
      namaMixer: json['NamaMixer']?.toString() ?? '',
      dateCreate: json['DateCreate']?.toString() ?? '',
      statusText: statusText,
      idStatus: _statusToBool(statusText),

      blok: json['Blok']?.toString(),
      idLokasi: _toIntOrNull(json['IdLokasi']),

      moisture: _toDouble(json['Moisture']),
      maxMeltTemp: _toDouble(json['MaxMeltTemp']),
      minMeltTemp: _toDouble(json['MinMeltTemp']),
      mfi: _toDouble(json['MFI']),
      moisture2: _toDouble(json['Moisture2']),
      moisture3: _toDouble(json['Moisture3']),

      noProduksi: json['NoProduksi']?.toString(),
      namaMesin: json['NamaMesin']?.toString(),
      noBongkarSusun: json['NoBongkarSusun']?.toString(),

      createBy: json['CreateBy']?.toString(),
      dateTimeCreate: json['DateTimeCreate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'NoMixer': noMixer,
    'IdMixer': idMixer,
    'NamaMixer': namaMixer,
    'DateCreate': dateCreate,
    'StatusText': statusText,
    'IdStatus': idStatus, // derived

    'Blok': blok,
    'IdLokasi': idLokasi,

    'Moisture': moisture,
    'MaxMeltTemp': maxMeltTemp,
    'MinMeltTemp': minMeltTemp,
    'MFI': mfi,
    'Moisture2': moisture2,
    'Moisture3': moisture3,

    'NoProduksi': noProduksi,
    'NamaMesin': namaMesin,
    'NoBongkarSusun': noBongkarSusun,

    'CreateBy': createBy,
    'DateTimeCreate': dateTimeCreate,
  };

  MixerHeader copyWith({
    String? noMixer,
    int? idMixer,
    String? namaMixer,
    String? dateCreate,
    String? statusText,
    bool? idStatus,
    String? blok,
    int? idLokasi,
    double? moisture,
    double? maxMeltTemp,
    double? minMeltTemp,
    double? mfi,
    double? moisture2,
    double? moisture3,
    String? noProduksi,
    String? namaMesin,
    String? noBongkarSusun,
    String? createBy,
    String? dateTimeCreate,
  }) {
    return MixerHeader(
      noMixer: noMixer ?? this.noMixer,
      idMixer: idMixer ?? this.idMixer,
      namaMixer: namaMixer ?? this.namaMixer,
      dateCreate: dateCreate ?? this.dateCreate,
      statusText: statusText ?? this.statusText,
      idStatus: idStatus ?? this.idStatus,
      blok: blok ?? this.blok,
      idLokasi: idLokasi ?? this.idLokasi,
      moisture: moisture ?? this.moisture,
      maxMeltTemp: maxMeltTemp ?? this.maxMeltTemp,
      minMeltTemp: minMeltTemp ?? this.minMeltTemp,
      mfi: mfi ?? this.mfi,
      moisture2: moisture2 ?? this.moisture2,
      moisture3: moisture3 ?? this.moisture3,
      noProduksi: noProduksi ?? this.noProduksi,
      namaMesin: namaMesin ?? this.namaMesin,
      noBongkarSusun: noBongkarSusun ?? this.noBongkarSusun,
      createBy: createBy ?? this.createBy,
      dateTimeCreate: dateTimeCreate ?? this.dateTimeCreate,
    );
  }
}
