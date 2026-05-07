import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_lokasi_view_model.dart';

class MappingLokasiScreen extends StatelessWidget {
  final String blok;
  final String namaWarehouse;

  const MappingLokasiScreen({
    super.key,
    required this.blok,
    required this.namaWarehouse,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          MappingLokasiViewModel(repository: MappingRepository(api: ApiClient()))
            ..loadLokasiByBlok(blok),
      child: _MappingLokasiView(blok: blok, namaWarehouse: namaWarehouse),
    );
  }
}

class _MappingLokasiView extends StatelessWidget {
  final String blok;
  final String namaWarehouse;

  const _MappingLokasiView({required this.blok, required this.namaWarehouse});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MappingLokasiViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Lokasi Blok $blok'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: vm.isLoading ? null : () => vm.loadLokasiByBlok(blok),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Text(
              namaWarehouse,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: _buildContent(vm)),
        ],
      ),
    );
  }

  Widget _buildContent(MappingLokasiViewModel vm) {
    if (vm.isLoading && vm.lokasiList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error.isNotEmpty && vm.lokasiList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(vm.error, textAlign: TextAlign.center),
        ),
      );
    }

    if (vm.lokasiList.isEmpty) {
      return const Center(child: Text('Data lokasi kosong'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: vm.lokasiList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = vm.lokasiList[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description.isEmpty ? '-' : item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID Lokasi: ${item.idLokasi}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                item.enable ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: item.enable ? Colors.green : Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }
}
