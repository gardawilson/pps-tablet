// features/stock_opname/detail/widgets/filter_section/search_label_widget.dart

import 'package:flutter/material.dart';
import 'dart:async';

class SearchLabelWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const SearchLabelWidget({
    Key? key,
    required this.onSearch,
    required this.onClear,
  }) : super(key: key);

  @override
  State<SearchLabelWidget> createState() => _SearchLabelWidgetState();
}

class _SearchLabelWidgetState extends State<SearchLabelWidget> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCDFE4)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF8896A6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onTextChanged,
              decoration: const InputDecoration(
                hintText: 'Cari label...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF8896A6)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A2340)),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.clear, size: 20),
              color: const Color(0xFF8896A6),
              onPressed: _clearSearch,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _onTextChanged(String value) {
    setState(() {}); // Refresh suffix

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isEmpty) {
        widget.onClear();
      } else {
        widget.onSearch(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    widget.onClear();
  }
}
