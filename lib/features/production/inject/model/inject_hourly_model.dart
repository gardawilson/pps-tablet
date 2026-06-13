class InjectHourlyEntry {
  final int? id;
  final String noProduksi;
  final String jam; // "08:00"
  final double? berat;
  final double? cycleTime;
  final int? counter;

  const InjectHourlyEntry({
    this.id,
    required this.noProduksi,
    required this.jam,
    this.berat,
    this.cycleTime,
    this.counter,
  });

  factory InjectHourlyEntry.fromJson(Map<String, dynamic> json) {
    return InjectHourlyEntry(
      id: json['id'] as int?,
      noProduksi: json['noProduksi'] as String? ?? '',
      jam: json['jam'] as String? ?? '',
      berat: (json['berat'] as num?)?.toDouble(),
      cycleTime: (json['cycleTime'] as num?)?.toDouble(),
      counter: json['counter'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'noProduksi': noProduksi,
    'jam': jam,
    if (berat != null) 'berat': berat,
    if (cycleTime != null) 'cycleTime': cycleTime,
    if (counter != null) 'counter': counter,
  };
}
