import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/login/view/login_screen.dart';
import 'features/stock_opname/list/view/stock_opname_list_screen.dart'; // Import DashboardScreen
import 'features/home/view/home_screen.dart';  // Pastikan path sesuai dengan file Anda
import 'features/stock_opname/list/view_model/stock_opname_list_view_model.dart'; // Import StockOpnameViewModel
import 'features/stock_opname/detail/view_model/stock_opname_detail_view_model.dart'; // Import StockOpnameInputViewModel
import 'features/stock_opname/detail/view_model/stock_opname_label_before_view_model.dart'; // Import StockOpnameInputViewModel
import 'features/home/view_model/user_profile_view_model.dart'; // Import UserProfileViewModel
import 'features/stock_opname/detail/view_model/lokasi_view_model.dart'; // Import UserProfileViewModel
import 'features/stock_opname/detail/view_model/socket_manager.dart'; // Import UserProfileViewModel
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  await dotenv.load(fileName: ".env");  // ✅ Aman & async-safe
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(  // Menggunakan MultiProvider untuk mengelola lebih dari satu provider
      providers: [
        ChangeNotifierProvider(create: (_) => StockOpnameViewModel()),  // Memberikan StockOpnameViewModel ke seluruh aplikasi
        ChangeNotifierProvider(create: (_) => StockOpnameLabelBeforeViewModel()),  // Memberikan StockOpnameViewModel ke seluruh aplikasi
        ChangeNotifierProvider(create: (_) => StockOpnameDetailViewModel()),  // Menambahkan StockOpnameInputViewModel
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()), // Menambahkan UserProfileViewModel
        ChangeNotifierProvider(create: (_) => LokasiViewModel()),
        ChangeNotifierProvider(create: (_) => SocketManager()),
      ],
      child: MaterialApp(
        title: 'PPS Tablet',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
          '/stockopname': (context) => StockOpnameListScreen(),
        },
      ),
    );
  }
}
