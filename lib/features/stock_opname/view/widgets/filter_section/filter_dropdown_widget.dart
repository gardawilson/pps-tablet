// features/stock_opname/detail/widgets/filter_section/filter_dropdown_widget.dart

import 'package:flutter/material.dart';

class FilterDropdownWidget extends StatefulWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onChanged;

  const FilterDropdownWidget({
    Key? key,
    required this.selectedFilter,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FilterDropdownWidget> createState() => _FilterDropdownWidgetState();
}

class _FilterDropdownWidgetState extends State<FilterDropdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _rotationAnimation;

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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedFilter,
          isExpanded: true,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          dropdownColor: Colors.white,
          menuMaxHeight: 400,
          onTap: () {
            _animController.forward();
          },
          onChanged: (value) {
            widget.onChanged(value);
            _animController.reverse();
          },
          icon: AnimatedBuilder(
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
          hint: Text(
            'Filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          items: [
            _buildDropdownItem('all', 'Semua'),
            _buildDropdownItem('bahanbaku', 'Bahan Baku'),
            _buildDropdownItem('washing', 'Washing'),
            _buildDropdownItem('broker', 'Broker'),
            _buildDropdownItem('crusher', 'Crusher'),
            _buildDropdownItem('bonggolan', 'Bonggolan'),
            _buildDropdownItem('gilingan', 'Gilingan'),
            _buildDropdownItem('mixer', 'Mixer'),
            _buildDropdownItem('furniturewip', 'Furniture WIP'),
            _buildDropdownItem('barangjadi', 'Barang Jadi'),
            _buildDropdownItem('reject', 'Reject'),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, String label) {
    final bool isSelected = widget.selectedFilter == value;

    return DropdownMenuItem<String>(
      value: value,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? Colors.blue.shade700 : Colors.black87,
          ),
        ),
      ),
    );
  }
}