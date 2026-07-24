// lib/features/verifikasi/view/verifikasi_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/view_model/permission_view_model.dart';
import '../model/verifikasi_models.dart';
import '../view_model/verifikasi_view_model.dart';
import 'verifikasi_detail_screen.dart';

const _kVerifikasiPrimary = Color(0xFF6D28D9);

class VerifikasiListScreen extends StatelessWidget {
  const VerifikasiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VerifikasiViewModel>(
      create: (_) => VerifikasiViewModel()..load(),
      child: const _VerifikasiListBody(),
    );
  }
}

class _VerifikasiListBody extends StatelessWidget {
  const _VerifikasiListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VerifikasiViewModel>();
    final perm = context.watch<PermissionViewModel>();
    final canRead = perm.can('verifikasi:read');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Verifikasi Produksi'),
        backgroundColor: _kVerifikasiPrimary,
        foregroundColor: Colors.white,
      ),
      body: !canRead
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Anda tidak memiliki akses untuk halaman ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : Column(
              children: [
                _buildFilterBar(context, vm),
                Expanded(child: _buildBody(context, vm)),
              ],
            ),
    );
  }

  Widget _buildFilterBar(BuildContext context, VerifikasiViewModel vm) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(context, vm, null, 'Semua'),
            for (final key in vm.availableJenis)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _filterChip(context, vm, key, vm.jenisLabel(key)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    VerifikasiViewModel vm,
    String? key,
    String label,
  ) {
    final selected = vm.jenisFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _kVerifikasiPrimary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? _kVerifikasiPrimary : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
      onSelected: (_) => vm.setJenisFilter(key),
    );
  }

  Widget _buildBody(BuildContext context, VerifikasiViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Gagal memuat data:\n${vm.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (vm.items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada produksi yang menunggu verifikasi.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: vm.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _VerifikasiListTile(item: vm.items[i]),
      ),
    );
  }
}

class _VerifikasiListTile extends StatelessWidget {
  final VerifikasiItem item;

  const _VerifikasiListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final tgl = item.tglProduksi != null
        ? DateFormat('dd MMM yyyy', 'id_ID').format(item.tglProduksi!.toLocal())
        : '-';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          final vm = context.read<VerifikasiViewModel>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider<VerifikasiViewModel>.value(
                value: vm,
                child: VerifikasiDetailScreen(item: item),
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kVerifikasiPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fact_check_outlined, color: _kVerifikasiPrimary),
        ),
        title: Text(
          item.noProduksi,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item.jenisLabel} • ${item.namaMesin ?? '-'} • Shift ${item.shift ?? '-'} • $tgl',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
