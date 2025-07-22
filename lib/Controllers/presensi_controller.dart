import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:math';

class PresensiController extends GetxController {
  final box = GetStorage();

  var status = ''.obs;
  var jamHadir = '--'.obs;
  var jamPulang = '--'.obs;
  var isLoading = false.obs;

  // Variabel untuk riwayat presensi
  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final selectedDate = Rxn<DateTime>(); // Untuk pencarian tanggal spesifik
  var riwayatPresensi = <Map<String, dynamic>>[].obs;

  final double kantorLatitude = -8.1961617;
  final double kantorLongitude = 111.1075926;
  final double batasRadiusMeter = 100; // presensi hanya bisa dilakukan dalam radius 100 meter

  double hitungJarak(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Radius bumi dalam meter
    final double dLat = (lat2 - lat1) * (3.141592653589793 / 180.0);
    final double dLon = (lon2 - lon1) * (3.141592653589793 / 180.0);

    final double a = 
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(lat1 * (3.141592653589793 / 180.0)) *
      cos(lat2 * (3.141592653589793 / 180.0)) *
      (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> cekStatusPresensiHariIni() async {
    try {
      isLoading.value = true;
      final token = box.read('token');

      final response = await http.get(
        Uri.parse("http://192.168.1.23:8000/api/status-presensi"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        status.value = data['status'] ?? '-';
        jamHadir.value = data['jam_hadir'] ?? '--';
        jamPulang.value = data['jam_pulang'] ?? '--';
      } else {
        status.value = 'Gagal memuat data';
        jamHadir.value = '--';
        jamPulang.value = '--';
      }
    } catch (e) {
      status.value = 'Terjadi kesalahan';
      jamHadir.value = '--';
      jamPulang.value = '--';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> kirimPresensi({
    required File foto,
    required String lokasi,
    required double latitude,
    required double longitude,
  }) async {
    isLoading.value = true;
    try {
      final double jarak = hitungJarak(latitude, longitude, kantorLatitude, kantorLongitude);
      if (jarak > batasRadiusMeter) {
        Get.snackbar(
          "Lokasi Tidak Valid",
          "Anda berada di luar radius yang diperbolehkan untuk presensi.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final token = box.read('token');
      final statusPresensi = status.value;
      final fieldFoto = statusPresensi == 'belum presensi' ? 'foto_masuk' : 'foto_pulang';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.23:8000/api/post-presensi'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          fieldFoto,
          foto.path,
          filename: basename(foto.path),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        await cekStatusPresensiHariIni();
        return true;
      } else {
        print("Error response: $responseBody");
        Get.snackbar("Gagal", "Presensi gagal dikirim");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mengirim presensi: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchRiwayatPresensi() async {
    try {
      isLoading.value = true;
      final token = box.read('token');

      final response = await http.get(
        Uri.parse("http://192.168.1.23:8000/api/riwayat-presensi"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Data : $data");
        if (data['data'] != null) {
          riwayatPresensi.value = List<Map<String, dynamic>>.from(data['data']);
        } else {
          riwayatPresensi.clear();
        }
      } else {
        Get.snackbar("Gagal", "Gagal mengambil riwayat presensi");
        riwayatPresensi.clear();
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan saat mengambil riwayat presensi");
      riwayatPresensi.clear();
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredRiwayat {
    if (selectedDate.value != null) {
      return riwayatPresensi.where((item) {
        final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
        return tanggal != null &&
            tanggal.year == selectedDate.value!.year &&
            tanggal.month == selectedDate.value!.month &&
            tanggal.day == selectedDate.value!.day;
      }).toList();
    } else {
      return riwayatPresensi.where((item) {
        final tanggal = DateTime.tryParse(item['tanggal'] ?? '');
        return tanggal != null &&
            tanggal.year == selectedYear.value &&
            tanggal.month == selectedMonth.value;
      }).toList();
    }
  }

  Future<void> logout() async {
    final token = box.read('token');

    final response = await http.post(
      Uri.parse("http://192.168.1.23:8000/api/logout"),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      box.remove('token');
      box.remove('user');
      box.remove('pegawai');
      box.remove('read_surat_ids');
      box.remove('last_fcm_token');
      Get.offAllNamed('/login'); // Arahkan ke halaman login
    } else {
      Get.snackbar("Gagal", "Logout gagal. Coba lagi.");
    }
  }
}
