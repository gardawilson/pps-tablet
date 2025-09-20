// features/stock_opname/detail/widgets/filter_section/lokasi_dropdown_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../view_model/lokasi_view_model.dart';

class LokasiDropdownWidget extends StatefulWidget {
  final String? selectedIdLokasi;
  final ValueChanged<String?> onChanged;

  const LokasiDropdownWidget({
    Key? key,
    required this.selectedIdLokasi,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<LokasiDropdownWidget> createState() => _LokasiDropdownWidgetState();
}

class _LokasiDropdownWidgetState extends State<LokasiDropdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LokasiViewModel>(
      builder: (context, lokasiVM, child) {
        if (lokasiVM.isLoading) {
          return _buildLoadingContainer();
        }

        final lokasiItems = [
          const MapEntry('all', 'Semua'),
          ...lokasiVM.lokasiList.map((e) => MapEntry(e.idLokasi, e.idLokasi)),
        ];

        final selectedEntry = lokasiItems.firstWhere(
              (item) => item.key == (widget.selectedIdLokasi ?? 'all'),
          orElse: () => lokasiItems.first,
        );

        return Container(
          height: 53,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownSearch<MapEntry<String, String>>(
            items: lokasiItems,
            selectedItem: selectedEntry,
            itemAsString: (item) => item.value,

            popupProps: PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              menuProps: MenuProps(
                backgroundColor: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Cari lokasi...",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              itemBuilder: (context, item, isSelected) => _buildDropdownItem(item, isSelected),
            ),
            dropdownButtonProps: DropdownButtonProps(
              icon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isOpen = !_isOpen;
                  });
                  if (_isOpen) {
                    _animController.forward();
                  } else {
                    _animController.reverse();
                  }
                },
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
                hintText: "Lokasi",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            onBeforePopupOpening: (selectedItem) {
              setState(() {
                _isOpen = true;
              });
              _animController.forward();
              return Future.value(true);
            },
            onChanged: (selectedEntry) {
              setState(() {
                _isOpen = false;
              });
              _animController.reverse();
              widget.onChanged(selectedEntry?.key);
            },
          ),
        );
      },
    );
  }

  Widget _buildDropdownItem(MapEntry<String, String> item, bool isSelected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade100 : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        item.value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          color: isSelected ? Colors.blue.shade700 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Memuat lokasi...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}