import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

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

  await FCMService().initFCM();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final box = GetStorage();

  MyApp({super.key});

  Future<String> _checkToken() async {
    final token = box.read('token');
    if (token == null) return '/login';

    // Cek token ke backend
    final response = await http.get(
      Uri.parse('http://192.168.1.23:8000/api/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return '/home';
    } else {
      box.remove('token');
      return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _checkToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
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
          initialRoute: snapshot.data!,
        );
      },
    );
  }
}
