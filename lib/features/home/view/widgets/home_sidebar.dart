import 'package:flutter/material.dart';

class HomeSidebar extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final void Function(String title) onNavigate;

  const HomeSidebar({
    super.key,
    required this.navigatorKey,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onNavigate,
  });

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  String? _selectedRoute;
  int? _expandedGroup;

  static const Color _primaryColor = Color(0xFF0D47A1);
  static const String _logoAsset = 'assets/images/icon_without_bg.png';

  static List<_MenuGroup> get _menuGroups => <_MenuGroup>[
    _MenuGroup(
      title: 'Buat Label',
      icon: Icons.label_outlined,
      children: [
        _SubItem(
          title: 'Bahan Baku',
          icon: Icons.inventory_2_outlined,
          route: '/label/bahan-baku',
        ),
        _SubItem(
          title: 'Washing',
          icon: Icons.local_laundry_service_outlined,
          route: '/label/washing',
        ),
        _SubItem(
          title: 'Broker',
          icon: Icons.handshake_outlined,
          route: '/label/broker',
        ),
        _SubItem(
          title: 'Bonggolan',
          icon: Icons.category_outlined,
          route: '/label/bonggolan',
        ),
        _SubItem(
          title: 'Crusher',
          icon: Icons.construction_outlined,
          route: '/label/crusher',
        ),
        _SubItem(
          title: 'Gilingan',
          icon: Icons.settings_outlined,
          route: '/label/gilingan',
        ),
        _SubItem(
          title: 'Mixer',
          icon: Icons.blender_outlined,
          route: '/label/mixer',
        ),
        _SubItem(
          title: 'Furniture WIP',
          icon: Icons.chair_outlined,
          route: '/label/furniture_wip',
        ),
        _SubItem(
          title: 'Barang Jadi',
          icon: Icons.inventory_outlined,
          route: '/label/packing',
        ),
        _SubItem(
          title: 'Reject',
          icon: Icons.cancel_outlined,
          route: '/label/reject',
        ),
      ],
    ),
    _MenuGroup(
      title: 'Proses Produksi',
      icon: Icons.precision_manufacturing_outlined,
      children: [
        _SubItem(
          title: 'Proses Washing',
          icon: Icons.local_laundry_service_outlined,
          route: '/production/washing',
        ),
        _SubItem(
          title: 'Proses Broker',
          icon: Icons.handshake_outlined,
          route: '/production/broker',
        ),
        _SubItem(
          title: 'Proses Crusher',
          icon: Icons.construction_outlined,
          route: '/production/crusher',
        ),
        _SubItem(
          title: 'Proses Gilingan',
          icon: Icons.settings_outlined,
          route: '/production/gilingan',
        ),
        _SubItem(
          title: 'Proses Mixer',
          icon: Icons.blender_outlined,
          route: '/production/mixer',
        ),
        _SubItem(
          title: 'Proses Inject',
          icon: Icons.invert_colors_outlined,
          route: '/production/inject',
        ),
      ],
    ),
  ];

  static List<_MenuItem> get _menuItems => <_MenuItem>[
    _MenuItem(
      title: 'Bongkar Susun',
      subtitle: 'Input data Bongkar Susun',
      icon: Icons.layers_outlined,
      route: '/shell/bongkar-susun',
    ),
    _MenuItem(
      title: 'Hot Stamp',
      subtitle: 'Input data Hot Stamp',
      icon: Icons.local_fire_department_outlined,
      route: '/shell/hot-stamp',
    ),
    _MenuItem(
      title: 'Pasang Kunci',
      subtitle: 'Input data Pasang Kunci',
      icon: Icons.key_outlined,
      route: '/shell/key-fitting',
    ),
    _MenuItem(
      title: 'Spanner',
      subtitle: 'Input data Spanner',
      icon: Icons.hardware_outlined,
      route: '/shell/spanner',
    ),
    _MenuItem(
      title: 'Packing',
      subtitle: 'Input data Packing',
      icon: Icons.inventory_outlined,
      route: '/shell/packing',
    ),
    _MenuItem(
      title: 'Return',
      subtitle: 'Input data Return',
      icon: Icons.undo_outlined,
      route: '/shell/return',
    ),
    _MenuItem(
      title: 'Sortir Reject',
      subtitle: 'Input data Sortir Reject',
      icon: Icons.filter_alt_outlined,
      route: '/shell/sortir-reject',
    ),
    _MenuItem(
      title: 'Stock Opname',
      subtitle: 'Kelola stok item',
      icon: Icons.checklist_rtl_rounded,
      route: '/stockopname',
    ),
    _MenuItem(
      title: 'BJ Jual',
      subtitle: 'Kelola BJ Jual',
      icon: Icons.sell_outlined,
      route: '/shell/bj-jual',
    ),
    _MenuItem(
      title: 'Laporan',
      subtitle: 'Lihat laporan',
      icon: Icons.bar_chart_outlined,
      route: '/shell/laporan',
    ),
    _MenuItem(
      title: 'History',
      subtitle: 'Lihat history aktivitas',
      icon: Icons.history,
      route: '/shell/history',
    ),
    _MenuItem(
      title: 'Mapping',
      subtitle: 'Monitoring lokasi label',
      icon: Icons.map_outlined,
      route: '/shell/mapping',
    ),
  ];

  void _navigateTo(String route, String title) {
    setState(() => _selectedRoute = route);
    widget.onNavigate(title);
    widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (r) => false,
    );
  }

  void _toggleGroup(int index) {
    setState(() => _expandedGroup = _expandedGroup == index ? null : index);
  }

  void _handleGroupTap(int index) {
    if (_collapsed) {
      setState(() => _expandedGroup = index);
      widget.onToggleCollapse();
      return;
    }

    _toggleGroup(index);
  }

  bool get _collapsed => widget.isCollapsed;

  @override
  Widget build(BuildContext context) {
    final contentWidth = _collapsed ? 64.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: contentWidth,
      decoration: const BoxDecoration(
        color: _primaryColor,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: contentWidth,
          maxWidth: contentWidth,
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                _buildHeader(),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildFlatItem(
                        _MenuItem(
                          title: 'Dashboard',
                          subtitle: 'Halaman utama',
                          icon: Icons.dashboard_outlined,
                          route: '/shell/welcome',
                        ),
                      ),
                      for (int i = 0; i < _menuGroups.length; i++)
                        _buildGroup(i),
                      for (final item in _menuItems) _buildFlatItem(item),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_collapsed) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleCollapse,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(_logoAsset, width: 30, height: 30),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(_logoAsset, width: 24, height: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'PPS Tablet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: widget.onToggleCollapse,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white70,
                  size: 20,
                ),
                tooltip: 'Collapse',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Plastic Production System',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(int index) {
    final group = _menuGroups[index];
    final isExpanded = _expandedGroup == index && !_collapsed;
    final hasActiveChild = group.children.any((c) => c.route == _selectedRoute);
    final isActive = isExpanded || hasActiveChild;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        children: [
          Tooltip(
            message: _collapsed ? group.title : '',
            preferBelow: false,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _handleGroupTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: _collapsed ? 0 : 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _collapsed
                      ? Center(
                          child: Icon(
                            group.icon,
                            color: isActive ? Colors.white : Colors.white70,
                            size: 20,
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              group.icon,
                              color: isActive ? Colors.white : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                group.title,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.25 : 0,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          // Sub items — hanya tampil saat expanded & tidak collapsed
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    children: group.children
                        .map((sub) => _buildSubItem(sub))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(_SubItem sub) {
    final isSelected = _selectedRoute == sub.route;
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _navigateTo(sub.route, sub.title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  sub.icon,
                  color: isSelected ? Colors.white : Colors.white60,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  sub.title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlatItem(_MenuItem item) {
    final isSelected = _selectedRoute == item.route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: _collapsed ? item.title : '',
        preferBelow: false,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _navigateTo(item.route, item.title),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: _collapsed ? 0 : 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _collapsed
                  ? Center(
                      child: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 20,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 16,
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGroup {
  final String title;
  final IconData icon;
  final List<_SubItem> children;

  const _MenuGroup({
    required this.title,
    required this.icon,
    required this.children,
  });
}

class _SubItem {
  final String title;
  final IconData icon;
  final String route;

  const _SubItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
