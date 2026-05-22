import 'package:flutter/material.dart';
import 'package:pps_tablet/core/services/permission_storage.dart';
import 'package:pps_tablet/core/services/token_storage.dart';
import 'package:pps_tablet/core/services/user_session_storage.dart';
import 'package:pps_tablet/core/view_model/label_print_lock_socket_manager.dart';
import 'package:pps_tablet/core/view_model/permission_view_model.dart';
import 'package:pps_tablet/features/audit/view/audit_screen.dart';
import 'package:pps_tablet/features/bj_jual/view/bj_jual_screen.dart';
import 'package:pps_tablet/features/bongkar_susun_v2/view/bs_v2_list_screen.dart';
import 'package:pps_tablet/features/home/view/home_screen.dart';
import 'package:pps_tablet/features/home/view/widgets/home_sidebar.dart';
import 'package:pps_tablet/features/home/view/widgets/user_profile_dialog.dart';
import 'package:pps_tablet/features/label/bahan_baku/view/bahan_baku_screen.dart';
import 'package:pps_tablet/features/label/bonggolan/view/bonggolan_screen.dart';
import 'package:pps_tablet/features/label/broker/view/broker_screen.dart';
import 'package:pps_tablet/features/label/crusher/view/crusher_screen.dart';
import 'package:pps_tablet/features/label/furniture_wip/view/furniture_wip_screen.dart';
import 'package:pps_tablet/features/label/gilingan/view/gilingan_screen.dart';
import 'package:pps_tablet/features/label/mixer/view/mixer_screen.dart';
import 'package:pps_tablet/features/label/packing/view/packing_screen.dart';
import 'package:pps_tablet/features/label/reject/view/reject_screen.dart';
import 'package:pps_tablet/features/label/selection/view/label_selection_screen.dart';
import 'package:pps_tablet/features/label/washing/view/washing_screen.dart';
import 'package:pps_tablet/features/mapping/view/mapping_screen.dart';
import 'package:pps_tablet/features/production/broker/view/broker_production_mesin_screen.dart';
import 'package:pps_tablet/features/production/crusher/view/crusher_production_screen.dart';
import 'package:pps_tablet/features/production/gilingan/view/gilingan_production_screen.dart';
import 'package:pps_tablet/features/production/hot_stamp/view/hot_stamp_production_screen.dart';
import 'package:pps_tablet/features/production/inject/view/inject_production_screen.dart';
import 'package:pps_tablet/features/production/key_fitting/view/key_fitting_production_screen.dart';
import 'package:pps_tablet/features/production/mixer/view/mixer_production_screen.dart';
import 'package:pps_tablet/features/production/packing/view/packing_production_screen.dart';
import 'package:pps_tablet/features/production/return/view/return_production_screen.dart';
import 'package:pps_tablet/features/production/selection/view/production_selection_screen.dart';
import 'package:pps_tablet/features/production/sortir_reject/view/sortir_reject_production_screen.dart';
import 'package:pps_tablet/features/production/spanner/view/spanner_production_screen.dart';
import 'package:pps_tablet/features/production/washing/view/washing_production_screen.dart';
import 'package:pps_tablet/features/report/view/report_list_screen.dart';
import 'package:pps_tablet/features/sortir_reject_v2/view/sr_v2_list_screen.dart';
import 'package:pps_tablet/features/stock_opname/view/stock_opname_list_screen.dart';
import 'package:provider/provider.dart';

class BreadcrumbSegment {
  final String label;
  final VoidCallback? onTap;
  const BreadcrumbSegment(this.label, {this.onTap});
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static final shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Global breadcrumb — screens can push/pop segments to show navigation flow.
  static final breadcrumb = ValueNotifier<List<BreadcrumbSegment>>([
    const BreadcrumbSegment('Dashboard'),
  ]);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    AppShell.breadcrumb.addListener(_onBreadcrumbChanged);
  }

  void _onBreadcrumbChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppShell.breadcrumb.removeListener(_onBreadcrumbChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (AppShell.shellNavigatorKey.currentState?.canPop() ?? false) {
          AppShell.shellNavigatorKey.currentState?.maybePop();
          return;
        }
        if (!context.mounted) return;
        final confirm = await _showExitDialog(context);
        if ((confirm ?? false) && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              HomeSidebar(
                navigatorKey: AppShell.shellNavigatorKey,
                isCollapsed: _sidebarCollapsed,
                onToggleCollapse: () =>
                    setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                onNavigate: (title) =>
                    AppShell.breadcrumb.value = [BreadcrumbSegment(title)],
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildCompactAppBar(context),
                    Expanded(
                      child: ClipRect(
                        child: Navigator(
                          key: AppShell.shellNavigatorKey,
                          initialRoute: '/shell/welcome',
                          onGenerateRoute: _generateRoute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAppBar(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.7),
        ),
      ),
      child: Row(
        children: [
          _BreadcrumbRow(segments: AppShell.breadcrumb.value),
          const Spacer(),
          _buildUserMenu(context),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            color: const Color(0xFF64748B),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return FutureBuilder<String>(
      future: UserSessionStorage.getUsername(fallback: '-'),
      builder: (_, snapshot) {
        final username = snapshot.data ?? '-';

        return PopupMenuButton<_UserMenuAction>(
          tooltip: 'Akun',
          offset: const Offset(0, 34),
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
          ),
          onSelected: (action) {
            switch (action) {
              case _UserMenuAction.account:
                _showAccountDialog();
                break;
              case _UserMenuAction.logout:
                _handleLogout(context);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<_UserMenuAction>(
              enabled: false,
              height: 70,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: Text(
                      _initials(username),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk sebagai',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<_UserMenuAction>(
              value: _UserMenuAction.account,
              height: 44,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.manage_accounts_outlined,
                      color: Color(0xFF0D47A1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Akun',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<_UserMenuAction>(
              value: _UserMenuAction.logout,
              height: 44,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountDialog() {
    showDialog(context: context, builder: (_) => const UserProfileDialog());
  }

  String _initials(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty || trimmed == '-') return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final socketMgr = context.read<LabelPrintLockSocketManager>();
    final permVm = context.read<PermissionViewModel>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    socketMgr.disconnect();
    await TokenStorage.clear();
    await PermissionStorage.clear();
    await UserSessionStorage.clear();

    if (context.mounted) {
      permVm.clear();
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final Widget page = _pageForRoute(settings.name);
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  Widget _pageForRoute(String? name) {
    switch (name) {
      case '/shell/welcome':
        return const HomeScreen();
      case '/label':
        return LabelSelectionScreen();
      case '/label/bahan-baku':
        return BahanBakuScreen();
      case '/label/washing':
        return WashingTableScreen();
      case '/label/broker':
        return BrokerScreen();
      case '/label/bonggolan':
        return BonggolanScreen();
      case '/label/crusher':
        return CrusherScreen();
      case '/label/gilingan':
        return GilinganScreen();
      case '/label/mixer':
        return MixerScreen();
      case '/label/furniture_wip':
        return FurnitureWipScreen();
      case '/label/packing':
        return PackingScreen();
      case '/label/reject':
        return RejectScreen();
      case '/production':
        return ProductionSelectionScreen();
      case '/production/washing':
        return WashingProductionScreen();
      case '/production/broker':
        return const BrokerProductionMesinScreen();
      case '/production/crusher':
        return CrusherProductionScreen();
      case '/production/gilingan':
        return GilinganProductionScreen();
      case '/production/mixer':
        return MixerProductionScreen();
      case '/shell/hot-stamp':
      case '/production/hot-stamp':
        return HotStampProductionScreen();
      case '/production/inject':
        return InjectProductionScreen();
      case '/shell/key-fitting':
      case '/production/key-fitting':
        return KeyFittingProductionScreen();
      case '/shell/spanner':
      case '/production/spanner':
        return SpannerProductionScreen();
      case '/shell/packing':
      case '/production/packing':
        return PackingProductionScreen();
      case '/production/sortir-reject':
        return SortirRejectProductionScreen();
      case '/shell/return':
      case '/production/return':
        return ReturnProductionScreen();
      case '/stockopname':
        return StockOpnameListScreen();
      case '/shell/bongkar-susun':
        return const BsV2ListScreen();
      case '/shell/sortir-reject':
        return const SrV2ListScreen();
      case '/shell/bj-jual':
        return const BJJualScreen();
      case '/shell/laporan':
        return const ReportListScreen();
      case '/shell/history':
        return const AuditScreen();
      case '/shell/mapping':
        return const MappingScreen();
      default:
        return const HomeScreen();
    }
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7a1b0c),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

enum _UserMenuAction { account, logout }

class _BreadcrumbRow extends StatelessWidget {
  final List<BreadcrumbSegment> segments;
  const _BreadcrumbRow({required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    final items = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final isLast = i == segments.length - 1;
      final label = Text(
        seg.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isLast ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          fontSize: 15,
          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
        ),
      );

      items.add(
        !isLast && seg.onTap != null
            ? InkWell(
                onTap: seg.onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: label,
                ),
              )
            : label,
      );

      if (!isLast) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFD1D5DB),
            ),
          ),
        );
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
