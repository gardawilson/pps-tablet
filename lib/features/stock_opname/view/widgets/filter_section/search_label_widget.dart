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
      height: 53,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onTextChanged,
              decoration: const InputDecoration(
                hintText: 'Cari label...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              color: Colors.grey,
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