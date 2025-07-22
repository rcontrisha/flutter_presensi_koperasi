import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:presensi_dinkop/Controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final RxBool rememberMe = false.obs;

  @override
  void initState() {
    super.initState();
    final box = GetStorage();

    final savedEmail = box.read('remembered_email');
    if (savedEmail != null) {
      emailC.text = savedEmail;
    }

    final rememberStatus = box.read('remember_me');
    if (rememberStatus != null && rememberStatus == true) {
      rememberMe.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: ModalProgressHUD(
            inAsyncCall: auth.isLoading.value,
            color: Colors.blueAccent,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Image.asset('assets/images/background.png'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(fontSize: 50.0),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Welcome back,', style: TextStyle(fontSize: 30.0)),
                            Text('please login', style: TextStyle(fontSize: 30.0)),
                            Text('to your account', style: TextStyle(fontSize: 30.0)),
                          ],
                        ),
                        Column(
                          children: [
                            TextFormField(
                              controller: emailC,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                labelText: 'Email',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email required';
                                if (!value.contains('@')) return 'Invalid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              controller: passC,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Password',
                                labelText: 'Password',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password required';
                                return null;
                              },
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () {
                                  Get.toNamed('/forgot-password');
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(fontSize: 14.0, color: Colors.blue),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Obx(() => Checkbox(
                                      value: rememberMe.value,
                                      onChanged: (val) => rememberMe.value = val ?? false,
                                    )),
                                const Text('Remember Me'),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff447def),
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final box = GetStorage();
                              if (rememberMe.value) {
                                box.write('remembered_email', emailC.text.trim());
                              } else {
                                box.remove('remembered_email');
                              }
                              await auth.loginUser(
                                emailC.text.trim(),
                                passC.text.trim(),
                                rememberMe.value, // <--- ini penting!
                              );
                            }
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 20.0, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      child: SizedBox(
        width: 60.0,
        height: 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.black87),
        ),
      ),
    );
  }
}
