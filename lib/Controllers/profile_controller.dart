import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var profileData = {}.obs;
  final box = GetStorage();

  Future<void> fetchProfile() async {
    isLoading.value = true;
    final token = box.read('token');

    final response = await http.get(
      Uri.parse('http://192.168.1.12:8000/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      profileData.value = json.decode(response.body)['data'];
    } else {
      profileData.value = {}; // reset jika gagal
      Get.snackbar("Error", "Gagal mengambil data profil");
    }

    isLoading.value = false;
  }

  Future<bool> createProfile(Map<String, dynamic> data) async {
    final token = box.read('token');

    final response = await http.post(
      Uri.parse('http://192.168.1.12:8000/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      await fetchProfile();
      return true;
    } else {
      Get.snackbar("Error", "Gagal membuat data profil");
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final token = box.read('token');

    final response = await http.put(
      Uri.parse('http://192.168.1.12:8000/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      await fetchProfile();
      return true;
    } else {
      Get.snackbar("Error", "Gagal memperbarui data profil");
      return false;
    }
  }

  // Function to change password
  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final token = box.read('token');

    // Validasi jika password baru dan konfirmasi password tidak sama
    if (newPassword != confirmPassword) {
      Get.snackbar("Error", "Password baru dan konfirmasi password tidak cocok");
      return false;
    }

    final response = await http.put(
      Uri.parse('http://192.168.1.12:8000/api/user/update-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}
