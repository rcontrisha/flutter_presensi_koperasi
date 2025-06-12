import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () => Get.offAllNamed('/login'));
    return Scaffold(
      body: Center(child: Text('MyApp', style: TextStyle(fontSize: 32))),
    );
  }
}
