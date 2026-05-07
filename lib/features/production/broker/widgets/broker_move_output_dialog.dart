import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/broker_inputs_model.dart';
import '../model/broker_production_model.dart';
import '../repository/broker_production_repository.dart';
import '../view_model/broker_production_input_view_model.dart';
import '../../../../common/widgets/error_status_dialog.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kBorder = Color(0xFFE2E6EA);
const _kSurface = Color(0xFFF8F9FB);
const _kPageSize = 20;

class BrokerMoveOutputDialog extends StatefulWidget {
  final String noProduksi;
  final List<BrokerOutput> outputs;

  const BrokerMoveOutputDialog({
    super.key,
    required this.noProduksi,
    required this.outputs,
  });

  @override
  State<BrokerMoveOutputDialog> createState() => _BrokerMoveOutputDialogState();
}

class _BrokerMoveOutputDialogState extends State<BrokerMoveOutputDialog> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _repo = BrokerProductionRepository();

  // Selected noBroker keys
  final Set<String> _selectedNoBrokers = {};
  bool _isSubmitting = false;

  // Production list state (right panel)
  final List<BrokerProduction> _productions = [];
  bool _isFirstLoading = false;
  bool _isLoadingMore = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String? _listError;
  BrokerProduction? _selectedTarget;
  Timer? _debounce;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPage(reset: true);
    _searchCtrl.addListener(_onSearchChanged);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _scrollCtrl.removeListener(_onScroll);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Production list loading (right panel)
  // ---------------------------------------------------------------------------

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = _searchCtrl.text.trim();
      if (q != _lastQuery) _fetchPage(reset: true);
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 80) {
      _fetchNextPageIfNeeded();
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_isFirstLoading) return;

    final query = _searchCtrl.text.trim();

    if (reset) {
      setState(() {
        _isFirstLoading = true;
        _listError = null;
        _productions.clear();
        _currentPage = 1;
        _hasNextPage = true;
        _lastQuery = query;
        if (_selectedTarget != null) _selectedTarget = null;
      });
    }

    try {
      final res = await _repo.fetchAll(
        page: _currentPage,
        pageSize: _kPageSize,
        search: query.isEmpty ? null : query,
      );

      if (!mounted) return;

      final items = (res['items'] as List<BrokerProduction>)
          .where((p) => p.noProduksi != widget.noProduksi)
          .toList();

      final totalPages = (res['totalPages'] as int?) ?? 1;

      setState(() {
        _productions.addAll(items);
        _hasNextPage = _currentPage < totalPages;
        _currentPage++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _listError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isFirstLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _fetchNextPageIfNeeded() async {
    if (!_hasNextPage || _isFirstLoading || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await _fetchPage();
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_selectedTarget == null || _selectedNoBrokers.isEmpty || _isSubmitting)
      return;

    final items = <Map<String, dynamic>>[];
    for (final output in widget.outputs) {
      final noBroker = output.noBroker ?? '';
      if (!_selectedNoBrokers.contains(noBroker)) continue;
      for (final sak in output.detailSak) {
        if (sak.noSak != null) {
          items.add({'noBroker': noBroker, 'noSak': sak.noSak});
        }
      }
    }

    setState(() => _isSubmitting = true);
    final vm = context.read<BrokerProductionInputViewModel>();
    final success = await vm.moveOutputs(
      widget.noProduksi,
      _selectedTarget!.noProduksi,
      items,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final errMsg = vm.moveOutputError ?? 'Gagal memindahkan output';
      await showDialog(
        context: context,
        builder: (_) =>
            ErrorStatusDialog(title: 'Gagal Memindahkan', message: errMsg),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildBrokerSelector()),
                  const VerticalDivider(width: 1, color: _kBorder),
                  SizedBox(width: 260, child: _buildProductionPicker()),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      decoration: const BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pindah Output Broker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left panel — broker selector
  // ---------------------------------------------------------------------------

  Widget _buildBrokerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(
            children: [
              const Text(
                'Pilih Label Broker',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
              const Spacer(),
              if (_selectedNoBrokers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedNoBrokers.length} dipilih',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.outputs.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada output',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.outputs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final output = widget.outputs[i];
                    final noBroker = output.noBroker ?? '';
                    final isSelected = _selectedNoBrokers.contains(noBroker);
                    return _BrokerOutputItem(
                      output: output,
                      isSelected: isSelected,
                      disabled: _isSubmitting,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedNoBrokers.remove(noBroker);
                          } else {
                            _selectedNoBrokers.add(noBroker);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Right panel — production picker
  // ---------------------------------------------------------------------------

  Widget _buildProductionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No. Produksi Tujuan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D23),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: TextField(
                  controller: _searchCtrl,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Cari no. produksi...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: _isFirstLoading
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search, size: 16),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: _kPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildProductionList()),
      ],
    );
  }

  Widget _buildProductionList() {
    if (_isFirstLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_listError != null && _productions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
            const SizedBox(height: 8),
            Text(
              _listError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _fetchPage(reset: true),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (_productions.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      itemCount: _productions.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 12, endIndent: 12, color: _kBorder),
      itemBuilder: (_, i) {
        if (i == _productions.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final prod = _productions[i];
        final isSelected = _selectedTarget?.noProduksi == prod.noProduksi;
        return _ProductionListItem(
          production: prod,
          isSelected: isSelected,
          onTap: _isSubmitting
              ? null
              : () => setState(() => _selectedTarget = prod),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    final canSubmit =
        _selectedTarget != null &&
        _selectedNoBrokers.isNotEmpty &&
        !_isSubmitting;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
        color: _kSurface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _selectedTarget != null
                ? Row(
                    children: [
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: _kPrimary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedTarget!.noProduksi,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Pilih produksi tujuan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.swap_horiz_rounded, size: 15),
            label: Text(
              _isSubmitting ? 'Memindahkan...' : 'Pindahkan',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Broker output item (left panel)
// ---------------------------------------------------------------------------

class _BrokerOutputItem extends StatelessWidget {
  final BrokerOutput output;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  const _BrokerOutputItem({
    required this.output,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final noBroker = output.noBroker ?? '-';
    final totalBerat = output.detailSak.fold<double>(
      0,
      (sum, s) => sum + (s.berat ?? 0),
    );
    final fmt = NumberFormat('#,##0.##', 'id_ID');

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kPrimary : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? _kPrimary
                    : _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.label_outline_rounded,
                size: 16,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noBroker,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _kPrimary : const Color(0xFF1A1D23),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((output.namaJenis ?? '').isNotEmpty)
                    Text(
                      output.namaJenis!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${output.totalSak} sak',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _kPrimary : const Color(0xFF1A1D23),
                  ),
                ),
                Text(
                  '${fmt.format(totalBerat)} kg',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Production list item (right panel)
// ---------------------------------------------------------------------------

class _ProductionListItem extends StatelessWidget {
  final BrokerProduction production;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ProductionListItem({
    required this.production,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tglText = production.tglProduksi == null
        ? null
        : DateFormat(
            'dd MMM yy',
            'id_ID',
          ).format(production.tglProduksi!.toLocal());

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        color: isSelected
            ? _kPrimary.withValues(alpha: 0.07)
            : Colors.transparent,
        child: Row(
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: _kPrimary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    production.noProduksi,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _kPrimary : const Color(0xFF1A1D23),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      production.namaMesin,
                      'Shift ${production.shift}',
                      if (tglText != null) tglText,
                    ].join('  •  '),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
