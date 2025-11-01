import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/horizontal_table.dart';
import '../../../../common/widgets/table_column_spec.dart';
import '../view_model/broker_production_view_model.dart';
import '../model/broker_inputs_model.dart';

class BrokerInputsScreen extends StatefulWidget {
  final String noProduksi;

  const BrokerInputsScreen({
    super.key,
    required this.noProduksi,
  });

  @override
  State<BrokerInputsScreen> createState() => _BrokerInputsScreenState();
}

class _BrokerInputsScreenState extends State<BrokerInputsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);

    // ✅ Defer loading until after first frame to avoid notify during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<BrokerProductionViewModel>();
      final already = vm.inputsOf(widget.noProduksi) != null;
      final loading = vm.isInputsLoading(widget.noProduksi);
      if (!already && !loading) {
        vm.loadInputs(widget.noProduksi); // no 'force' so it respects cache
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _num(double? v) => v == null ? '' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Consumer<BrokerProductionViewModel>(
      builder: (context, vm, _) {
        final loading = vm.isInputsLoading(widget.noProduksi);
        final err = vm.inputsError(widget.noProduksi);
        final inputs = vm.inputsOf(widget.noProduksi);

        return Scaffold(
          appBar: AppBar(
            title: Text('Inputs • ${widget.noProduksi}'),
            actions: [
              IconButton(
                tooltip: 'Refresh Inputs',
                icon: const Icon(Icons.refresh),
                onPressed: () => vm.loadInputs(widget.noProduksi, force: true),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: _InputsTabBar(
                controller: _tab,
                inputs: inputs,
              ),
            ),
          ),
          body: Builder(
            builder: (_) {
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (err != null) {
                return Center(child: Text('Gagal memuat inputs:\n$err'));
              }
              if (inputs == null) {
                return const Center(child: Text('Tidak ada data inputs.'));
              }

              return TabBarView(
                controller: _tab,
                children: [
                  // ===== Broker =====
                  HorizontalTable<BrokerItem>(
                    rows: inputs.broker,
                    columns: [
                      TableColumnSpec<BrokerItem>(
                        title: 'NoBroker',
                        width: 220,
                        cellBuilder: (_, r) => Text(r.noBroker ?? ''),
                      ),
                      TableColumnSpec<BrokerItem>(
                        title: 'NoSak',
                        width: 100,
                        headerAlign: TextAlign.center,
                        cellAlign: TextAlign.center,
                        cellBuilder: (_, r) => Text(r.noSak?.toString() ?? ''),
                      ),
                      TableColumnSpec<BrokerItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                      TableColumnSpec<BrokerItem>(
                        title: 'BeratAct',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.beratAct)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== BB =====
                  HorizontalTable<BbItem>(
                    rows: inputs.bb,
                    columns: [
                      TableColumnSpec<BbItem>(
                        title: 'NoBahanBaku',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noBahanBaku ?? ''),
                      ),
                      TableColumnSpec<BbItem>(
                        title: 'NoPallet',
                        width: 160,
                        headerAlign: TextAlign.center,
                        cellAlign: TextAlign.center,
                        // use ?.toString() to avoid "null"
                        cellBuilder: (_, r) => Text(r.noPallet?.toString() ?? ''),
                      ),
                      TableColumnSpec<BbItem>(
                        title: 'NoSak',
                        width: 100,
                        headerAlign: TextAlign.center,
                        cellAlign: TextAlign.center,
                        cellBuilder: (_, r) => Text(r.noSak?.toString() ?? ''),
                      ),
                      TableColumnSpec<BbItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== Washing =====
                  HorizontalTable<WashingItem>(
                    rows: inputs.washing,
                    columns: [
                      TableColumnSpec<WashingItem>(
                        title: 'NoWashing',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noWashing ?? ''),
                      ),
                      TableColumnSpec<WashingItem>(
                        title: 'NoSak',
                        width: 100,
                        headerAlign: TextAlign.center,
                        cellAlign: TextAlign.center,
                        cellBuilder: (_, r) => Text(r.noSak?.toString() ?? ''),
                      ),
                      TableColumnSpec<WashingItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== Crusher =====
                  HorizontalTable<CrusherItem>(
                    rows: inputs.crusher,
                    columns: [
                      TableColumnSpec<CrusherItem>(
                        title: 'NoCrusher',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noCrusher ?? ''),
                      ),
                      TableColumnSpec<CrusherItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== Gilingan =====
                  HorizontalTable<GilinganItem>(
                    rows: inputs.gilingan,
                    columns: [
                      TableColumnSpec<GilinganItem>(
                        title: 'NoGilingan',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noGilingan ?? ''),
                      ),
                      TableColumnSpec<GilinganItem>(
                        title: 'NoGilinganPartial',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noGilinganPartial ?? ''),
                      ),
                      TableColumnSpec<GilinganItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== Mixer =====
                  HorizontalTable<MixerItem>(
                    rows: inputs.mixer,
                    columns: [
                      TableColumnSpec<MixerItem>(
                        title: 'NoMixer',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noMixer ?? ''),
                      ),
                      TableColumnSpec<MixerItem>(
                        title: 'NoMixerPartial',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noMixerPartial ?? ''),
                      ),
                      TableColumnSpec<MixerItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),

                  // ===== Reject =====
                  HorizontalTable<RejectItem>(
                    rows: inputs.reject,
                    columns: [
                      TableColumnSpec<RejectItem>(
                        title: 'NoReject',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noReject ?? ''),
                      ),
                      TableColumnSpec<RejectItem>(
                        title: 'NoRejectPartial',
                        width: 240,
                        cellBuilder: (_, r) => Text(r.noRejectPartial ?? ''),
                      ),
                      TableColumnSpec<RejectItem>(
                        title: 'Berat',
                        width: 120,
                        headerAlign: TextAlign.right,
                        cellAlign: TextAlign.right,
                        cellBuilder: (_, r) => Text(_num(r.berat)),
                      ),
                    ],
                    horizontalPadding: 16,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _InputsTabBar extends StatelessWidget {
  final TabController controller;
  final BrokerInputs? inputs;

  const _InputsTabBar({
    required this.controller,
    required this.inputs,
  });

  @override
  Widget build(BuildContext context) {
    final s = inputs?.summary ?? const <String, int>{};
    final tabs = <(String, int)>[
      ('Broker', s['broker'] ?? 0),
      ('BB', s['bb'] ?? 0),
      ('Washing', s['washing'] ?? 0),
      ('Crusher', s['crusher'] ?? 0),
      ('Gilingan', s['gilingan'] ?? 0),
      ('Mixer', s['mixer'] ?? 0),
      ('Reject', s['reject'] ?? 0),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabs: [for (final t in tabs) Tab(text: '${t.$1} (${t.$2})')],
      ),
    );
  }
}
