import 'package:flutter/material.dart';

import '../model/so_v2_access_user.dart';
import '../repository/so_v2_user_lokasi_access_repository.dart';

const _kBorder = Color(0xFFE2E6EA);
const _kInk = Color(0xFF1A1D23);
const _kMuted = Color(0xFF6B7280);

/// Dialog pemilih user (search) untuk ditugaskan bekerja pada satu lokasi.
/// Pop [SoV2AccessUser] yang dipilih, atau null jika dibatalkan.
class SoV2WorkerPickerDialog extends StatefulWidget {
  final SoV2UserLokasiAccessRepository repo;

  const SoV2WorkerPickerDialog({super.key, required this.repo});

  @override
  State<SoV2WorkerPickerDialog> createState() =>
      _SoV2WorkerPickerDialogState();
}

class _SoV2WorkerPickerDialogState extends State<SoV2WorkerPickerDialog> {
  bool _loading = true;
  String? _error;
  List<SoV2AccessUser> _users = [];
  final _searchCtl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final users = await widget.repo.fetchAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar user';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _users
        : _users.where((u) {
            final q = _query.toLowerCase();
            return u.username.toLowerCase().contains(q) ||
                u.fullName.toLowerCase().contains(q);
          }).toList();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tugaskan User',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih user yang akan mengerjakan stock opname di lokasi ini.',
                style: TextStyle(fontSize: 12, color: _kMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Cari nama atau username...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: _buildList(filtered)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<SoV2AccessUser> filtered) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Tidak ada user ditemukan',
            style: TextStyle(fontSize: 12.5, color: _kMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
      itemBuilder: (context, index) {
        final user = filtered[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            user.fullName.isEmpty ? user.username : user.fullName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kInk,
            ),
          ),
          subtitle: Text(
            user.username,
            style: const TextStyle(fontSize: 11.5, color: _kMuted),
          ),
          onTap: () => Navigator.of(context).pop(user),
        );
      },
    );
  }
}
