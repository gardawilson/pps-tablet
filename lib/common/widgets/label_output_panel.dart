import 'package:flutter/material.dart';

/// Generic data item for the output panel.
class LabelOutputItem {
  final String code;
  final bool isPrinted;

  const LabelOutputItem({required this.code, required this.isPrinted});
}

/// Reusable right-column output panel used across label form dialogs
/// (Bonggolan, Crusher, etc.).
///
/// Usage:
/// ```dart
/// LabelOutputPanel(
///   title: 'Output Bonggolan',
///   items: _outputs.map((o) => LabelOutputItem(code: o.noBonggolan, isPrinted: o.isPrinted)).toList(),
///   isLoading: _loadingOutputs,
///   hasSource: sourceCode.isNotEmpty,
///   noSourceMessage: 'Pilih No Produksi\nuntuk melihat output',
/// )
/// ```
class LabelOutputPanel extends StatelessWidget {
  final String title;
  final List<LabelOutputItem> items;
  final bool isLoading;

  /// Whether a source code (produksi / bongkar susun) has been selected.
  /// When false, shows the "no source" empty state.
  final bool hasSource;

  /// Message shown when [hasSource] is false.
  final String noSourceMessage;

  const LabelOutputPanel({
    super.key,
    required this.title,
    required this.items,
    required this.isLoading,
    required this.hasSource,
    this.noSourceMessage = 'Pilih sumber\nuntuk melihat output',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.output, size: 18, color: Colors.indigo.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          if (hasSource)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!hasSource) {
      return _buildEmptyState(icon: Icons.link_off, message: noSourceMessage);
    }
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        message: 'Belum ada\nlabel output',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade100),
      itemBuilder: (_, i) => _buildItem(items[i]),
    );
  }

  Widget _buildItem(LabelOutputItem item) {
    final printed = item.isPrinted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.code,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: printed ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: printed ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  printed ? Icons.print : Icons.print_outlined,
                  size: 12,
                  color: printed ? Colors.green.shade700 : Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  printed ? 'Printed' : 'Belum',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: printed
                        ? Colors.green.shade700
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
