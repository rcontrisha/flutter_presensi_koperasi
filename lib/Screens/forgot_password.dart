import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presensi_dinkop/Controllers/auth_controller.dart';

class ForgotPasswordUI extends StatelessWidget {
  final emailC = TextEditingController();
  final auth = Get.find<AuthController>();

  ForgotPasswordUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Image.asset('assets/images/background.png'),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 60.0,
              bottom: 20.0,
              left: 20.0,
              right: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 40.0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your email',
                      style: TextStyle(fontSize: 30.0),
                    ),
                    const SizedBox(height: 20.0),
                    TextField(
                      controller: emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff447def),
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onPressed: auth.isLoading.value
                          ? null
                          : () => auth.forgotPassword(emailC.text),
                      child: auth.isLoading.value
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Reset Password',
                              style: TextStyle(
                                  fontSize: 20.0, color: Colors.white),
                            ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
