import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/izin_controller.dart';

class DaftarIzinScreen extends StatelessWidget {
  final izinC = Get.put(IzinController());

  DaftarIzinScreen({super.key}) {
    izinC.fetchIzinList(); // Ambil data saat halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Izin"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Obx(() {
              if (izinC.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final daftarIzin = izinC.daftarIzin;

              if (daftarIzin.isEmpty) {
                return const Center(child: Text("Belum ada pengajuan izin."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daftarIzin.length,
                itemBuilder: (context, index) {
                  final item = daftarIzin[index];
                  final jenisIzin = item['jenis_izin'] ?? '-';
                  final mulai = item['tanggal_mulai'] ?? '';
                  final selesai = item['tanggal_selesai'] ?? '';
                  final status = item['status'] ?? 'Menunggu';

                  Color badgeColor;
                  switch (status.toLowerCase()) {
                    case 'diterima':
                      badgeColor = Colors.green;
                      break;
                    case 'ditolak':
                      badgeColor = Colors.redAccent;
                      break;
                    default:
                      badgeColor = Colors.orange;
                  }

                  return Stack(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.description, color: Colors.indigo),
                          title: Text(jenisIzin),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mulai: ${DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(mulai))}"),
                              Text("Selesai: ${DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(selesai))}"),
                              Text("Status: $status"),
                            ],
                          ),
                          onTap: () => _showDetailIzinBottomSheet(context, item),
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
                            status,
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () => _showAjukanIzinBottomSheet(context),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Obx(() => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                value: izinC.selectedMonth.value,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text(DateFormat.MMMM('id_ID').format(DateTime(0, month))),
                  );
                }),
                onChanged: (val) {
                  izinC.selectedMonth.value = val!;
                  izinC.fetchIzinList(bulan: val, tahun: izinC.selectedYear.value);
                },
              ),
              DropdownButton<int>(
                value: izinC.selectedYear.value,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
                onChanged: (val) {
                  izinC.selectedYear.value = val!;
                  izinC.fetchIzinList(bulan: izinC.selectedMonth.value, tahun: val);
                },
              ),
            ],
          )),
    );
  }

  void _showDetailIzinBottomSheet(BuildContext context, Map item) {
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
                      "Detail Izin",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailItem("Jenis Izin", item['jenis_izin'] ?? '-'),
                  _buildDetailItem("Tanggal Mulai", DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(item['tanggal_mulai']))),
                  _buildDetailItem("Tanggal Selesai", DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(item['tanggal_selesai']))),
                  _buildDetailItem("Status", item['status'] ?? '-'),
                  _buildDetailItem("Keterangan", item['keterangan'] ?? '-'),
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
          SizedBox(width: 120, child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  void _showAjukanIzinBottomSheet(BuildContext context) {
    final keteranganController = TextEditingController();
    String? selectedJenisIzin;
    DateTime? tanggalMulai;
    DateTime? tanggalSelesai;
    PlatformFile? selectedFile;

    final List<String> jenisIzinList = [
      "Diperbantukan atau Ditugaskan pada Instansi Vertikal",
      "Melaksanakan Cuti",
      "Menghadiri Rapat, Perjalanan Dinas, dan Tugas Lain yang Berkaitan dengan Kedinasan",
      "Mengikuti Diklat",
      "Presensi Manual",
      "Tugas Belajar",
      "Tugas Kedinasan",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Ajukan Izin",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ),
                const SizedBox(height: 16),

                /// Dropdown Jenis Izin
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Jenis Izin"),
                  isExpanded: true, // Penting agar dropdown menyesuaikan lebar parent
                  items: jenisIzinList.map((jenis) {
                    return DropdownMenuItem<String>(
                      value: jenis,
                      child: Text(
                        jenis,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedJenisIzin = val;
                  },
                ),
                const SizedBox(height: 8),

                /// Picker Tanggal
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            izinC.setTanggalMulai(picked);
                          }
                        },
                        child: Obx(() => Text(
                          izinC.tanggalMulai.value != null
                              ? DateFormat('dd-MM-yyyy').format(izinC.tanggalMulai.value!)
                              : "Pilih Tanggal Mulai",
                        )),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            izinC.setTanggalSelesai(picked);
                          }
                        },
                        child: Obx(() => Text(
                          izinC.tanggalSelesai.value != null
                              ? DateFormat('dd-MM-yyyy').format(izinC.tanggalSelesai.value!)
                              : "Pilih Tanggal Selesai",
                        )),
                      ),
                    ),
                  ],
                ),

                /// Keterangan
                TextField(
                  controller: keteranganController,
                  decoration: const InputDecoration(labelText: "Keterangan (opsional)"),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),

                /// Upload File Pendukung
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    );
                    if (result != null) {
                      izinC.selectedFile.value = result.files.first;
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Upload File Pendukung (opsional)"),
                ),
                Obx(() {
                  final file = izinC.selectedFile.value;
                  return file != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("File: ${file.name}", style: const TextStyle(fontSize: 12)),
                        )
                      : const SizedBox();
                }),
                const SizedBox(height: 16),

                /// Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () async {
                      if (selectedJenisIzin == null || izinC.tanggalMulai.value == null || izinC.tanggalSelesai.value == null) {
                        Get.snackbar("Gagal", "Lengkapi semua data terlebih dahulu",
                            backgroundColor: Colors.redAccent, colorText: Colors.white);
                        return;
                      }

                      print('Jenis Izin: $selectedJenisIzin');
                      print('Tanggal Mulai: ${izinC.tanggalMulai.value}');
                      print('Tanggal Selesai: ${izinC.tanggalSelesai.value}');
                      print('File Path: ${izinC.selectedFile.value?.path}');

                      final success = await izinC.ajukanIzin(
                        jenisIzin: selectedJenisIzin!,
                        tanggalMulai: DateFormat('yyyy-MM-dd').format(izinC.tanggalMulai.value!),
                        tanggalSelesai: DateFormat('yyyy-MM-dd').format(izinC.tanggalSelesai.value!),
                        keterangan: keteranganController.text.isNotEmpty ? keteranganController.text : null,
                        filePendukung: izinC.selectedFile.value,
                      );

                      if (success) {
                        Navigator.pop(context);
                        izinC.fetchIzinList();
                        Get.snackbar("Berhasil", "Pengajuan izin berhasil dikirim",
                            backgroundColor: Colors.green, colorText: Colors.white);
                      } else {
                        Get.snackbar("Gagal", "Gagal mengajukan izin",
                            backgroundColor: Colors.redAccent, colorText: Colors.white);
                      }
                    },
                    child: const Text("Kirim Pengajuan", style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
