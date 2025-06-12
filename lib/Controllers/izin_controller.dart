import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class IzinController extends GetxController {
  var daftarIzin = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  final box = GetStorage();
  Rx<PlatformFile?> selectedFile = Rx<PlatformFile?>(null);
  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final selectedDate = Rxn<DateTime>(); // Untuk pencarian tanggal spesifik
  var tanggalMulai = Rxn<DateTime>();
  var tanggalSelesai = Rxn<DateTime>();

  void setTanggalMulai(DateTime date) => tanggalMulai.value = date;
  void setTanggalSelesai(DateTime date) => tanggalSelesai.value = date;

  final jenisIzinList = [
    'Diperbantukan atau Ditugaskan pada Instansi Vertikal',
    'Melaksanakan Cuti',
    'Menghadiri Rapat, Perjalanan Dinas, dan Tugas Lain yang Berkaitan dengan Kedinasan',
    'Mengikuti Diklat',
    'Presensi Manual',
    'Tugas Belajar',
    'Tugas Kedinasan',
  ];

  // ✅ 1. Fetch daftar izin (dengan filter opsional bulan dan tahun)
  Future<void> fetchIzinList({int? bulan, int? tahun}) async {
    isLoading.value = true;
    final token = box.read('token');

    try {
      final uri = Uri.parse('http://192.168.1.8:8000/api/izin').replace(queryParameters: {
        if (bulan != null) 'bulan': bulan.toString(),
        if (tahun != null) 'tahun': tahun.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        daftarIzin.value = List<Map<String, dynamic>>.from(body['data']);
      } else {
        print('Gagal mengambil data izin: ${response.body}');
      }
    } catch (e) {
      print('Error saat fetch izin: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> ajukanIzin({
    required String jenisIzin,
    required String tanggalMulai,
    required String tanggalSelesai,
    String? keterangan,
    PlatformFile? filePendukung // path ke file opsional
  }) async {
    final token = box.read('token');

    try {
      var uri = Uri.parse('http://192.168.1.8:8000/api/izin');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['jenis_izin'] = jenisIzin;
      request.fields['tanggal_mulai'] = tanggalMulai;
      request.fields['tanggal_selesai'] = tanggalSelesai;
      if (keterangan != null) request.fields['keterangan'] = keterangan;

      if (filePendukung != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file_pendukung',
          filePendukung.path!, // Use the path of the PlatformFile
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Gagal mengajukan izin: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat ajukan izin: $e');
      return false;
    }
  }

  // ✅ 3. Ambil detail izin tertentu
  Future<Map<String, dynamic>?> getDetailIzin(String id) async {
    try {
      final token = box.read('token');

      final response = await http.get(
        Uri.parse('http://192.168.1.8:8000/api/izin/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return Map<String, dynamic>.from(body['data']);
      } else {
        print('Gagal mengambil detail izin: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error saat ambil detail izin: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> get filteredRiwayat {
    if (selectedDate.value != null) {
      return daftarIzin.where((item) {
        final tanggal = DateTime.tryParse(item['tanggal_mulai'] ?? '');
        return tanggal != null &&
            tanggal.year == selectedDate.value!.year &&
            tanggal.month == selectedDate.value!.month &&
            tanggal.day == selectedDate.value!.day;
      }).toList();
    } else {
      return daftarIzin.where((item) {
        final tanggal = DateTime.tryParse(item['tanggal_mulai'] ?? '');
        return tanggal != null &&
            tanggal.year == selectedYear.value &&
            tanggal.month == selectedMonth.value;
      }).toList();
    }
  }
}
