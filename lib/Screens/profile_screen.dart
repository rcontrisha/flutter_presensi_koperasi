import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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

  final noHpController = TextEditingController();
  final alamatController = TextEditingController();
  final pendidikanController = TextEditingController();
  final jabatanController = TextEditingController();
  final tempatLahirController = TextEditingController();
  final tanggalLahirController = TextEditingController();

  String selectedGender = 'L';

  @override
  void initState() {
    super.initState();
    controller.fetchProfile();
  }

  @override
  void dispose() {
    noHpController.dispose();
    alamatController.dispose();
    pendidikanController.dispose();
    jabatanController.dispose();
    tempatLahirController.dispose();
    tanggalLahirController.dispose();
    super.dispose();
  }

  void _onAvatarTap() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Lihat Foto Profil'),
                onTap: () {
                  Navigator.pop(context);
                  _showFullProfilePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ganti Foto Profil'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullProfilePhoto() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            // Ganti dengan URL foto profil user jika sudah ada
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      Get.snackbar(
        "Mengunggah...",
        "Nama file: ${picked.name}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
      final success = await controller.uploadPhoto(picked);
      if (success) {
        // Sudah ada snackbar di controller, tidak perlu lagi di sini
      }
    } else {
      Get.snackbar(
        "Batal",
        "Tidak ada foto yang dipilih",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = controller.profileData.value;
        if (profile == null) {
          return _buildCreateProfileForm();
        }
        return _buildProfileView(context, profile, screenHeight);
      }),
    );
  }

  Widget _buildProfileView(
    BuildContext context,
    Map<String, dynamic> profile,
    double screenHeight,
  ) {
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
    final tempatTgl =
        (tgl != '-' && tempat != '-') ? '$tempat, ${formatTanggal(tgl)}' : '-';
    final jk = jenisKelamin(profile['jenis_kelamin']);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Bagian atas
          SizedBox(
            height: screenHeight * 0.2,
            child: _TopPortion(
              onAvatarTap: _onAvatarTap,
              photoUrl: (profile['foto_profil'] != null && profile['foto_profil'].toString().isNotEmpty)
                  ? 'http://192.168.1.23:8000/storage/${profile['foto_profil']}'
                  : 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
            ),
          ),
          const SizedBox(height: 55), // untuk mengimbangi overflow avatar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Text(
                  GetStorage().read('user')['name'] ?? 'Nama Pegawai',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  profile['jabatan'] ?? 'Jabatan Pegawai',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                _buildProfileDetailRow(
                  "Email",
                  GetStorage().read('user')['email'],
                ),
                _buildProfileDetailRow("No HP", profile['no_telpon']),
                _buildProfileDetailRow("Jenis Kelamin", jk),
                _buildProfileDetailRow("Alamat", profile['alamat']),
                _buildProfileDetailRow("Tempat, Tanggal Lahir", tempatTgl),
                _buildProfileDetailRow(
                  "Pendidikan Terakhir",
                  profile['pendidikan_terakhir'],
                ),
                const SizedBox(height: 72),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProfileForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              "Lengkapi Data Profil",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const SizedBox(height: 24),
      
            // ========== Form Fields ==========
            _buildInputLabel("Tanggal Lahir"),
            TextField(
              controller: tanggalLahirController,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  tanggalLahirController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(picked);
                }
              },
              decoration: _buildInputDecoration("Pilih tanggal lahir"),
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("Tempat Lahir"),
            TextField(
              controller: tempatLahirController,
              decoration: _buildInputDecoration("Contoh: Yogyakarta"),
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("Jabatan"),
            TextField(
              controller: jabatanController,
              decoration: _buildInputDecoration("Contoh: Staf IT"),
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("No HP"),
            TextField(
              controller: noHpController,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration("Contoh: 0812xxxxxxx"),
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("Alamat"),
            TextField(
              controller: alamatController,
              decoration: _buildInputDecoration("Contoh: Jl. Merpati No. 123"),
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("Jenis Kelamin"),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: _buildInputDecoration("Pilih jenis kelamin"),
              items: const [
                DropdownMenuItem(value: 'L', child: Text("Laki-laki")),
                DropdownMenuItem(value: 'P', child: Text("Perempuan")),
              ],
              onChanged: (value) {
                if (value != null) selectedGender = value;
              },
            ),
            const SizedBox(height: 16),
      
            _buildInputLabel("Pendidikan Terakhir"),
            TextField(
              controller: pendidikanController,
              decoration: _buildInputDecoration("Contoh: S1 Teknik Informatika"),
            ),
            const SizedBox(height: 32),
      
            // ========== Tombol Simpan ==========
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text(
                  "Simpan Profil",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final data = {
                    'no_telpon': noHpController.text,
                    'alamat': alamatController.text,
                    'jenis_kelamin': selectedGender,
                    'pendidikan_terakhir': pendidikanController.text,
                    'jabatan': jabatanController.text,
                    'tempat_lahir': tempatLahirController.text,
                    'tanggal_lahir': tanggalLahirController.text,
                  };
      
                  final success = await controller.createProfile(data);
                  if (success) {
                    Get.snackbar("Berhasil", "Data profil berhasil disimpan");
                    controller.fetchProfile(); // Refresh
                  }
                },
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 1.5),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
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
    final noHpController = TextEditingController(
      text: profile['no_telpon'] ?? '',
    );
    final alamatController = TextEditingController(
      text: profile['alamat'] ?? '',
    );
    final pendidikanController = TextEditingController(
      text: profile['pendidikan_terakhir'] ?? '',
    );
    final TextEditingController jabatanController = TextEditingController(
      text: profile['jabatan'] ?? '',
    );
    final TextEditingController tempatLahirController = TextEditingController(
      text: profile['tempat_lahir'] ?? '',
    );
    final TextEditingController tanggalLahirController = TextEditingController(
      text: profile['tanggal_lahir'] ?? '',
    );

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
                      tanggalLahirController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(picked);
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
                  decoration: const InputDecoration(
                    labelText: "Pendidikan Terakhir",
                  ),
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
                      'tanggal_lahir':
                          tanggalLahirController.text, // Format yyyy-MM-dd
                    };

                    final success = await controller.updateProfile(data);

                    if (success) {
                      Get.back(); // tutup modal
                      Get.snackbar(
                        "Berhasil",
                        "Data profil berhasil diperbarui",
                      );
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
                  decoration: const InputDecoration(
                    labelText: "Current Password",
                  ),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "New Password"),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Tampilkan loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (_) =>
                              const Center(child: CircularProgressIndicator()),
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
  final VoidCallback? onAvatarTap;
  final String photoUrl;
  const _TopPortion({this.onAvatarTap, this.photoUrl = ''});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Bagian biru (gradient)
        Container(
          height:
              170, // Setengah dari tinggi total _TopPortion (anggap totalnya 300)
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
            child: GestureDetector(
              onTap: onAvatarTap,
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: NetworkImage(photoUrl),
                        ),
                      ),
                    ),
                    // Tambahkan icon edit di pojok bawah
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.camera_alt, size: 22, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
