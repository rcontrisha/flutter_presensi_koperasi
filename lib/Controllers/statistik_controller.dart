import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StatistikController extends GetxController {
  var statistik = <String, dynamic>{}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStatistik();
  }

  void fetchStatistik() async {
    isLoading.value = true;
    final token = GetStorage().read('token');
    print(token);

    final response = await http.get(
      Uri.parse('http://192.168.1.23:8000/api/statistik'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      statistik.value = json.decode(response.body);
    } else {
      Get.snackbar('Error', 'Gagal mengambil data statistik');
    }

    isLoading.value = false;
  }
}
