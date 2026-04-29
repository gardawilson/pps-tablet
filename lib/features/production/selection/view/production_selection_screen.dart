import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/view_model/permission_view_model.dart';

class ProductionSelectionScreen extends StatelessWidget {
  const ProductionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final perm = context.watch<PermissionViewModel>();

    final canReadWashing = perm.can('produksi_washing:read');
    final canReadBroker = perm.can('produksi_broker:read');
    final canReadCrusher = perm.can('produksi_crusher:read');
    final canReadBonggolan = perm.can('produksi_bonggolan:read');
    final canReadMixer = perm.can('produksi_mixer:read');
    final canReadGilingan = perm.can('produksi_gilingan:read');
    final canReadInject = perm.can('injectproduksi:read');
    final canReadHotStamping = perm.can('hotstamping:read');
    final canReadPasangKunci = perm.can('pasangkunci:read');
    final canReadSpanner = perm.can('spanner:read');
    final canReadPacking = perm.can('packing:read');
    final canReadSortirReject = perm.can('barangjadisortirreject:read');
    final canReadRetur = perm.can('barangjadiretur:read');
    final canReadFurnitureAssembly = perm.can('furnitureassembly:read');
    final canReadFurnitureMaterial = perm.can('furniturematerial:read');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Proses'),
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
            title: 'Proses Washing',
            subtitle: 'Buat label untuk proses washing',
            icon: Icons.inventory_2_outlined,
            enabled: canReadWashing,
            onTap: canReadWashing
                ? () => Navigator.pushNamed(context, '/production/washing')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Broker
          _buildLabelCard(
            context,
            title: 'Proses Broker',
            subtitle: 'Buat label untuk proses broker',
            icon: Icons.inventory_2_outlined,
            enabled: canReadBroker,
            onTap: canReadBroker
                ? () => Navigator.pushNamed(context, '/production/broker')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Crusher
          _buildLabelCard(
            context,
            title: 'Proses Crusher',
            subtitle: 'Buat label untuk proses crusher',
            icon: Icons.inventory_2_outlined,
            enabled: canReadCrusher,
            onTap: canReadCrusher
                ? () => Navigator.pushNamed(context, '/production/crusher')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Gilingan
          _buildLabelCard(
            context,
            title: 'Proses Gilingan',
            subtitle: 'Buat label untuk proses gilingan',
            icon: Icons.inventory_2_outlined,
            enabled: canReadGilingan,
            onTap: canReadGilingan
                ? () => Navigator.pushNamed(context, '/production/gilingan')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Mixer
          _buildLabelCard(
            context,
            title: 'Proses Mixer',
            subtitle: 'Buat label untuk proses mixer',
            icon: Icons.inventory_2_outlined,
            enabled: canReadMixer,
            onTap: canReadMixer
                ? () => Navigator.pushNamed(context, '/production/mixer')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Inject
          _buildLabelCard(
            context,
            title: 'Proses Inject',
            subtitle: 'Buat label untuk proses inject',
            icon: Icons.inventory_2_outlined,
            enabled: canReadInject,
            onTap: canReadInject
                ? () => Navigator.pushNamed(context, '/production/inject')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label HotStamping
          _buildLabelCard(
            context,
            title: 'Proses HotStamping',
            subtitle: 'Buat label untuk proses hot stamping',
            icon: Icons.inventory_2_outlined,
            enabled: canReadHotStamping,
            onTap: canReadHotStamping
                ? () => Navigator.pushNamed(context, '/production/hot-stamp')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label PasangKunci
          _buildLabelCard(
            context,
            title: 'Proses Pasang Kunci',
            subtitle: 'Buat label untuk proses pasang kunci',
            icon: Icons.inventory_2_outlined,
            enabled: canReadPasangKunci,
            onTap: canReadPasangKunci
                ? () => Navigator.pushNamed(context, '/production/key-fitting')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Spanner
          _buildLabelCard(
            context,
            title: 'Proses Spanner',
            subtitle: 'Buat label untuk proses spanner',
            icon: Icons.inventory_2_outlined,
            enabled: canReadSpanner,
            onTap: canReadSpanner
                ? () => Navigator.pushNamed(context, '/production/spanner')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Packing
          _buildLabelCard(
            context,
            title: 'Proses Packing',
            subtitle: 'Buat label untuk proses packing',
            icon: Icons.inventory_2_outlined,
            enabled: canReadPacking,
            onTap: canReadPacking
                ? () => Navigator.pushNamed(context, '/production/packing')
                : null,
          ),

          const SizedBox(height: 16),

          // 🔹 Card Label Retur
          _buildLabelCard(
            context,
            title: 'Proses Retur',
            subtitle: 'Buat label untuk proses retur',
            icon: Icons.inventory_2_outlined,
            enabled: canReadRetur,
            onTap: canReadRetur
                ? () => Navigator.pushNamed(context, '/production/return')
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: baseColor),
        ),
      ),
    );
  }
}
