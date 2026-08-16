import 'package:flutter/material.dart';

import '../stock_proses_key.dart';
import '../stock_totals.dart';
import '../widgets/stock_proses_card.dart';
import 'stock_detail_screen.dart';

class _StockProsesDef {
  const _StockProsesDef({
    required this.key,
    required this.title,
    required this.icon,
  });

  final StockProsesKey key;
  final String title;
  final IconData icon;
}

const _kStockProsesList = <_StockProsesDef>[
  _StockProsesDef(
    key: StockProsesKey.washing,
    title: 'Washing',
    icon: Icons.local_laundry_service_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.broker,
    title: 'Broker',
    icon: Icons.recycling_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.crusher,
    title: 'Crusher',
    icon: Icons.grain_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.bonggolan,
    title: 'Bonggolan',
    icon: Icons.scatter_plot_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.mixer,
    title: 'Mixer',
    icon: Icons.blender_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.furnitureWip,
    title: 'Furniture WIP',
    icon: Icons.chair_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.reject,
    title: 'Reject',
    icon: Icons.report_gmailerrorred_outlined,
  ),
  _StockProsesDef(
    key: StockProsesKey.bahanBaku,
    title: 'Bahan Baku',
    icon: Icons.inventory_2_outlined,
  ),
];

/// Grid pilihan proses untuk menu Stock — layout meniru grid mesin pada
/// layar produksi (`WashingProductionMesinScreen` dkk), tapi kartunya
/// merepresentasikan proses (Washing/Broker/dst), bukan mesin. Tiap kartu
/// juga menampilkan ringkasan jumlah label & total berat/pcs proses
/// tersebut. Tap sebuah kartu membuka [StockDetailScreen] yang menampilkan
/// data stok item untuk proses tersebut.
class StockSelectionScreen extends StatefulWidget {
  const StockSelectionScreen({super.key});

  @override
  State<StockSelectionScreen> createState() => _StockSelectionScreenState();
}

class _StockSelectionScreenState extends State<StockSelectionScreen> {
  final Map<StockProsesKey, StockProsesTotals> _totals = {};
  final Set<StockProsesKey> _failed = {};

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  void _loadTotals() {
    for (final def in _kStockProsesList) {
      fetchStockProsesTotals(def.key)
          .then((totals) {
            if (!mounted) return;
            setState(() => _totals[def.key] = totals);
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _failed.add(def.key));
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Stok per Proses',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = (constraints.maxWidth / 160).floor().clamp(2, 6);
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisExtent: 140,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _kStockProsesList.length,
                  itemBuilder: (context, index) {
                    final def = _kStockProsesList[index];
                    return StockProsesCard(
                      title: def.title,
                      icon: def.icon,
                      totals: _totals[def.key],
                      isLoading:
                          !_totals.containsKey(def.key) &&
                          !_failed.contains(def.key),
                      hasError: _failed.contains(def.key),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StockDetailScreen(
                            prosesKey: def.key,
                            title: def.title,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
