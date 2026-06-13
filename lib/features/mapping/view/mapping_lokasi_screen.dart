import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pps_tablet/core/network/api_client.dart';
import 'package:pps_tablet/features/mapping/model/mapping_lokasi_model.dart';
import 'package:pps_tablet/features/mapping/repository/mapping_repository.dart';
import 'package:pps_tablet/features/mapping/view/mapping_layout_editor_screen.dart';
import 'package:pps_tablet/features/mapping/view/widgets/label_dialog.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_label_view_model.dart';
import 'package:pps_tablet/features/mapping/view_model/mapping_lokasi_view_model.dart';

const Color _primary = Color(0xFF0D47A1);

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
      create: (_) => MappingLokasiViewModel(
        repository: MappingRepository(api: ApiClient()),
      )..loadLokasiByBlok(blok),
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
      backgroundColor: Colors.white,
      body: _buildContent(context, vm),
    );
  }

  Widget _buildContent(BuildContext context, MappingLokasiViewModel vm) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subheader
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                namaWarehouse,
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${vm.lokasiList.length} lokasi',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MappingLayoutEditorScreen(
                      blok: blok,
                      namaWarehouse: namaWarehouse,
                      lokasiList: vm.lokasiList,
                    ),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 15),
                label: const Text('Edit Layout'),
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lokasi grid
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: vm.lokasiList
                  .map((item) => _buildLokasiCard(context, item))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLokasiCard(BuildContext context, MappingLokasi item) {
    return GestureDetector(
      onTap: () => _showLabelDialog(context, item),
      child: Container(
        width: 80,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.description.isEmpty ? '-' : item.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 9,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelDialog(BuildContext context, MappingLokasi item) {
    final vm = MappingLabelViewModel(
      repository: MappingRepository(api: ApiClient()),
    )..load(blok: item.blok, idLokasi: item.idLokasi);

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: LabelDialog(lokasi: item),
      ),
    ).whenComplete(() => vm.dispose());
  }
}
