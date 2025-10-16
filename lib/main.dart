import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pps_tablet/core/view_model/permission_view_model.dart';
import 'package:pps_tablet/features/label/broker/repository/broker_repository.dart';
import 'package:pps_tablet/features/label/broker/view/broker_screen.dart';
import 'package:pps_tablet/features/label/broker/view_model/broker_view_model.dart';
import 'package:pps_tablet/features/shared/bongkar_susun/bongkar_susun_repository.dart';
import 'package:pps_tablet/features/shared/bongkar_susun/bongkar_susun_view_model.dart';
import 'package:pps_tablet/features/shared/broker_production/broker_production_repository.dart';
import 'package:pps_tablet/features/shared/broker_production/broker_production_view_model.dart';
import 'package:pps_tablet/features/shared/max_sak/max_sak_repository.dart';
import 'package:pps_tablet/features/shared/max_sak/max_sak_service.dart';
import 'package:pps_tablet/features/shared/washing_production/washing_production_repository.dart';
import 'package:pps_tablet/features/shared/washing_production/washing_production_view_model.dart';
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
import 'features/login/view/login_screen.dart';
import 'features/stock_opname/view/stock_opname_list_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/stock_opname/view_model/stock_opname_list_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_detail_view_model.dart';
import 'features/stock_opname/view_model/stock_opname_label_before_view_model.dart';
import 'features/home/view_model/user_profile_view_model.dart';
import 'features/stock_opname/view_model/lokasi_view_model.dart';
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
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel(repository: StockOpnameRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameLabelBeforeViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()),
        ChangeNotifierProvider(create: (_) => LokasiViewModel()),
        ChangeNotifierProvider(create: (_) => SocketManager()),
        ChangeNotifierProvider(create: (_) => LabelDetailViewModel()),
        ChangeNotifierProvider(create: (_) => StockOpnameAscendViewModel(repository: StockOpnameAscendRepository())),
        ChangeNotifierProvider(create: (_) => StockOpnameFamilyViewModel(repository: StockOpnameFamilyRepository())),
        ChangeNotifierProvider(create: (_) => WashingViewModel(repository: WashingRepository())),
        ChangeNotifierProvider(create: (_) => JenisPlastikViewModel(repository: JenisPlastikRepository())),
        ChangeNotifierProvider(create: (_) => WashingProductionViewModel(repository: WashingProductionRepository())),
        ChangeNotifierProvider(create: (_) => BongkarSusunViewModel(repository: BongkarSusunRepository())),
        Provider<MaxSakService>(create: (_) => MaxSakService(MaxSakRepository())),
        ChangeNotifierProvider(create: (_) => PermissionViewModel()..loadPermissions()),
        ChangeNotifierProvider(create: (_) => BrokerViewModel(repository: BrokerRepository())),
        ChangeNotifierProvider(create: (_) => BrokerProductionViewModel(repository: BrokerProductionRepository())),



      ],
      child: MaterialApp(
        title: 'PPS Tablet',
        theme: ThemeData(primarySwatch: Colors.blue),
        navigatorKey: AppNav.key,


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
        },
      ),
    );
  }
}
