import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class FCMService {
  Future<void> initFCM() async {
    final box = GetStorage();
    final tokenUser = box.read('token');

    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      String? lastSavedToken = box.read('last_fcm_token');

      if (fcmToken != null && fcmToken != lastSavedToken) {
        try {
          final response = await http.post(
            Uri.parse('http://192.168.1.12:8000/api/save-fcm-token'),
            headers: {
              'Authorization': 'Bearer $tokenUser',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'fcm_token': fcmToken}),
          );
          if (response.statusCode == 200) {
            box.write('last_fcm_token', fcmToken);
            print('✅ FCM token berhasil disimpan ke server');
          } else {
            print('❌ Gagal kirim FCM token: ${response.statusCode}: ${response.body}');
          }
        } catch (e) {
          print('❌ Error saat kirim FCM token: $e');
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken != lastSavedToken) {
          try {
            final res = await http.post(
              Uri.parse('http://192.168.1.30:8000/api/save-fcm-token'),
              headers: {
                'Authorization': 'Bearer $tokenUser',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'fcm_token': newToken}),
            );
            if (res.statusCode == 200) {
              box.write('last_fcm_token', newToken);
              print('🔄 Token FCM berhasil diperbarui di server.');
            }
          } catch (e) {
            print('❌ Error refresh token: $e');
          }
        }
      });
    } else {
      print('🔒 Notifikasi tidak diizinkan.');
    }
  }
}
