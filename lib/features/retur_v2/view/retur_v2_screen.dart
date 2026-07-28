import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/atlas_data_table.dart';
import '../../../common/widgets/atlas_paged_data_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../model/retur_v2_pending_import.dart';
import '../model/retur_v2_transaction.dart';
import '../repository/retur_v2_repository.dart';
import '../view_model/retur_v2_list_view_model.dart';
import '../view_model/retur_v2_pending_view_model.dart';

// ─── Theme ─────────────────────────────────────────────────────────────────

const _kPrimary = Color(0xFF1E6FD9);
const _kSurface = Color(0xFFF8F9FB);
const _kBorder = Color(0xFFE2E6EA);

// ─── Screen ────────────────────────────────────────────────────────────────

class ReturV2Screen extends StatefulWidget {
  const ReturV2Screen({super.key});

  @override
  State<ReturV2Screen> createState() => _ReturV2ScreenState();
}

class _ReturV2ScreenState extends State<ReturV2Screen> {
  late final ReturV2Repository _repository;
  late final ReturV2ListViewModel _listVm;
  late final ReturV2PendingViewModel _pendingVm;
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = ReturV2Repository();
    _listVm = ReturV2ListViewModel(repository: _repository);
    _pendingVm = ReturV2PendingViewModel(repository: _repository);
    _listVm.refresh();
    _pendingVm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _listVm.dispose();
    _pendingVm.dispose();
    super.dispose();
  }

  void _openPendingImportDialog() {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider<ReturV2PendingViewModel>.value(
        value: _pendingVm,
        child: const _PendingImportDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ReturV2ListViewModel>.value(value: _listVm),
        ChangeNotifierProvider<ReturV2PendingViewModel>.value(
          value: _pendingVm,
        ),
      ],
      child: Scaffold(
        backgroundColor: _kSurface,
        body: _ReturListTab(
          searchCtl: _searchCtl,
          onImportTap: _openPendingImportDialog,
        ),
      ),
    );
  }
}

// ─── Import Button ──────────────────────────────────────────────────────────

class _ImportButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ImportButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      backgroundColor: Colors.red.shade600,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: _kPrimary),
        icon: const Icon(Icons.download_rounded, size: 18),
        label: const Text('Import'),
      ),
    );
  }
}

// ─── List Retur ──────────────────────────────────────────────────────────────

class _ReturListTab extends StatelessWidget {
  final TextEditingController searchCtl;
  final VoidCallback onImportTap;

  const _ReturListTab({required this.searchCtl, required this.onImportTap});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReturV2ListViewModel>();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchBar(
                controller: searchCtl,
                onChanged: vm.setSearchDebounced,
                onClear: () {
                  searchCtl.clear();
                  vm.clearSearch();
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
              child: Consumer<ReturV2PendingViewModel>(
                builder: (context, pendingVm, _) => _ImportButton(
                  count: pendingVm.totalItems,
                  onTap: onImportTap,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AtlasPagedDataTable<ReturV2Transaction>(
              pagingController: vm.pagingController,
              columns: _columns(),
              rowColorBuilder: (row) =>
                  row.isLocked ? Colors.red.shade50 : null,
            ),
          ),
        ),
      ],
    );
  }

  List<AtlasTableColumn<ReturV2Transaction>> _columns() {
    return [
      AtlasTableColumn<ReturV2Transaction>(
        title: 'NO. RETUR',
        width: 150,
        cellBuilder: (ctx, item, state) => Text(
          item.noRetur,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: state.isSelected
                ? const Color(0xFF0C66E4)
                : const Color(0xFF1A1D23),
            letterSpacing: -0.2,
          ),
        ),
      ),
      AtlasTableColumn<ReturV2Transaction>(
        title: 'INVOICE',
        width: 140,
        cellBuilder: (ctx, item, state) => Text(
          item.invoice ?? '-',
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
      ),
      AtlasTableColumn<ReturV2Transaction>(
        title: 'TANGGAL',
        width: 120,
        cellBuilder: (ctx, item, state) => Text(
          formatDateToShortId(item.tanggal),
          style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
      ),
      AtlasTableColumn<ReturV2Transaction>(
        title: 'PEMBELI',
        width: 220,
        cellBuilder: (ctx, item, state) => Text(
          item.namaPembeli ?? '-',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AtlasTableColumn<ReturV2Transaction>(
        title: 'NO BJ SORTIR',
        width: 150,
        cellBuilder: (ctx, item, state) => Text(
          item.noBJSortir ?? '-',
          style: TextStyle(
            fontSize: 13,
            color: item.noBJSortir == null
                ? Colors.grey.shade400
                : const Color(0xFF374151),
          ),
        ),
      ),
      AtlasTableColumn<ReturV2Transaction>(
        title: 'STATUS',
        width: 110,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (ctx, item, state) {
          final locked = item.isLocked;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: locked
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              locked ? 'Locked' : 'Open',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: locked ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          );
        },
      ),
    ];
  }
}

// ─── Pending Import Dialog ───────────────────────────────────────────────────

class _PendingImportDialog extends StatelessWidget {
  const _PendingImportDialog();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReturV2PendingViewModel>();
    final size = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: size.width * 0.85,
        height: size.height * 0.85,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: _kPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pending Import (${vm.totalItems} item)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D23),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _PendingImportList(
                  pagingController: vm.pagingController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingImportList extends StatelessWidget {
  final PagingController<int, ReturV2PendingImportGroup> pagingController;

  const _PendingImportList({required this.pagingController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: PagingListener<int, ReturV2PendingImportGroup>(
        controller: pagingController,
        builder: (context, state, fetchNextPage) {
          return RefreshIndicator(
            onRefresh: () async => pagingController.refresh(),
            child: PagedListView<int, ReturV2PendingImportGroup>(
              state: state,
              fetchNextPage: fetchNextPage,
              padding: EdgeInsets.zero,
              builderDelegate:
                  PagedChildBuilderDelegate<ReturV2PendingImportGroup>(
                    itemBuilder: (context, group, index) =>
                        _InvoiceGroupTile(group: group),
                    firstPageProgressIndicatorBuilder: (_) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Terjadi kesalahan memuat data.'),
                      ),
                    ),
                    newPageErrorIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('Gagal memuat halaman berikutnya'),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Tidak ada data pending import.'),
                      ),
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceGroupTile extends StatelessWidget {
  final ReturV2PendingImportGroup group;

  const _InvoiceGroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        shape: const Border(bottom: BorderSide(color: Color(0xFFEBECF0))),
        title: Row(
          children: [
            Text(
              group.invoiceNumber,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D23),
              ),
            ),
            if (group.invoiceType != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  group.invoiceType!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group.customerName ?? '-',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${group.items.length} item · qty ${group.totalQuantity}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        children: [for (final item in group.items) _InvoiceItemRow(item: item)],
      ),
    );
  }
}

class _InvoiceItemRow extends StatelessWidget {
  final ReturV2PendingImportItem item;

  const _InvoiceItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item.itemName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.itemCode ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.stockCategoryName ?? '-',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari no. retur / invoice / pembeli...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: Colors.grey.shade400,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: _kSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
