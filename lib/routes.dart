import 'package:get/get.dart';
import 'package:presensi_dinkop/Screens/forgot_password.dart';
import 'package:presensi_dinkop/Screens/home_screen.dart';
import 'package:presensi_dinkop/Screens/izin_screen.dart';
import 'package:presensi_dinkop/Screens/profile_screen.dart';
import 'package:presensi_dinkop/Screens/riwayat-presensi_screen.dart';
import 'package:presensi_dinkop/Widgets/main_tab_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

final getPages = [
  GetPage(name: '/', page: () => SplashScreen()),
  GetPage(name: '/login', page: () => LoginScreen()),
  GetPage(name: '/register', page: () => RegisterScreen()),
  GetPage(name: '/forgot-password', page: () => ForgotPasswordUI()),
  GetPage(name: '/home', page: () => MainTabController()),
  GetPage(name: '/riwayat', page: () => RiwayatScreen()),
  GetPage(name: '/izin', page: () => DaftarIzinScreen()),
  GetPage(name: '/profile', page: () => ProfilePage()),
];
