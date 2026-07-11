import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/so_v2_kategori.dart';
import '../view_model/so_v2_kategori_list_view_model.dart';
import '../widgets/so_v2_generate_date_dialog.dart';
import '../widgets/so_v2_status_badge.dart';
import 'so_v2_detail_screen.dart';

const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

class SoV2KategoriListScreen extends StatefulWidget {
  const SoV2KategoriListScreen({super.key});

  @override
  State<SoV2KategoriListScreen> createState() =>
      _SoV2KategoriListScreenState();
}

class _SoV2KategoriListScreenState extends State<SoV2KategoriListScreen> {
  late final SoV2KategoriListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SoV2KategoriListViewModel();
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _onTapKategori(SoV2Kategori kategori) async {
    if (kategori.status == SoV2Status.notStarted) {
      final date = await showDialog<DateTime>(
        context: context,
        builder: (_) => SoV2GenerateDateDialog(
          categoryName: kategori.categoryName,
        ),
      );
      if (date == null) return;
      final res = await _vm.generate(categoryId: kategori.categoryId, date: date);
      if (!mounted) return;
      if (res.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage!),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
      final result = res.result!;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SoV2DetailScreen(
            stockOpnameNo: result['stockOpnameNo'].toString(),
            categoryCode: result['categoryCode']?.toString() ?? kategori.categoryCode,
          ),
        ),
      );
      if (mounted) _vm.load();
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SoV2DetailScreen(
            stockOpnameNo: kategori.stockOpnameNo!,
            categoryCode: kategori.categoryCode,
          ),
        ),
      );
      if (mounted) _vm.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SoV2KategoriListViewModel>.value(
      value: _vm,
      child: Consumer<SoV2KategoriListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: _kSurface,
            body: RefreshIndicator(
              onRefresh: vm.load,
              child: _buildBody(vm),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(SoV2KategoriListViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null && vm.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Center(
            child: Text(vm.error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      );
    }
    if (vm.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(child: Text('Belum ada kategori')),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 220).floor().clamp(
          1,
          8,
        );
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            final kategori = vm.items[index];
            return _KategoriTile(
              kategori: kategori,
              onTap: () => _onTapKategori(kategori),
            );
          },
        );
      },
    );
  }
}

class _KategoriTile extends StatelessWidget {
  final SoV2Kategori kategori;
  final VoidCallback onTap;

  const _KategoriTile({required this.kategori, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final percent = (kategori.progress * 100).round();
    final complete = kategori.labelCount > 0 && kategori.scannedCount >= kategori.labelCount;
    final progressColor = complete ? const Color(0xFF0A7349) : const Color(0xFF1E6FD9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    kategori.categoryName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SoV2StatusBadge(status: kategori.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              kategori.stockOpnameNo ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${kategori.scannedCount}/${kategori.labelCount} label',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: kategori.progress.clamp(0, 1),
                minHeight: 5,
                backgroundColor: _kBorder,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
