import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:presensi_dinkop/Controllers/presensi_controller.dart';
import 'package:presensi_dinkop/Controllers/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = Get.put(ProfileController());
  final presensi = Get.put(PresensiController());

  @override
  void initState() {
    super.initState();
    controller.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = controller.profileData;

        String formatTanggal(String tanggal) {
          try {
            final date = DateTime.parse(tanggal);
            return DateFormat("d MMMM yyyy", "id_ID").format(date);
          } catch (_) {
            return tanggal; // fallback jika parsing gagal
          }
        }

        String jenisKelamin(String? kode) {
          if (kode == 'L') return 'Laki-laki';
          if (kode == 'P') return 'Perempuan';
          return '-';
        }

        final tempat = profile['tempat_lahir'] ?? '-';
        final tgl = profile['tanggal_lahir'] ?? '-';
        final tempatTgl = (tgl != '-' && tempat != '-') ? '$tempat, ${formatTanggal(tgl)}' : '-';
        final jk = jenisKelamin(profile['jenis_kelamin']);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Bagian atas
              SizedBox(
                height: screenHeight * 0.2,
                child: const _TopPortion(),
              ),
              const SizedBox(height: 55), // untuk mengimbangi overflow avatar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  children: [
                    Text(
                      GetStorage().read('user')['name'] ?? 'Nama Pegawai',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile['jabatan'] ?? 'Jabatan Pegawai',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FloatingActionButton.extended(
                              onPressed: () => _showEditProfileSheet(profile),
                              heroTag: 'edit',
                              elevation: 0,
                              label: const Text("Edit Data"),
                              icon: const Icon(Icons.edit),
                            ),
                            FloatingActionButton.extended(
                              onPressed: () => _showChangePasswordSheet(),
                              heroTag: 'edit_password',
                              elevation: 0,
                              label: const Text("Change Password"),
                              icon: const Icon(Icons.vpn_key),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: FloatingActionButton.extended(
                            onPressed: presensi.logout,
                            heroTag: 'logout',
                            elevation: 0,
                            label: const Text("Log Out"),
                            icon: const Icon(Icons.logout),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildProfileDetailRow("Email", GetStorage().read('user')['email']),
                    _buildProfileDetailRow("No HP", profile['no_telpon']),
                    _buildProfileDetailRow("Jenis Kelamin", jk),
                    _buildProfileDetailRow("Alamat", profile['alamat']),
                    _buildProfileDetailRow("Tempat, Tanggal Lahir", tempatTgl),
                    _buildProfileDetailRow("Pendidikan Terakhir", profile['pendidikan_terakhir']),
                    const SizedBox(height: 72)
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileDetailRow(String title, String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          text: "$title: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(Map<dynamic, dynamic> profile) {
    final noHpController = TextEditingController(text: profile['no_telpon'] ?? '');
    final alamatController = TextEditingController(text: profile['alamat'] ?? '');
    final pendidikanController = TextEditingController(text: profile['pendidikan_terakhir'] ?? '');
    final TextEditingController jabatanController = TextEditingController(text: profile['jabatan'] ?? '');
    final TextEditingController tempatLahirController = TextEditingController(text: profile['tempat_lahir'] ?? '');
    final TextEditingController tanggalLahirController = TextEditingController(text: profile['tanggal_lahir'] ?? '');

    String selectedGender = profile['jenis_kelamin'] ?? 'L'; // default ke 'L'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Data Pegawai",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tanggalLahirController,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                ),
                TextField(
                  controller: noHpController,
                  decoration: const InputDecoration(labelText: "No HP"),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: alamatController,
                  decoration: const InputDecoration(labelText: "Alamat"),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: "Jenis Kelamin"),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text("Laki-laki")),
                    DropdownMenuItem(value: 'P', child: Text("Perempuan")),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedGender = value;
                  },
                ),
                TextField(
                  controller: pendidikanController,
                  decoration: const InputDecoration(labelText: "Pendidikan Terakhir"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final data = {
                      'no_telpon': noHpController.text,
                      'alamat': alamatController.text,
                      'jenis_kelamin': selectedGender,
                      'pendidikan_terakhir': pendidikanController.text,
                      'jabatan': jabatanController.text,
                      'tempat_lahir': tempatLahirController.text,
                      'tanggal_lahir': tanggalLahirController.text, // Format yyyy-MM-dd
                    };

                    final success = await controller.updateProfile(data);

                    if (success) {
                      Get.back(); // tutup modal
                      Get.snackbar("Berhasil", "Data profil berhasil diperbarui");
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Change Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Current Password"),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Confirm New Password"),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Tampilkan loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    final success = await controller.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                      confirmPasswordController.text,
                    );

                    Navigator.of(context).pop(); // Tutup dialog loading

                    if (success) {
                      Navigator.of(context).pop(); // Tutup bottom sheet
                      Get.snackbar(
                        "Success",
                        "Password berhasil diperbarui",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    } else {
                      Get.snackbar(
                        "Error",
                        "Gagal memperbarui password",
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.TOP,
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProfileInfoItem {
  final String title;
  final int value;
  const ProfileInfoItem(this.title, this.value);
}

class _TopPortion extends StatelessWidget {
  const _TopPortion();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Supaya bisa overflow keluar container
      children: [
        // Bagian biru (gradient)
        Container(
          height: 170, // Setengah dari tinggi total _TopPortion (anggap totalnya 300)
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xff0043ba), Color(0xff006df1)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        // Foto profil di bawah dan sebagian keluar dari container biru
        Positioned(
          top: 0,
          bottom: -125, // Supaya setengah keluar (dari 150 ukuran avatar)
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
