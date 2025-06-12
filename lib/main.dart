import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:presensi_dinkop/Controllers/auth_controller.dart';
import 'package:presensi_dinkop/Controllers/tab_controller.dart';
import 'package:presensi_dinkop/firebase_options.dart';
import 'package:presensi_dinkop/routes.dart';
import 'package:presensi_dinkop/Services/fcm_service.dart';

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Get.put(AuthController());
  Get.put(TabNavigationController());

  // Jalankan ambil token FCM sekali
  await FCMService().initFCM();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final box = GetStorage();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final token = box.read('token');

    return GetMaterialApp(
      title: 'Presensi Dinas Koperasi & UMKM Kab. Pacitan',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
      getPages: getPages,
      initialRoute: token == null ? '/login' : '/home',
    );
  }
}
