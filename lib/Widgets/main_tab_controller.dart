import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:presensi_dinkop/Controllers/tab_controller.dart';
import 'package:presensi_dinkop/Screens/home_screen.dart';
import 'package:presensi_dinkop/Screens/izin_screen.dart';
import 'package:presensi_dinkop/Screens/riwayat-presensi_screen.dart';
import 'package:presensi_dinkop/Screens/profile_screen.dart';

class MainTabController extends StatelessWidget {
  MainTabController({super.key});

  final List<Widget> _pages = [
    const HomeScreen(),
    RiwayatScreen(),
    DaftarIzinScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final tabController = Get.find<TabNavigationController>();

    return Obx(() => Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: _pages[tabController.currentIndex.value],
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DotNavigationBar(
                currentIndex: tabController.currentIndex.value,
                onTap: tabController.changeTab,
                marginR: const EdgeInsets.symmetric(horizontal: 10),
                paddingR: const EdgeInsets.symmetric(vertical: 6),
                enableFloatingNavBar: true,
                items: [
                  DotNavigationBarItem(
                      icon: Icon(Icons.home), selectedColor: Colors.brown),
                  DotNavigationBarItem(
                      icon: Icon(Icons.history), selectedColor: Colors.brown),
                  DotNavigationBarItem(
                      icon: Icon(Icons.edit_calendar),
                      selectedColor: Colors.brown),
                  DotNavigationBarItem(
                      icon: Icon(Icons.person), selectedColor: Colors.brown),
                ],
              ),
            ),
          ),
        ));
  }
}
