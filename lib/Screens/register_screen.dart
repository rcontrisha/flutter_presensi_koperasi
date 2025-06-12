import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:presensi_dinkop/Controllers/auth_controller.dart';

class RegisterScreen extends StatelessWidget {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final auth = Get.find<AuthController>();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Obx(() => ModalProgressHUD(
            inAsyncCall: auth.isLoading.value,
            color: Colors.blueAccent,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Image.asset('assets/images/background.png'),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: 60.0, bottom: 20.0, left: 20.0, right: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Register',
                        style: TextStyle(fontSize: 50.0),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Let\'s get',
                            style: TextStyle(fontSize: 30.0),
                          ),
                          Text(
                            'you on board',
                            style: TextStyle(fontSize: 30.0),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          TextField(
                            controller: nameC,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: 'Nama Lengkap',
                              labelText: 'Nama Lengkap',
                            ),
                          ),
                          SizedBox(height: 20.0),
                          TextField(
                            controller: emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                          SizedBox(height: 10.0),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff447def),
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        onPressed: auth.isLoading.value
                            ? null
                            : () => auth.registerUser(
                                  nameC.text.trim(),
                                  emailC.text.trim(),
                                ),
                        child: Text(
                          'Daftar',
                          style: TextStyle(fontSize: 20.0, color: Colors.white),
                        ),
                      ),                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun?',
                            style: TextStyle(fontSize: 18.0),
                          ),
                          GestureDetector(
                            onTap: () => Get.toNamed('/login'),
                            child: Text(
                              ' Masuk',
                              style:
                                  TextStyle(fontSize: 18.0, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
