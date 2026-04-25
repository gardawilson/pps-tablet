import 'package:flutter/material.dart';

const Map<String, String> _bsV2CategoryLabels = {
  'washing': 'Washing',
  'broker': 'Broker',
  'crusher': 'Crusher',
  'gilingan': 'Gilingan',
  'mixer': 'Mixer',
  'furnitureWip': 'Furniture WIP',
  'barangJadi': 'Barang Jadi',
  'bahanBaku': 'Bahan Baku',
  'bonggolan': 'Bonggolan',
};

const Map<String, String> _bsV2CategoryCodes = {
  'washing': 'B.',
  'broker': 'D.',
  'crusher': 'F.',
  'gilingan': 'V.',
  'mixer': 'H.',
  'furnitureWip': 'BB.',
  'barangJadi': 'BA.',
  'bahanBaku': 'A.',
  'bonggolan': 'M.',
};

String bsV2CategoryLabel(
  String? category, {
  String nullLabel = '-',
  String unknownLabel = 'Unknown',
}) {
  if (category == null) return nullLabel;
  return _bsV2CategoryLabels[category] ?? unknownLabel;
}

String bsV2CategoryLabelWithCode(
  String? category, {
  String nullLabel = '-',
  String unknownLabel = 'Bonggolan',
}) {
  if (category == null) return nullLabel;

  final label = _bsV2CategoryLabels[category] ?? unknownLabel;
  final code = _bsV2CategoryCodes[category] ?? _bsV2CategoryCodes['bonggolan']!;
  return '$label ($code)';
}

Widget bsV2CategoryBadge(String? category, {TextStyle? textStyle}) {
  final label = bsV2CategoryLabelWithCode(category);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4F8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: textStyle),
  );
}
