import 'penjualan_header_model.dart';
import 'penjualan_line_model.dart';

class PenjualanDetail {
  final PenjualanHeader header;
  final List<PenjualanLine> lines;

  const PenjualanDetail({required this.header, required this.lines});

  factory PenjualanDetail.fromJson(Map<String, dynamic> j) {
    final headerJson = j['header'] as Map<String, dynamic>? ?? {};
    final rawLines = j['lines'];
    final lines = (rawLines is List ? rawLines : <dynamic>[])
        .map((e) => PenjualanLine.fromJson(e as Map<String, dynamic>))
        .toList();

    return PenjualanDetail(
      header: PenjualanHeader.fromJson(headerJson),
      lines: lines,
    );
  }

  bool get isComplete => lines.isNotEmpty && lines.every((l) => l.isComplete);
}
