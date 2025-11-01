// lib/features/shared/washing_production/screens/washing_production_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../view_model/washing_production_view_model.dart';
import '../model/washing_production_model.dart';
import '../repository/washing_production_repository.dart';

class WashingProductionScreen extends StatelessWidget {
  const WashingProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WashingProductionViewModel(
        repository: WashingProductionRepository(),
      )..refreshPaged(), // mulai di mode paged
      child: const _ScaffoldBody(),
    );
  }
}

class _ScaffoldBody extends StatefulWidget {
  const _ScaffoldBody();

  @override
  State<_ScaffoldBody> createState() => _ScaffoldBodyState();
}

class _ScaffoldBodyState extends State<_ScaffoldBody> {
  // Controller untuk sinkronisasi scroll horizontal header & isi tabel
  final _hScroll = ScrollController();

  // Lebar total tabel (silakan sesuaikan jika kolom ditambah/diubah)
  static const double _tableWidth = 1100;

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WashingProductionViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Washing Production'),
        actions: [
          if (vm.isByDateMode)
            IconButton(
              tooltip: 'Tampilkan Semua (Paged)',
              icon: const Icon(Icons.list_alt),
              onPressed: vm.exitByDateModeAndRefreshPaged,
            ),
          if (!vm.isByDateMode)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: vm.refreshPaged,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ====== HEADER TABEL (ikut scroll horizontal) ======
            Material(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _tableWidth,
                  child: const _TableHeader(),
                ),
              ),
            ),
            const Divider(height: 1),
            // ====== ISI TABEL (PagedListView) dalam scroll horizontal yang sama ======
            Expanded(
              child: _TableBody(
                hScroll: _hScroll,
                tableWidth: _tableWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// TABEL: HEADER
// =======================================================

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          _HCell('No Produksi', width: 160),
          _HCell('Tanggal', width: 110),
          _HCell('Shift', width: 70, align: TextAlign.center),
          _HCell('Mesin', width: 140),
          _HCell('Operator', width: 200),
          _HCell('Jam', width: 70, align: TextAlign.right),
          _HCell('HM', width: 90, align: TextAlign.right),
          _HCell('Anggota/Hadir', width: 140, align: TextAlign.center),
          _HCell('Approved', width: 90, align: TextAlign.center),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign align;
  const _HCell(this.text, {required this.width, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return SizedBox(
      width: width,
      child: Text(text, style: style, textAlign: align, maxLines: 1),
    );
  }
}

// =======================================================
// TABEL: BODY (Paged v5)
// =======================================================

class _TableBody extends StatelessWidget {
  const _TableBody({required this.hScroll, required this.tableWidth});
  final ScrollController hScroll;
  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WashingProductionViewModel>();

    return PagingListener<int, WashingProduction>(
      controller: vm.pagingController,
      builder: (context, state, fetchNextPage) => RefreshIndicator(
        onRefresh: () async => vm.refreshPaged(),
        child: SingleChildScrollView(
          controller: hScroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: PagedListView<int, WashingProduction>(
              // penting: scroll vertikal untuk list
              state: state,
              fetchNextPage: fetchNextPage,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              builderDelegate: PagedChildBuilderDelegate<WashingProduction>(
                itemBuilder: (context, item, index) => _TableRowItem(
                  row: item,
                  index: index,
                ),
                // Prefetch ketika sisa item tak terlihat < 3
                invisibleItemsThreshold: 3,

                // indikator bawaan
                firstPageProgressIndicatorBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
                newPageProgressIndicatorBuilder: (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                firstPageErrorIndicatorBuilder: (_) => _ErrorView(
                  message: '${state.error}',
                  onRetry: fetchNextPage,
                ),
                newPageErrorIndicatorBuilder: (_) => _NewPageError(
                  onRetry: fetchNextPage,
                ),
                noItemsFoundIndicatorBuilder: (_) =>
                const Center(child: Text('Tidak ada data.')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// TABEL: ROW ITEM
// =======================================================

class _TableRowItem extends StatelessWidget {
  const _TableRowItem({required this.row, required this.index});
  final WashingProduction row;
  final int index;

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd-$mm-$yy';
  }

  @override
  Widget build(BuildContext context) {
    final bg = index.isEven
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25);

    return Container(
      key: ValueKey(row.noProduksi),
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _Cell(row.noProduksi, width: 160, fontWeight: FontWeight.w600),
          _Cell(_formatDate(row.tglProduksi), width: 110),
          _Cell('${row.shift}', width: 70, align: TextAlign.center),
          _Cell(row.namaMesin, width: 140),
          _Cell(row.namaOperator, width: 200, maxLines: 1, overflow: TextOverflow.ellipsis),
          _Cell('${row.jamKerja}', width: 70, align: TextAlign.right),
          _Cell('${row.hourMeter}', width: 90, align: TextAlign.right),
          _Cell('${row.jmlhAnggota}/${row.hadir}', width: 140, align: TextAlign.center),
          SizedBox(
            width: 90,
            child: Center(
              child: row.approveBy != null
                  ? const Icon(Icons.verified, size: 18)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final double width;
  final TextAlign align;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;

  const _Cell(
      this.text, {
        required this.width,
        this.align = TextAlign.left,
        this.fontWeight,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: fontWeight,
    );
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: align,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

// =======================================================
// Komponen error & retry sederhana (lokal screen)
// (Boleh kamu pindah ke commons/widget seperti sebelumnya)
// =======================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ]),
      ),
    );
  }
}

class _NewPageError extends StatelessWidget {
  final VoidCallback onRetry;
  const _NewPageError({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Gagal memuat halaman berikutnya'),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    );
  }
}
