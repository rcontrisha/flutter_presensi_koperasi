import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class InboxController extends GetxController {
  var isLoading = false.obs;
  var suratList = [].obs;
  var unreadCount = 0.obs;

  Future<void> fetchSuratPeringatan() async {
    isLoading.value = true;

    final box = GetStorage();
    final token = box.read('token');
    final readIds = box.read<List>('read_surat_ids') ?? [];

    final url = Uri.parse('http://192.168.1.8:8000/api/peringatan');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        suratList.value = data;

        // Hitung yang belum dibaca berdasarkan ID surat
        unreadCount.value = data.where((e) => !readIds.contains(e['id'])).length;
      } else {
        suratList.value = [];
        Get.snackbar('Error', 'Gagal mengambil data surat peringatan');
      }
    } catch (e) {
      suratList.value = [];
      Get.snackbar('Error', 'Terjadi kesalahan: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void markAsRead(int suratId) {
    final box = GetStorage();
    final readIds = box.read<List>('read_surat_ids') ?? [];

    if (!readIds.contains(suratId)) {
      readIds.add(suratId);
      box.write('read_surat_ids', readIds);
      unreadCount.value = suratList.where((e) => !readIds.contains(e['id'])).length;
    }
  }
}
