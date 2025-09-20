import 'package:flutter/material.dart';

class LabelSelectionScreen extends StatelessWidget {
  const LabelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          _buildLabelCard(
            context,
            title: 'Label Washing',
            subtitle: 'Buat label untuk proses washing',
            icon: Icons.local_laundry_service,
            onTap: () {
              Navigator.pushNamed(context, '/label/washing');
            },
          ),
          const SizedBox(height: 16),
          _buildLabelCard(
            context,
            title: 'Label Broker',
            subtitle: 'Buat label untuk broker',
            icon: Icons.people,
            onTap: () {
              Navigator.pushNamed(context, '/label/broker');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabelCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: Colors.blue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
      ),
    );
  }
}
