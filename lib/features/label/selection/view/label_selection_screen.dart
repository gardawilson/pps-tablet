import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';

class LabelSelectionScreen extends StatelessWidget {
  const LabelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionViewModel>();

    final canReadWashing = perm.can('label_washing:read');
    final canReadBroker = perm.can('label_washing:read');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Label'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 🔹 Card Label Washing
          _buildLabelCard(
            context,
            title: 'Label Washing',
            subtitle: 'Buat label untuk proses washing',
            icon: Icons.label,
            enabled: canReadWashing,
            onTap: canReadWashing
                ? () => Navigator.pushNamed(context, '/label/washing')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Broker
          _buildLabelCard(
            context,
            title: 'Label Broker',
            subtitle: 'Buat label untuk proses broker',
            icon: Icons.label,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/label/broker')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Bonggolan
          _buildLabelCard(
            context,
            title: 'Label Bonggolan',
            subtitle: 'Buat label untuk proses bonggolan',
            icon: Icons.label,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/label/bonggolan')
                : null,
          ),

          // 🔹 Card Label Crusher
          _buildLabelCard(
            context,
            title: 'Label Crusher',
            subtitle: 'Buat label untuk proses crusher',
            icon: Icons.label,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/label/crusher')
                : null,
          ),

          // 🔹 Card Label Gilingan
          _buildLabelCard(
            context,
            title: 'Label Gilingan',
            subtitle: 'Buat label untuk proses gilingan',
            icon: Icons.label,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/label/gilingan')
                : null,
          ),

          // 🔹 Card Label Mixer
          _buildLabelCard(
            context,
            title: 'Label Mixer',
            subtitle: 'Buat label untuk proses mixer',
            icon: Icons.label,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/label/mixer')
                : null,
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable builder untuk setiap kartu label
  Widget _buildLabelCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback? onTap,
        bool enabled = true,
      }) {
    final Color baseColor = enabled ? Colors.blue : Colors.grey;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: enabled ? onTap : null,
          contentPadding: const EdgeInsets.all(20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: baseColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black87 : Colors.black45,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: baseColor,
          ),
        ),
      ),
    );
  }
}
