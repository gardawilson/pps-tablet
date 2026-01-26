import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Tambahkan dependency ini di pubspec.yaml
import 'package:pps_tablet/features/audit/view/audit_screen.dart';
import 'package:pps_tablet/features/bj_jual/view/bj_jual_screen.dart';
import 'package:pps_tablet/features/report/view/report_list_screen.dart';
import '../../../core/services/permission_storage.dart';
import '../../bongkar_susun/view/bongkar_susun_screen.dart';
import '../view_model/user_profile_view_model.dart';
import 'package:provider/provider.dart'; // ⬅️ wajib agar context.read bisa digunakan
import '../../home/view/widgets/user_profile_dialog.dart';
import '../../../core/services/token_storage.dart';
import '../../../core/view_model/permission_view_model.dart';

class HomeScreen extends StatelessWidget {

  // Fungsi untuk menampilkan dialog ganti password
  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserProfileDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool? confirmExit = await _showExitDialog(context);
        return confirmExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF0D47A1), // BLUE THEME
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.white,
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout != true) return;

                // 🔹 1. Bersihkan token dan permissions di local storage
                await TokenStorage.clear();
                await PermissionStorage.clear();

                // 🔹 2. Reset PermissionViewModel (biar permission lama tidak nyangkut)
                if (context.mounted) {
                  final permVm = context.read<PermissionViewModel>();
                  permVm.clear();

                  // 🔹 3. Arahkan kembali ke login page
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
            ),
          ],

        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0D47A1).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(), // Pastikan sudah disesuaikan ke tema biru
                const SizedBox(height: 24),
                _buildMenuSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0D47A1).withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PPS Tablet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plastic Production System',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900], // ganti warna judul agar sesuai tema
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          title: 'Input Label',
          subtitle: 'Buat label untuk item',
          icon: Icons.label,
          color: const Color(0xFF0D47A1), // BLUE PRIMARY
          onTap: () {
            Navigator.pushNamed(context, '/label');
          },
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          title: 'Proses Produksi',
          subtitle: 'Input data produksi',
          icon: Icons.production_quantity_limits_outlined,
          color: const Color(0xFF0D47A1), // BLUE PRIMARY
          onTap: () {
            Navigator.pushNamed(context, '/production');
          },
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          title: 'Bongkar Susun',
          subtitle: 'Input data Bongkar Susun',
          icon: Icons.production_quantity_limits_outlined,
          color: const Color(0xFF0D47A1),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BongkarSusunScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          title: 'Stock Opname',
          subtitle: 'Kelola stok item',
          icon: Icons.checklist_rtl_rounded,
          color: const Color(0xFF0D47A1), // BLUE PRIMARY
          onTap: () {
            Navigator.pushNamed(context, '/stockopname');
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          title: 'BJ Jual',
          subtitle: 'Kelola BJ Jual',
          icon: Icons.checklist_rtl_rounded,
          color: const Color(0xFF0D47A1), // BLUE PRIMARY
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BJJualScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          title: 'Laporan',
          subtitle: 'Lihat laporan',
          icon: Icons.newspaper_outlined,
          color: const Color(0xFF0D47A1), // BLUE PRIMARY
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReportListScreen(),
              ),
            );
          },
        ),
        // const SizedBox(height: 12),
        // _buildMenuCard(
        //   context,
        //   title: 'Audit',
        //   subtitle: 'Lihat history',
        //   icon: Icons.newspaper_outlined,
        //   color: const Color(0xFF0D47A1), // BLUE PRIMARY
        //   onTap: () {
        //     Navigator.of(context).push(
        //       MaterialPageRoute(
        //         builder: (_) => const AuditScreen(),
        //       ),
        //     );
        //   },
        // ),

        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          title: 'Akun',
          subtitle: 'Kelola password akun',
          icon: Icons.person,
          color: const Color(0xFF0D47A1),
          onTap: () {
            _showChangePasswordDialog(context);
          },
        ),
      ],
    );
  }


  Widget _buildMenuCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required Function onTap,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => onTap(),
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
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
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7a1b0c),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Ya', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}