class StockOpname {
  final String noSO;
  final String tanggal;
  final String namaWarehouse; // ⬅️ ubah dari int? idWarehouse menjadi String
  final bool isBahanBaku;
  final bool isWashing;
  final bool isBonggolan;
  final bool isCrusher;
  final bool isBroker;
  final bool isGilingan;
  final bool isMixer;

  StockOpname({
    required this.noSO,
    required this.tanggal,
    required this.namaWarehouse,
    required this.isBahanBaku,
    required this.isWashing,
    required this.isBonggolan,
    required this.isCrusher,
    required this.isBroker,
    required this.isGilingan,
    required this.isMixer,
  });

  factory StockOpname.fromJson(Map<String, dynamic> json) {
    return StockOpname(
      noSO: json['NoSO'] ?? '',
      tanggal: json['Tanggal']?.toString() ?? '',
      namaWarehouse: json['NamaWarehouse'] ?? '-', // ⬅️ ambil nama dari API
      isBahanBaku: json['IsBahanBaku'] ?? false,
      isWashing: json['IsWashing'] ?? false,
      isBonggolan: json['IsBonggolan'] ?? false,
      isCrusher: json['IsCrusher'] ?? false,
      isBroker: json['IsBroker'] ?? false,
      isGilingan: json['IsGilingan'] ?? false,
      isMixer: json['IsMixer'] ?? false,
    );
  }
}
