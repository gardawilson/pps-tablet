/// Format angka berat/pcs: tanpa desimal kalau bulat (mis. "23", bukan
/// "23.0"), maksimal 2 desimal (tanpa trailing zero) kalau tidak bulat.
String soV2FormatQty(num value) {
  final asDouble = value.toDouble();
  if (asDouble == asDouble.roundToDouble()) {
    return asDouble.toInt().toString();
  }
  var text = asDouble.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}
