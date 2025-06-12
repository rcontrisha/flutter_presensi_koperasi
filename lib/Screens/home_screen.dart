import 'dart:io';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presensi_dinkop/Controllers/inbox_controller.dart';
import 'package:presensi_dinkop/Controllers/presensi_controller.dart';
import 'package:presensi_dinkop/Controllers/statistik_controller.dart';
import 'package:presensi_dinkop/Screens/inbox_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final presensiC = Get.put(PresensiController());
    final statistikC = Get.put(StatistikController());
    final riwayatC = Get.put(PresensiController());
    final inboxC = Get.put(InboxController());

    // Jalankan cek status presensi dan fetch riwayat setelah build
    Future.delayed(Duration.zero, () {
      presensiC.cekStatusPresensiHariIni();
      riwayatC.fetchRiwayatPresensi();
      inboxC.fetchSuratPeringatan();
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Presensi Pegawai'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(() {
            final count = inboxC.unreadCount.value;
            return Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                    tooltip: 'Inbox Surat Peringatan',
                    onPressed: () {
                      Get.to(() => InboxScreen());
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildAttendanceCard(context),
                    const SizedBox(height: 16),
                    _buildQuickStats(),
                    const SizedBox(height: 16),
                    _buildRecentHistory(riwayatC),
                    const SizedBox(height: 80), // Tambahan ruang agar tidak mentok ke bottom bar
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.indigo[50],
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.indigo,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(GetStorage().read('user')['name'] ?? 'Nama Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(GetStorage().read('pegawai')['jabatan'] ?? 'Jabatan'),
        trailing: Icon(Icons.verified, color: Colors.green),
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context) {
    final presensiC = Get.find<PresensiController>();

    bool isInTimeRange(String status) {
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      if (status == "belum presensi") {
        // Waktu absen masuk: 06:00 - 09:00
        return currentTime.hour >= 7 && currentTime.hour <= 8;
      } else if (status == "sudah absen masuk") {
        // Waktu absen pulang: 16:00 - 18:00
        return currentTime.hour >= 15 && currentTime.hour <= 17;
      }

      return false;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Presensi Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Obx(() {
              if (presensiC.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Masuk: ${presensiC.jamHadir.value}"),
                  Text("Pulang: ${presensiC.jamPulang.value}"),
                ],
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              String buttonText = "Absen";
              bool isDisabled = false;

              final status = presensiC.status.value;

              // Atur teks tombol
              switch (status) {
                case "belum presensi":
                  buttonText = "Absen Masuk";
                  break;
                case "sudah absen masuk":
                  buttonText = "Absen Pulang";
                  break;
                case "sudah absen pulang":
                  buttonText = "Presensi Selesai";
                  isDisabled = true;
                  break;
                default:
                  buttonText = "Absen";
              }

              // Tambahkan validasi waktu presensi
              // if (!isInTimeRange(status)) {
              //   isDisabled = true;
              // }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: Text(buttonText, style: const TextStyle(color: Colors.white)),
                  onPressed: isDisabled ? null : () => _showCameraModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final statistikC = Get.find<StatistikController>();

    return Obx(() {
      if (statistikC.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final data = statistikC.statistik;

      if (data.isEmpty) {
        return const Text("Statistik belum tersedia.");
      }

      final jumlahPresensi = data['jumlah_presensi'] ?? 0;
      final jumlahIzin = data['jumlah_izin'] ?? 0;
      final jumlahAbsen = data['jumlah_absen'] ?? 0;

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Statistik Bulan Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: Colors.greenAccent,
                        value: jumlahPresensi.toDouble(),
                        title: 'Hadir\n$jumlahPresensi',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        titlePositionPercentageOffset: 0.55,
                      ),
                      PieChartSectionData(
                        color: Colors.yellowAccent,
                        value: jumlahIzin.toDouble(),
                        title: 'Izin\n$jumlahIzin',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        titlePositionPercentageOffset: 0.55,
                      ),
                      PieChartSectionData(
                        color: Colors.redAccent,
                        value: jumlahAbsen.toDouble(),
                        title: 'Absen\n$jumlahAbsen',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        titlePositionPercentageOffset: 0.55,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Hari Kerja: ${data['total_hari_kerja'] ?? 0}"),
              Text("Persentase Presensi: ${data['presentase'] ?? 0}%"),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecentHistory(PresensiController controller) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Riwayat Terakhir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
          
                final riwayat = controller.riwayatPresensi.take(3).toList();
          
                if (riwayat.isEmpty) {
                  return const Text("Belum ada riwayat presensi.");
                }
          
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: riwayat.map((item) {
                    final rawTanggal = item['tanggal'] ?? '';
                    final jamMasuk = item['jam_masuk'];
                    final dateTime = DateTime.tryParse(rawTanggal);
          
                    String tanggalFormatted = rawTanggal;
                    if (dateTime != null) {
                      tanggalFormatted = DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(dateTime);
                    }
          
                    String status;
                    if (jamMasuk == null) {
                      status = 'Tidak Hadir';
                    } else if (jamMasuk.compareTo('08:00:00') > 0) {
                      status = 'Terlambat (${jamMasuk.substring(0, 5).replaceAll(':', '.')})';
                    } else {
                      status = 'Hadir (${jamMasuk.substring(0, 5).replaceAll(':', '.')})';
                    }
          
                    return Text("$tanggalFormatted - $status");
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _menuButton(Icons.history, "Riwayat", () => Get.toNamed('/riwayat')),
        _menuButton(Icons.edit_calendar, "Izin", () => Get.toNamed('/izin')),
        _menuButton(Icons.logout, "Logout", () => Get.offAllNamed('/login')),
      ],
    );
  }

  Widget _menuButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label)
        ],
      ),
    );
  }

  void _showCameraModal(BuildContext context) async {
    // Minta izin kamera terlebih dahulu
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    // Tambahkan delay agar tidak crash karena channel belum siap
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Get.snackbar("Error", "Kamera tidak tersedia");
        return;
      }

      final firstCamera = cameras.first;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          builder: (_, controller) => CameraPreviewSheet(camera: firstCamera),
        ),
      );
    } catch (e) {
      Get.snackbar("Error", "Gagal membuka kamera: $e");
    }
  }
}

class CameraPreviewSheet extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewSheet({super.key, required this.camera});

  @override
  State<CameraPreviewSheet> createState() => _CameraPreviewSheetState();
}

class _CameraPreviewSheetState extends State<CameraPreviewSheet> {
  CameraController? _controller;
  String _location = 'Mencari lokasi...';
  String _timestamp = '';
  double? _latitude;
  double? _longitude;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getLocation();
    _setTimestamp();
  }

  void _initCamera([int cameraIndex = 0]) async {
    try {
      _cameras = await availableCameras();
      _currentCameraIndex = cameraIndex;
      _controller = CameraController(_cameras[cameraIndex], ResolutionPreset.high);
      await _controller?.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      Get.snackbar("Error", "Gagal inisialisasi kamera: $e");
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    final newIndex = (_currentCameraIndex + 1) % _cameras.length;
    _controller?.dispose();
    _initCamera(newIndex);
  }

  void _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    _latitude = position.latitude;
    _longitude = position.longitude;

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _location = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
      });
    } else {
      setState(() {
        _location = "${position.latitude}, ${position.longitude}";
      });
    }
  }

  void _setTimestamp() {
    final now = DateTime.now();
    final formatter = DateFormat('dd MMM yyyy - HH:mm');
    setState(() {
      _timestamp = formatter.format(now);
    });
  }

  Future<File?> _capturePictFromPreview() async {
    try {
      RenderRepaintBoundary boundary =
          _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      var image = await boundary.toImage(pixelRatio: 3.0); // tinggi resolusi
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Simpan ke file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/presensi_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      print("Error capturing preview: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  final GlobalKey _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final name = box.read('user')['name'] ?? 'Nama Pegawai';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // ✅ Screenshot area
                      RepaintBoundary(
                        key: _previewKey,
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: CameraPreview(_controller!),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black54,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    Text(_timestamp, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      child: Text(
                                        _location,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ❌ Tidak ikut terscreenshot
                      Positioned(
                        top: 36,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.4),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
                            onPressed: _switchCamera,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Ambil Foto Absen", style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final file = await _capturePictFromPreview();
                      if (file != null) {
                        final success = await Get.find<PresensiController>().kirimPresensi(
                          foto: file,
                          lokasi: _location,
                          latitude: _latitude!,
                          longitude: _longitude!,
                        );

                        if (success) {
                          Navigator.of(context).pop();

                          Future.delayed(const Duration(milliseconds: 300), () {
                            Get.snackbar(
                              "Berhasil",
                              "Presensi berhasil dikirim!",
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          });
                        }
                      } else {
                        Get.snackbar("Gagal", "Tidak bisa mengambil gambar.");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
