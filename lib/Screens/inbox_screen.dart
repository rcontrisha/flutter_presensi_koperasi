import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:presensi_dinkop/Controllers/inbox_controller.dart';
import 'package:presensi_dinkop/Screens/pdf_viewer.dart';

class InboxScreen extends StatelessWidget {
  final InboxController controller = Get.put(InboxController());

  InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.fetchSuratPeringatan();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox Surat Peringatan'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.suratList.isEmpty) {
          return const Center(child: Text('Tidak ada surat peringatan.'));
        }

        final readIds = GetStorage().read<List>('read_surat_ids') ?? [];

        return ListView.builder(
          itemCount: controller.suratList.length,
          itemBuilder: (context, index) {
            final surat = controller.suratList[index];
            final isRead = readIds.contains(surat['id']);
            final url = 'http://192.168.1.8:8000/storage/${surat['file_path']}';
            final judul = "${surat['judul_surat']} - ${GetStorage().read('user')['name']}";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.grey[300] : Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: isRead ? Colors.grey : Colors.indigo,
                    size: 30,
                  ),
                ),
                title: Text(
                  surat['judul_surat'],
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Tanggal: ${surat['tanggal_kirim']}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  controller.markAsRead(surat['id']);
                  Get.to(() => PDFViewScreen(url: url, judul: judul));
                },
              ),
            );
          },
        );
      }),
    );
  }
}
