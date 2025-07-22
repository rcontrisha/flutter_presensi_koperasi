import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final box = GetStorage();

  Future<void> loginUser(String email, String password, [bool rememberMe = false]) async {
    isLoading.value = true;

    final response = await http.post(
      Uri.parse('http://192.168.1.23:8000/api/login'),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
        'remember': rememberMe ? '1' : '0',
      },
    );

    isLoading.value = false;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Selalu simpan token untuk kebutuhan API selama aplikasi aktif
      box.write('token', data['access_token']);
      box.write('remember_me', rememberMe); // simpan status remember me

      box.write('user', data['user']);
      box.write('pegawai', data['pegawai']);

      Get.snackbar('Sukses', 'Login berhasil');
      Get.offAllNamed('/home');
    } else {
      final error = json.decode(response.body);
      Get.snackbar('Login Gagal', error['message'] ?? 'Email atau password salah');
    }
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar('Error', 'Masukkan email yang valid');
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.23:8000/api/forgot-password'),
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'email': email,
        },
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        Get.defaultDialog(
          title: 'Email Terkirim ✉️',
          middleText: 'Cek email Anda untuk mereset password!',
          textConfirm: 'OK',
          onConfirm: () => Get.back(),
        );
      } else {
        Get.snackbar('Gagal', 'Terjadi kesalahan. Coba lagi.');
        print(response.body);
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Tidak dapat terhubung ke server');
    }
  }
}
