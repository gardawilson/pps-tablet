import 'package:flutter/material.dart';

import '../model/so_v2_access_user.dart';
import '../repository/so_v2_user_lokasi_access_repository.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kInk = Color(0xFF1A1D23);
const _kMuted = Color(0xFF8A94A6);
const _kSurface = Color(0xFFF4F6F8);
const _kOnline = Color(0xFF0A7349);

/// Palet warna avatar — dipilih berdasarkan hash id user supaya konsisten
/// per user tapi bervariasi antar user.
const _kAvatarPalette = [
  Color(0xFF1E6FD9),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFFEA580C),
  Color(0xFF0A7349),
  Color(0xFF0891B2),
  Color(0xFFB45309),
  Color(0xFF4F46E5),
];

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.repo.fetchAllUsers();
      if (!mounted) return;
      users.sort((a, b) {
        if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
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
    final onlineCount = _users.where((u) => u.isOnline).length;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(onlineCount),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _buildSearchField(),
            ),
            Flexible(child: _buildList(filtered)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int onlineCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: _kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tugaskan User',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _loading
                      ? 'Memuat daftar user...'
                      : '$onlineCount user sedang online',
                  style: const TextStyle(fontSize: 11.5, color: _kMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18),
            color: _kMuted,
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _searchCtl,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 13.5, color: _kInk),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Cari nama atau username...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: _kMuted,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _kMuted,
                  ),
                  splashRadius: 14,
                  onPressed: () => setState(() {
                    _searchCtl.clear();
                    _query = '';
                  }),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildList(List<SoV2AccessUser> filtered) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _load, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 32,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              const Text(
                'Tidak ada user ditemukan',
                style: TextStyle(fontSize: 12.5, color: _kMuted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final user = filtered[index];
        return _UserTile(
          user: user,
          onTap: () => Navigator.of(context).pop(user),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final SoV2AccessUser user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  Color get _avatarColor =>
      _kAvatarPalette[user.idUsername % _kAvatarPalette.length];

  String get _initial {
    final trimmed = user.username.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _avatarColor.withValues(alpha: 0.14),
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: _avatarColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: _kOnline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                    if (user.fullName.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _kMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
