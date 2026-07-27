import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _ReturV2ScreenState extends State<ReturV2Screen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ReturV2Repository _repository;
  late final ReturV2ListViewModel _listVm;
  late final ReturV2PendingViewModel _pendingVm;
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _repository = ReturV2Repository();
    _listVm = ReturV2ListViewModel(repository: _repository);
    _pendingVm = ReturV2PendingViewModel(repository: _repository);
    _listVm.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtl.dispose();
    _listVm.dispose();
    _pendingVm.dispose();
    super.dispose();
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1D23),
          elevation: 0,
          title: const Text(
            'Retur V2',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: _kPrimary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: _kPrimary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'List Retur'),
              Tab(text: 'Pending Import'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ReturListTab(searchCtl: _searchCtl),
            const _PendingImportTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: List Retur ──────────────────────────────────────────────────────

class _ReturListTab extends StatelessWidget {
  final TextEditingController searchCtl;

  const _ReturListTab({required this.searchCtl});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReturV2ListViewModel>();
    return Column(
      children: [
        _SearchBar(
          controller: searchCtl,
          onChanged: vm.setSearchDebounced,
          onClear: () {
            searchCtl.clear();
            vm.clearSearch();
          },
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

// ─── Tab 2: Pending Import ──────────────────────────────────────────────────

class _PendingImportTab extends StatefulWidget {
  const _PendingImportTab();

  @override
  State<_PendingImportTab> createState() => _PendingImportTabState();
}

class _PendingImportTabState extends State<_PendingImportTab> {
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  Future<void> _pickDate(BuildContext context) async {
    final vm = context.read<ReturV2PendingViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.date,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Pilih tanggal',
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: const Locale('id', 'ID'),
        child: child,
      ),
    );
    if (picked != null) {
      await vm.setDateAndFetch(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReturV2PendingViewModel>();
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _dateFormat.format(vm.date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D23),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: vm.loading ? null : () => vm.fetch(),
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Cari'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildBody(vm),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ReturV2PendingViewModel vm) {
    if (!vm.hasFetched && !vm.loading) {
      return Center(
        child: Text(
          'Pilih tanggal lalu tekan "Cari" untuk melihat data pending import dari ERP Ascend.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      );
    }
    if (vm.error != null && vm.items.isEmpty) {
      return Center(
        child: Text(
          'Gagal memuat data: ${vm.error}',
          style: TextStyle(fontSize: 13, color: Colors.red.shade600),
        ),
      );
    }
    return AtlasDataTable<ReturV2PendingImport>(
      columns: _columns(),
      items: vm.items,
      isLoading: vm.loading,
      errorMessage: vm.error ?? '',
    );
  }

  List<AtlasTableColumn<ReturV2PendingImport>> _columns() {
    return [
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'INVOICE',
        width: 130,
        cellBuilder: (ctx, item, state) => Text(
          item.invoiceNumber,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D23),
          ),
        ),
      ),
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'ITEM',
        width: 320,
        cellBuilder: (ctx, item, state) => Text(
          item.itemName,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'KODE BARANG',
        width: 160,
        cellBuilder: (ctx, item, state) => Text(
          item.itemCode ?? '-',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ),
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'KATEGORI',
        width: 170,
        cellBuilder: (ctx, item, state) => Text(
          item.stockCategoryName ?? '-',
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        ),
      ),
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'CUSTOMER',
        width: 200,
        cellBuilder: (ctx, item, state) => Text(
          item.customerName ?? '-',
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      AtlasTableColumn<ReturV2PendingImport>(
        title: 'QTY',
        width: 80,
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        showDivider: false,
        cellBuilder: (ctx, item, state) => Text(
          '${item.quantity}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    ];
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
