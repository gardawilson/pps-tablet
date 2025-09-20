import 'package:flutter/material.dart';

class CompactLabelCardWidget extends StatelessWidget {
  final String nomorLabel;
  final String labelType;
  final int jmlhSak;
  final double berat;
  final String idLokasi;
  final String? username;
  final bool isReference;

  const CompactLabelCardWidget({
    Key? key,
    required this.nomorLabel,
    required this.labelType,
    required this.jmlhSak,
    required this.berat,
    required this.idLokasi,
    this.username,
    required this.isReference,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color baseColor = const Color(0xFF2196F3); // Senada biru
    final Color backgroundColor = Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(baseColor),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.8),
          const SizedBox(height: 8),
          _buildInfoRow(baseColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color baseColor) {
    return Row(
      children: [
        Icon(Icons.qr_code_2_rounded, color: baseColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            nomorLabel,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            labelType,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: baseColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(Color baseColor) {
    final iconColor = baseColor.withOpacity(0.9);
    final textColor = Colors.grey.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _InfoIconText(Icons.inventory_2, "Pcs", "$jmlhSak", iconColor, textColor),
            _InfoIconText(Icons.monitor_weight, "Berat", "${berat.toStringAsFixed(2)} kg", iconColor, textColor),
            _InfoIconText(Icons.location_on, "Lokasi", idLokasi, iconColor, textColor),
            if (username != null && username!.isNotEmpty)
              _InfoIconText(Icons.person, "Scanned by", username!, iconColor, textColor),
          ],
        ),
      ],
    );
  }
}

class _InfoIconText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color textColor;

  const _InfoIconText(this.icon, this.label, this.value, this.iconColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          "$label: ",
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }
}
