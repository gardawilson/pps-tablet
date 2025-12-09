import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pps_tablet/core/view_model/permission_view_model.dart';
import 'package:pps_tablet/features/crusher_type/repository/crusher_type_repository.dart';
import 'package:pps_tablet/features/crusher_type/view_model/crusher_type_view_model.dart';
import 'package:pps_tablet/features/furniture_wip_type/repository/furniture_wip_type_repository.dart';
import 'package:pps_tablet/features/furniture_wip_type/view_model/furniture_wip_type_view_model.dart';
import 'package:pps_tablet/features/gilingan_type/repository/gilingan_type_repository.dart';
import 'package:pps_tablet/features/gilingan_type/view_model/gilingan_type_view_model.dart';
import 'package:pps_tablet/features/jenis_bonggolan/repository/jenis_bonggolan_repository.dart';
import 'package:pps_tablet/features/jenis_bonggolan/view_model/jenis_bonggolan_view_model.dart';
import 'package:pps_tablet/features/label/bonggolan/repository/bonggolan_repository.dart';
import 'package:pps_tablet/features/label/bonggolan/view/bonggolan_screen.dart';
import 'package:pps_tablet/features/label/bonggolan/view_model/bonggolan_view_model.dart';
import 'package:pps_tablet/features/label/broker/repository/broker_repository.dart';
import 'package:pps_tablet/features/label/broker/view/broker_screen.dart';
import 'package:pps_tablet/features/label/broker/view_model/broker_view_model.dart';
import 'package:pps_tablet/features/label/furniture_wip/repository/furniture_wip_repository.dart';
import 'package:pps_tablet/features/label/furniture_wip/view/furniture_wip_screen.dart';
import 'package:pps_tablet/features/label/furniture_wip/view_model/furniture_wip_view_model.dart';
import 'package:pps_tablet/features/label/gilingan/repository/gilingan_repository.dart';
import 'package:pps_tablet/features/label/gilingan/view_model/gilingan_view_model.dart';
import 'package:pps_tablet/features/label/mixer/repository/mixer_repository.dart';
import 'package:pps_tablet/features/label/mixer/view/mixer_screen.dart';
import 'package:pps_tablet/features/label/mixer/view_model/mixer_view_model.dart';
import 'package:pps_tablet/features/label/packing/repository/packing_repository.dart';
import 'package:pps_tablet/features/label/packing/view/packing_screen.dart';
import 'package:pps_tablet/features/label/packing/view_model/packing_view_model.dart';
import 'package:pps_tablet/features/mesin/repository/mesin_repository.dart';
import 'package:pps_tablet/features/mesin/view_model/mesin_view_model.dart';
import 'package:pps_tablet/features/mixer_type/repository/mixer_type_repository.dart';
import 'package:pps_tablet/features/mixer_type/view_model/mixer_type_view_model.dart';
import 'package:pps_tablet/features/operator/repository/operator_repository.dart';
import 'package:pps_tablet/features/operator/view_model/operator_view_model.dart';
import 'package:pps_tablet/features/packing_type/repository/packing_type_repository.dart';
import 'package:pps_tablet/features/packing_type/view_model/packing_type_view_model.dart';
import 'package:pps_tablet/features/production/broker/repository/broker_production_input_repository.dart';
import 'package:pps_tablet/features/production/broker/view_model/broker_production_input_view_model.dart';
import 'package:pps_tablet/features/production/crusher/repository/crusher_production_input_repository.dart';
import 'package:pps_tablet/features/production/crusher/repository/crusher_production_repository.dart';
import 'package:pps_tablet/features/production/crusher/view/crusher_production_screen.dart';
import 'package:pps_tablet/features/production/crusher/view_model/crusher_production_input_view_model.dart';
import 'package:pps_tablet/features/production/crusher/view_model/crusher_production_view_model.dart';
import 'package:pps_tablet/features/production/gilingan/repository/gilingan_production_repository.dart';
import 'package:pps_tablet/features/production/gilingan/view_model/gilingan_production_view_model.dart';
import 'package:pps_tablet/features/production/hot_stamp/model/hot_stamp_production_model.dart';
import 'package:pps_tablet/features/production/hot_stamp/repository/hot_stamp_production_repository.dart';
import 'package:pps_tablet/features/production/hot_stamp/view_model/hot_stamp_production_view_model.dart';
import 'package:pps_tablet/features/production/inject/repository/inject_production_repository.dart';
import 'package:pps_tablet/features/production/inject/view_model/inject_production_view_model.dart';
import 'package:pps_tablet/features/production/key_fitting/repository/key_fitting_production_repository.dart';
import 'package:pps_tablet/features/production/key_fitting/view_model/key_fitting_production_view_model.dart';
import 'package:pps_tablet/features/production/mixer/repository/mixer_production_repository.dart';
import 'package:pps_tablet/features/production/mixer/view_model/mixer_production_view_model.dart';
import 'package:pps_tablet/features/production/packing/repository/packing_production_repository.dart';
import 'package:pps_tablet/features/production/packing/view_model/packing_production_view_model.dart';
import 'package:pps_tablet/features/production/return/repository/return_production_repository.dart';
import 'package:pps_tablet/features/production/return/view_model/return_production_view_model.dart';
import 'package:pps_tablet/features/production/selection/view/production_selection_screen.dart';
import 'package:pps_tablet/features/production/spanner/repository/spanner_production_repository.dart';
import 'package:pps_tablet/features/production/spanner/view_model/spanner_production_view_model.dart';
import 'package:pps_tablet/features/production/washing/repository/washing_production_input_repository.dart';
import 'package:pps_tablet/features/production/washing/view/washing_production_screen.dart';
import 'package:pps_tablet/features/production/washing/view_model/washing_production_input_view_model.dart';
import 'package:pps_tablet/features/shared/bongkar_susun/bongkar_susun_repository.dart';
import 'package:pps_tablet/features/shared/bongkar_susun/bongkar_susun_view_model.dart';
import 'package:pps_tablet/features/production/broker/repository/broker_production_repository.dart';
import 'package:pps_tablet/features/production/broker/view_model/broker_production_view_model.dart';
import 'package:pps_tablet/features/shared/lokasi/lokasi_repository.dart';
import 'package:pps_tablet/features/shared/max_sak/max_sak_repository.dart';
import 'package:pps_tablet/features/shared/max_sak/max_sak_service.dart';
import 'package:pps_tablet/features/production/washing/repository/washing_production_repository.dart';
import 'package:pps_tablet/features/production/washing/view_model/washing_production_view_model.dart';
import 'package:pps_tablet/features/shared/overlap/repository/overlap_repository.dart';
import 'package:pps_tablet/features/shared/overlap/view_model/overlap_view_model.dart';
import 'package:provider/provider.dart';

// ⬇️ Tambahan untuk locale & tanggal Indonesia
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// === imports kamu yang lain ===
import 'package:pps_tablet/features/label/selection/view/label_selection_screen.dart';
import 'package:pps_tablet/features/label/washing/repository/washing_repository.dart';
import 'package:pps_tablet/features/label/washing/view/washing_screen.dart';
import 'package:pps_tablet/features/label/washing/view_model/washing_view_model.dart';
import 'package:pps_tablet/features/shared/plastic_type/jenis_plastik_repository.dart';
import 'package:pps_tablet/features/shared/plastic_type/jenis_plastik_view_model.dart';
import 'package:pps_tablet/features/stock_opname/repository/stock_opname_ascend_repository.dart';
import 'package:pps_tablet/features/stock_opname/repository/stock_opname_family_repository.dart';
import 'package:pps_tablet/features/stock_opname/repository/stock_opname_repository.dart';
import 'package:pps_tablet/features/stock_opname/view_model/stock_opname_ascend_view_model.dart';
import 'package:pps_tablet/features/stock_opname/view_model/stock_opname_family_view_model.dart';
import 'core/navigation/app_nav.dart';
import 'core/network/api_client.dart';
import 'features/label/crusher/repository/crusher_repository.dart';
import 'features/label/crusher/view/crusher_screen.dart';
import 'features/label/crusher/view_model/crusher_view_model.dart';
import 'features/label/gilingan/view/gilingan_screen.dart';
import 'features/login/view/login_screen.dart';
import 'features/production/broker/view/broker_production_screen.dart';
import 'features/shared/lokasi/lokasi_view_model.dart';
import 'features/stock_opname/view/stock_opname_list_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/stock_opname/view_model/stock_opname_list_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_detail_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_label_before_view_model.dart';
import 'features/home/view_model/user_profile_view_model.dart';
import 'features/stock_opname/view_model/socket_manager.dart';
import 'features/stock_opname/view_model/label_detail_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Env
  await dotenv.load(fileName: ".env");

  // Locale Indonesia untuk nama hari/bulan (Intl)
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔹 Sediakan ApiClient sekali untuk seluruh app
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),

        ChangeNotifierProvider(create: (_) => StockOpnameViewModel(repository: StockOpnameRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameLabelBeforeViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => LokasiViewModel(repository: LokasiRepository())),
        ChangeNotifierProvider(create: (_) => SocketManager()),
        ChangeNotifierProvider(create: (_) => LabelDetailViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameAscendViewModel(repository: StockOpnameAscendRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameFamilyViewModel(repository: StockOpnameFamilyRepository())),
        ChangeNotifierProvider(create: (_) => WashingViewModel(repository: WashingRepository())),
        ChangeNotifierProvider(create: (_) => JenisPlastikViewModel(repository: JenisPlastikRepository())),
        ChangeNotifierProvider(create: (_) => WashingProductionViewModel(repository: WashingProductionRepository())),
        ChangeNotifierProvider(create: (_) => WashingProductionInputViewModel(repository: WashingProductionInputRepository())),
        ChangeNotifierProvider(create: (_) => BongkarSusunViewModel(repository: BongkarSusunRepository())),
        Provider<MaxSakService>(create: (_) => MaxSakService(MaxSakRepository())),
        ChangeNotifierProvider(create: (_) => PermissionViewModel()..loadPermissions()),
        ChangeNotifierProvider<BrokerViewModel>(
          create: (ctx) => BrokerViewModel(
            repository: BrokerRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => BonggolanViewModel(repository: BonggolanRepository())),
        ChangeNotifierProvider(create: (_) => CrusherViewModel(repository: CrusherRepository())),
        ChangeNotifierProvider(create: (_) => CrusherProductionInputViewModel(repository: CrusherProductionInputRepository())),
        ChangeNotifierProvider(create: (_) => BrokerProductionViewModel(repository: BrokerProductionRepository())),
        ChangeNotifierProvider(create: (_) => BrokerProductionInputViewModel(repository: BrokerProductionInputRepository())),
        ChangeNotifierProvider(create: (_) => JenisBonggolanViewModel(repository: JenisBonggolanRepository())),
        ChangeNotifierProvider(create: (_) => CrusherProductionViewModel(repository: CrusherProductionRepository())),
        ChangeNotifierProvider(create: (_) => CrusherTypeViewModel(repository: CrusherTypeRepository())),
        ChangeNotifierProvider(create: (_) => MesinViewModel(repository: MesinRepository())),
        ChangeNotifierProvider(create: (_) => OperatorViewModel(repository: OperatorRepository())),
        ChangeNotifierProvider(create: (_) => OverlapViewModel(repository: OverlapRepository())),
        ChangeNotifierProvider(create: (_) => MixerViewModel(repository: MixerRepository())),
        ChangeNotifierProvider(create: (_) => MixerProductionViewModel(repository: MixerProductionRepository())),
        ChangeNotifierProvider(create: (_) => MixerTypeViewModel(repository: MixerTypeRepository())),
        ChangeNotifierProvider(create: (_) => GilinganViewModel(repository: GilinganRepository())),
        ChangeNotifierProvider(create: (_) => GilinganTypeViewModel(repository: GilinganTypeRepository())),
        ChangeNotifierProvider(create: (_) => GilinganProductionViewModel(repository: GilinganProductionRepository())),

        ChangeNotifierProvider(create: (_) => FurnitureWipViewModel(repository: FurnitureWipRepository())),


        ChangeNotifierProvider<HotStampProductionViewModel>(
          create: (ctx) => HotStampProductionViewModel(
            repository: HotStampProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<SpannerProductionViewModel>(
          create: (ctx) => SpannerProductionViewModel(
            repository: SpannerProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<KeyFittingProductionViewModel>(
          create: (ctx) => KeyFittingProductionViewModel(
            repository: KeyFittingProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<ReturnProductionViewModel>(
          create: (ctx) => ReturnProductionViewModel(
            repository: ReturnProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<FurnitureWipTypeViewModel>(
          create: (ctx) => FurnitureWipTypeViewModel(
            repository: FurnitureWipTypeRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<PackingViewModel>(
          create: (ctx) => PackingViewModel(
            repository: PackingRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<PackingProductionViewModel>(
          create: (ctx) => PackingProductionViewModel(
            repository: PackingProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<PackingTypeViewModel>(
          create: (ctx) => PackingTypeViewModel(
            repository: PackingTypeRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


        ChangeNotifierProvider<InjectProductionViewModel>(
          create: (ctx) => InjectProductionViewModel(
            repository: InjectProductionRepository(
              api: ctx.read<ApiClient>(),
            ),
          ),
        ),


      ],
      child: MaterialApp(
        title: 'PPS Tablet',
        navigatorKey: AppNav.key,

        // 🎨 THEME: pakai biru sebagai warna utama + atur default button
        theme: ThemeData(
          useMaterial3: true, // boleh kamu ganti false kalau belum mau M3

          // Warna utama seluruh aplikasi
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // 🔵 biru utama
            brightness: Brightness.light,
          ),

          // ElevatedButton default → biru
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),

          // FilledButton default → biru
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
          ),

          // TextButton default → teks biru
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
            ),
          ),
        ),

        // ⬇️ Aktifkan localization supaya showDatePicker & widget lain pakai bahasa Indo
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        locale: const Locale('id', 'ID'),

        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
          '/label': (context) => LabelSelectionScreen(),
          '/label/washing': (context) => WashingTableScreen(),
          '/label/broker': (context) => BrokerScreen(),
          '/label/bonggolan': (context) => BonggolanScreen(),
          '/label/crusher': (context) => CrusherScreen(),
          '/label/gilingan': (context) => GilinganScreen(),
          '/label/mixer': (context) => MixerScreen(),
          '/label/furniture_wip': (context) => FurnitureWipScreen(),
          '/production': (context) => ProductionSelectionScreen(),
          '/production/washing': (context) => WashingProductionScreen(),
          '/production/broker': (context) => BrokerProductionScreen(),
          '/production/crusher': (context) => CrusherProductionScreen(),
          '/label/packing': (context) => PackingScreen(),

        },
      ),

    );
  }
}
