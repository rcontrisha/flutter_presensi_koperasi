import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final box = GetStorage();

  Future<void> registerUser(String name, String email) async {
    isLoading.value = true;

    final response = await http.post(
      Uri.parse('http://192.168.1.8:8000/api/register'),
      headers: {'Accept': 'application/json'},
      body: {'name': name, 'email': email},
    );

    isLoading.value = false;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Get.snackbar('Berhasil', data['message']);
      Get.offAllNamed('/login');
    } else {
      final error = json.decode(response.body);
      Get.snackbar('Error', error['message'] ?? 'Registrasi gagal');
    }
  }

  Future<void> loginUser(String email, String password) async {
    isLoading.value = true;

    final response = await http.post(
      Uri.parse('http://192.168.1.8:8000/api/login'),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'password': password,
      },
    );

    isLoading.value = false;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // ✅ Simpan token ke storage
      box.write('token', data['access_token']);
      box.write('user', data['user']); // Optional: simpan user info
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
        Uri.parse('http://192.168.1.8:8000/api/forgot-password'),
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
