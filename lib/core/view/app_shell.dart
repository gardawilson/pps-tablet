import 'package:flutter/material.dart';
import 'package:pps_tablet/features/audit/view/audit_screen.dart';
import 'package:pps_tablet/features/bj_jual/view/bj_jual_screen.dart';
import 'package:pps_tablet/features/bongkar_susun_v2/view/bs_v2_list_screen.dart';
import 'package:pps_tablet/features/home/view/home_screen.dart';
import 'package:pps_tablet/features/home/view/widgets/home_sidebar.dart';
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
import 'package:pps_tablet/features/production/broker/view/broker_production_screen.dart';
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static final shellNavigatorKey = GlobalKey<NavigatorState>();

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarCollapsed = false;
  final _activeTitle = ValueNotifier<String>('Dashboard');

  @override
  void dispose() {
    _activeTitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (AppShell.shellNavigatorKey.currentState?.canPop() ?? false) {
          AppShell.shellNavigatorKey.currentState?.pop();
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
                onNavigate: (title) => _activeTitle.value = title,
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
          ValueListenableBuilder<String>(
            valueListenable: _activeTitle,
            builder: (_, title, __) => Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            color: const Color(0xFF64748B),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Akun',
            color: const Color(0xFF64748B),
            iconSize: 21,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          ),
        ],
      ),
    );
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
        return BrokerProductionScreen();
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
