import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presensi_dinkop/Controllers/presensi_controller.dart';

class RiwayatScreen extends StatelessWidget {
  final presensiC = Get.put(PresensiController());

  RiwayatScreen({super.key}) {
    presensiC.fetchRiwayatPresensi(); // Ambil data saat screen dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Presensi"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterSection(context),
          Expanded(
            child: Obx(() {
              if (presensiC.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredList = presensiC.filteredRiwayat;

              if (filteredList.isEmpty) {
                return const Center(child: Text("Tidak ada riwayat presensi."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  final tanggal = item['tanggal'] ?? '';
                  final jamMasuk = item['jam_masuk'] ?? '-';
                  final jamPulang = item['jam_pulang'] ?? '-';

                  String keterangan;
                  Color badgeColor;

                  if (jamMasuk == null || jamMasuk.isEmpty) {
                    keterangan = 'Tidak Hadir';
                    badgeColor = Colors.redAccent;
                  } else {
                    final masukTime = DateFormat("HH:mm").parse(jamMasuk);
                    final batasTerlambat = DateFormat("HH:mm").parse("07:30");
                    if (masukTime.isAfter(batasTerlambat)) {
                      keterangan = 'Terlambat';
                      badgeColor = Colors.orange;
                    } else {
                      keterangan = 'Hadir';
                      badgeColor = Colors.green;
                    }
                  }

                  return Stack(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                          title: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.parse(tanggal))),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Masuk: $jamMasuk"),
                              Text("Pulang: $jamPulang"),
                              Text("Keterangan: $keterangan"),
                            ],
                          ),
                          onTap: () => _showDetailBottomSheet(context, item, tanggal, jamMasuk, jamPulang, keterangan),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            keterangan,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: presensiC.selectedMonth.value,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text(DateFormat.MMMM('id_ID').format(DateTime(0, month))),
                  );
                }),
                onChanged: (val) {
                  presensiC.selectedMonth.value = val!;
                  presensiC.selectedDate.value = null;
                },
              ),
              DropdownButton<int>(
                value: presensiC.selectedYear.value,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
                onChanged: (val) {
                  presensiC.selectedYear.value = val!;
                  presensiC.selectedDate.value = null;
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Tanggal"),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                    locale: const Locale("id", "ID"),
                  );
                  if (picked != null) {
                    presensiC.selectedDate.value = picked;
                  }
                },
              )
            ],
          )),
    );
  }

  void _showDetailBottomSheet(BuildContext context, Map item, String tanggal, String jamMasuk, String jamPulang, String keterangan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "Detail Presensi",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem("Tanggal", DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.parse(tanggal))),
                  _buildDetailItem("Jam Masuk", jamMasuk),
                  _buildDetailItem("Jam Pulang", jamPulang),
                  _buildDetailItem("Keterangan", keterangan),
                  const SizedBox(height: 20),
                  if (item['foto_masuk'] != null && item['foto_masuk'].toString().isNotEmpty)
                    _buildPhotoCard("Foto Masuk", item['foto_masuk']),
                  const SizedBox(height: 16),
                  if (item['foto_pulang'] != null && item['foto_pulang'].toString().isNotEmpty)
                    _buildPhotoCard("Foto Pulang", item['foto_pulang']),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(String title, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Get.to(() => ImagePreviewScreen(imageUrl: imageUrl, title: title)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                height: 200,
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImagePreviewScreen({super.key, required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 100),
          ),
        ),
      ),
    );
  }
}
