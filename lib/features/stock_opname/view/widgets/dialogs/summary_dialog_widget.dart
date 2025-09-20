import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryDialogWidget extends StatefulWidget {
  final int stockTotalDataGlobal;
  final int stockTotalSakGlobal;
  final double stockTotalBeratGlobal;
  final int stockTotalData;
  final int stockTotalSak;
  final double stockTotalBerat;
  final int scanTotalData;
  final int scanTotalSak;
  final double scanTotalBerat;
  final String noSO;
  final String tgl;
  final String selectedCategory;
  final String selectedLocation;

  const SummaryDialogWidget({
    Key? key,
    required this.stockTotalDataGlobal,
    required this.stockTotalSakGlobal,
    required this.stockTotalBeratGlobal,
    required this.stockTotalData,
    required this.stockTotalSak,
    required this.stockTotalBerat,
    required this.scanTotalData,
    required this.scanTotalSak,
    required this.scanTotalBerat,
    required this.noSO,
    required this.tgl,
    required this.selectedCategory,
    required this.selectedLocation,
  }) : super(key: key);

  @override
  State<SummaryDialogWidget> createState() => _SummaryDialogWidgetState();
}

class _SummaryDialogWidgetState extends State<SummaryDialogWidget>
    with TickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Calculate total items (based on data count)
  int get totalGlobalItems => widget.stockTotalDataGlobal;
  int get totalUnscannedItems => widget.stockTotalData;
  int get totalScannedItems => widget.scanTotalData;

  double get scannedPercentage => totalGlobalItems > 0
      ? (totalScannedItems / totalGlobalItems) * 100
      : 0;
  double get unscannedPercentage => totalGlobalItems > 0
      ? (totalUnscannedItems / totalGlobalItems) * 100
      : 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 650),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    // Left side - Chart section
                    Expanded(
                      flex: 2,
                      child: _buildChartSection(),
                    ),
                    const SizedBox(width: 32),
                    // Right side - Details section
                    Expanded(
                      flex: 3,
                      child: _buildDetailsSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade700],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Stock Opname',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.tgl} • ${widget.noSO} (${widget.selectedCategory.toUpperCase()} - ${widget.selectedLocation.toUpperCase()})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        // Animated Pie Chart with detailed percentages
        Flexible(
          flex: 3,
          child: _buildAnimatedPieChart(),
        ),
        const SizedBox(height: 16),

        // Legend with progress indicators
        Flexible(
          flex: 2,
          child: _buildDetailedLegend(),
        ),
      ],
    );
  }

  Widget _buildAnimatedPieChart() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedScannedPercentage = scannedPercentage * _animation.value;
        final animatedUnscannedPercentage = unscannedPercentage * _animation.value;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 240),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                        });
                      },
                    ),
                    sections: [
                      // Scanned section (Green)
                      PieChartSectionData(
                        value: totalScannedItems * _animation.value,
                        color: Colors.green.shade600,
                        radius: touchedIndex == 0 ? 70 : 60,
                        title: animatedScannedPercentage > 5
                            ? '${animatedScannedPercentage.toStringAsFixed(2)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      // Unscanned section (Orange)
                      PieChartSectionData(
                        value: totalUnscannedItems * _animation.value,
                        color: Colors.orange.shade600,
                        radius: touchedIndex == 1 ? 70 : 60,
                        title: animatedUnscannedPercentage > 5
                            ? '${animatedUnscannedPercentage.toStringAsFixed(2)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        borderSide: BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Center content showing overall progress
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${animatedScannedPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      'Terscan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedLegend() {
    return Column(
      children: [
        Expanded(
          child: _buildLegendItem(
            'Sudah Terscan',
            Colors.green.shade600,
            totalScannedItems,
            scannedPercentage,
            Icons.check_circle,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildLegendItem(
            'Belum Terscan',
            Colors.orange.shade600,
            totalUnscannedItems,
            unscannedPercentage,
            Icons.pending_actions,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value, double percentage, IconData icon) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(value * _animation.value).toInt()} label',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percentage * _animation.value).toStringAsFixed(2)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary cards in 2x2 grid
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: "TOTAL STOCK",
                  subtitle: "Keseluruhan",
                  color: Colors.blue.shade600,
                  data: widget.stockTotalDataGlobal,
                  sak: widget.stockTotalSakGlobal,
                  berat: widget.stockTotalBeratGlobal,
                  icon: Icons.inventory,
                  gradient: [Colors.blue.shade600, Colors.blue.shade400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: "SUDAH SCAN",
                  subtitle: "Terscan",
                  color: Colors.green.shade600,
                  data: widget.scanTotalData,
                  sak: widget.scanTotalSak,
                  berat: widget.scanTotalBerat,
                  icon: Icons.check_circle,
                  gradient: [Colors.green.shade600, Colors.green.shade400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: "BELUM SCAN",
                  subtitle: "Sisa",
                  color: Colors.orange.shade600,
                  data: widget.stockTotalData,
                  sak: widget.stockTotalSak,
                  berat: widget.stockTotalBerat,
                  icon: Icons.pending_actions,
                  gradient: [Colors.orange.shade600, Colors.orange.shade400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required int data,
    required int sak,
    required double berat,
    required List<Color> gradient,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildMetricRowWhite('Label', data.toString()),
          const SizedBox(height: 4),
          _buildMetricRowWhite('Pcs', sak.toString()),
          const SizedBox(height: 4),
          _buildMetricRowWhite('Berat', '${berat.toStringAsFixed(2)} kg'),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    final diffData = widget.scanTotalData - widget.stockTotalDataGlobal;
    final diffSak = widget.scanTotalSak - widget.stockTotalSakGlobal;
    final diffBerat = widget.scanTotalBerat - widget.stockTotalBeratGlobal;

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELISIH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Perbedaan',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildDiffRowWhite('Label', diffData),
          const SizedBox(height: 4),
          _buildDiffRowWhite('Pcs', diffSak),
          const SizedBox(height: 4),
          _buildDiffRowWhite('Berat', diffBerat, isBerat: true),
        ],
      ),
    );
  }

  Widget _buildMetricRowWhite(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDiffRowWhite(String label, num value, {bool isBerat = false}) {
    IconData icon;
    Color iconColor;

    if (value > 0) {
      icon = Icons.trending_up;
      iconColor = Colors.green;
    } else if (value < 0) {
      icon = Icons.trending_down;
      iconColor = Colors.red;
    } else {
      icon = Icons.trending_flat;
      iconColor = Colors.white70;
    }

    final display = isBerat
        ? '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} kg'
        : '${value >= 0 ? '+' : ''}$value';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
        Text(
          display,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}