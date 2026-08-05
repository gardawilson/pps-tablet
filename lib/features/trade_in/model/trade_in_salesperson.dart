class TradeInSalesPerson {
  final String code;
  final String name;

  const TradeInSalesPerson({required this.code, required this.name});

  factory TradeInSalesPerson.fromJson(Map<String, dynamic> json) {
    return TradeInSalesPerson(
      code: (json['SalesPersonCode'] ?? '').toString(),
      name: (json['SalesPersonName'] ?? '').toString(),
    );
  }
}
