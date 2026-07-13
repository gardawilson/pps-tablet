import 'package:flutter/material.dart';

import '../models/stok_item_data.dart';
import 'production_filter_chip.dart';
import 'stok_item_label_dialog.dart';
import 'stok_item_panel.dart';

/// Lets a screen trigger a reload of every stok source inside a
/// [StokItemSection] (e.g. from a toolbar refresh button or a
/// screen-level "refresh all" action) without needing to know how many
/// sources there are or what type each one is.
class StokItemSectionController {
  final List<Future<void> Function()> _refreshers = [];

  void _register(Future<void> Function() refresh) => _refreshers.add(refresh);

  void _unregister(Future<void> Function() refresh) =>
      _refreshers.remove(refresh);

  Future<void> refreshAll() async {
    await Future.wait(_refreshers.map((r) => r()));
  }
}

/// One stok data source (endpoint + label endpoint) for [StokItemSection].
/// When a section has more than one source, each renders as its own chip.
abstract class StokItemSource {
  const StokItemSource({required this.label});

  final String label;

  Widget buildPane(StokItemSectionController? controller);
}

class TypedStokItemSource<T extends StokItemData, L extends StokLabelData>
    extends StokItemSource {
  const TypedStokItemSource({
    required super.label,
    required this.fetchStok,
    required this.fetchLabel,
    this.showSakColumn = true,
    this.sakColumnLabel = 'SAK',
    this.showBeratColumn = true,
    this.oldestDateOf,
  });

  final Future<List<T>> Function() fetchStok;
  final Future<List<L>> Function(T item) fetchLabel;
  final bool showSakColumn;
  final String sakColumnLabel;

  /// Set `false` bila UOM item ini murni satuan ([sakSisa]) dan berat
  /// tidak relevan untuk ditampilkan — mis. Furniture WIP (Pcs).
  final bool showBeratColumn;
  final DateTime? Function(T item)? oldestDateOf;

  @override
  Widget buildPane(StokItemSectionController? controller) {
    return _StokItemSourcePane<T, L>(source: this, controller: controller);
  }
}

class _StokItemSourcePane<T extends StokItemData, L extends StokLabelData>
    extends StatefulWidget {
  const _StokItemSourcePane({required this.source, required this.controller});

  final TypedStokItemSource<T, L> source;
  final StokItemSectionController? controller;

  @override
  State<_StokItemSourcePane<T, L>> createState() =>
      _StokItemSourcePaneState<T, L>();
}

class _StokItemSourcePaneState<T extends StokItemData, L extends StokLabelData>
    extends State<_StokItemSourcePane<T, L>>
    with AutomaticKeepAliveClientMixin {
  List<T> _items = [];
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller?._register(_load);
    _load();
  }

  @override
  void dispose() {
    widget.controller?._unregister(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.source.fetchStok();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: StokItemList<T>(
        items: _items,
        isLoading: _loading,
        errorMessage: _error,
        oldestDateOf: widget.source.oldestDateOf,
        showSakColumn: widget.source.showSakColumn,
        sakColumnLabel: widget.source.sakColumnLabel,
        showBeratColumn: widget.source.showBeratColumn,
        onTap: (item) => showDialog<void>(
          context: context,
          builder: (_) => StokItemLabelDialog<T, L>(
            item: item,
            showSakColumn: widget.source.showSakColumn,
            sakColumnLabel: widget.source.sakColumnLabel,
            showBeratColumn: widget.source.showBeratColumn,
            fetchLabels: widget.source.fetchLabel,
          ),
        ),
      ),
    );
  }
}

/// Sidebar "Stok Item" content: a chip row (one chip per source) plus the
/// selected source's stok list, each source managing its own loading/error
/// state independently. Used by production mesin screens (broker/washing/
/// crusher) inside their sidebar drawer, replacing what used to be
/// per-screen `_stokItems`/`_stokLoading`/`_loadStokItems()` boilerplate.
class StokItemSection extends StatefulWidget {
  const StokItemSection({super.key, required this.sources, this.controller});

  final List<StokItemSource> sources;
  final StokItemSectionController? controller;

  @override
  State<StokItemSection> createState() => _StokItemSectionState();
}

class _StokItemSectionState extends State<StokItemSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              children: [
                for (var i = 0; i < widget.sources.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ProductionFilterChip(
                      label: widget.sources[i].label,
                      selected: _selected == i,
                      onTap: widget.sources.length == 1
                          ? () {}
                          : () => setState(() => _selected = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: [
              for (final source in widget.sources)
                source.buildPane(widget.controller),
            ],
          ),
        ),
      ],
    );
  }
}
