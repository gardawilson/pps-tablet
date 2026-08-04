import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/atlas_data_table.dart';
import '../../../common/widgets/atlas_paged_data_table.dart';
import '../../../core/utils/date_formatter.dart';
import '../model/retur_v2_transaction.dart';
import '../repository/retur_v2_repository.dart';
import '../view_model/retur_v2_list_view_model.dart';
import 'retur_v2_detail_screen.dart';

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
  late final ReturV2ListViewModel _listVm;
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listVm = ReturV2ListViewModel(repository: ReturV2Repository());
    _listVm.refresh();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _listVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReturV2ListViewModel>.value(
      value: _listVm,
      child: Scaffold(
        backgroundColor: _kSurface,
        body: _ReturListTab(searchCtl: _searchCtl),
      ),
    );
  }
}

// ─── List Retur ──────────────────────────────────────────────────────────────

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
              onRowTap: (row) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReturV2DetailScreen(noRetur: row.noRetur),
                ),
              ),
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
