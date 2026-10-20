import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {

    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos',
          ),
        ),
      );

      return;
    }

    try {

      setState(() {
        loading = true;
      });

      final response = await http.post(

        Uri.parse(
          '${ApiService.baseUrl}/login',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'email': email,
          'password': password,

        }),
      );

      final data =
          jsonDecode(response.body);

      if (data['success']) {

        await handleAuthSuccess(data);

      } else {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              data['message'],
            ),
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );

    } finally {

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> handleAuthSuccess(Map<String, dynamic> data) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'token',
      data['token'],
    );

    await prefs.setString(
      'username',
      data['user']['username'],
    );

    await prefs.setString(
      'email',
      data['user']['email'],
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Login realizado com sucesso!',
        ),
      ),
    );

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  static bool googleInitialized = false;

  Future<void> loginWithGoogle() async {

    try {

      setState(() {
        loading = true;
      });

      final googleSignIn = GoogleSignIn.instance;

      if (!googleInitialized) {
        await googleSignIn.initialize(
          serverClientId: ApiService.googleServerClientId,
        );
        googleInitialized = true;
      }

      final account = await googleSignIn.authenticate();

      final idToken = account.authentication.idToken;

      if (idToken == null) {
        throw Exception('Google não retornou o token de login');
      }

      final response = await http.post(

        Uri.parse(
          '${ApiService.baseUrl}/auth/google',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (data['success']) {

        await handleAuthSuccess(data);

      } else if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              data['message'] ?? 'Erro ao entrar com Google',
            ),
          ),
        );
      }

    } on GoogleSignInException catch (e) {

      // Usuário fechou a janela do Google: não é erro
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              'Erro no login com Google: ${e.description ?? e.code.name}',
            ),
          ),
        );
      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              e.toString(),
            ),
          ),
        );
      }

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF020817),

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(24),

          child: Container(

            width: 420,

            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(

              color: Colors.black.withOpacity(0.88),

              borderRadius: BorderRadius.circular(24),

              border: Border.all(
                color: Colors.white10,
              ),

              boxShadow: [

                BoxShadow(
                  color: const Color(0xFF39FF14)
                      .withOpacity(0.08),
                  blurRadius: 40,
                ),
              ],
            ),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Center(

                  child: Text(

                    'PLAYBOXED',

                    style: TextStyle(

                      color: Color(0xFF39FF14),

                      fontSize: 42,

                      fontWeight: FontWeight.bold,

                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(

                  child: Text(

                    'TRACK. CONNECT. LEVEL UP.',

                    style: TextStyle(

                      color:
                          Colors.white.withOpacity(0.7),

                      fontSize: 14,

                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                buildInput(
                  'EMAIL ADDRESS',
                  emailController,
                  Icons.email_outlined,
                ),

                const SizedBox(height: 24),

                buildInput(
                  'PASSWORD',
                  passwordController,
                  Icons.lock_outline,
                  obscure: true,
                ),

                const SizedBox(height: 32),

                SizedBox(

                  width: double.infinity,

                  height: 58,

                  child: ElevatedButton(

                    onPressed:
                        loading ? null : login,

                    style: ElevatedButton.styleFrom(

                      backgroundColor:
                          const Color(0xFF39FF14),

                      foregroundColor: Colors.black,

                      shape: RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: loading

                        ? const SizedBox(

                            height: 22,
                            width: 22,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )

                        : const Row(

                            mainAxisAlignment:
                                MainAxisAlignment.center,

                            children: [

                              Text(

                                'SIGN IN TO PLAYBOXED',

                                style: TextStyle(

                                  fontWeight:
                                      FontWeight.bold,

                                  fontSize: 15,

                                  letterSpacing: 1,
                                ),
                              ),

                              SizedBox(width: 8),

                              Icon(Icons.arrow_forward),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(

                  children: [

                    const Expanded(
                      child: Divider(color: Colors.white10),
                    ),

                    Padding(

                      padding: const EdgeInsets.symmetric(horizontal: 12),

                      child: Text(

                        'OU',

                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Divider(color: Colors.white10),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(

                  width: double.infinity,

                  height: 58,

                  child: OutlinedButton(

                    onPressed:
                        loading ? null : loginWithGoogle,

                    style: OutlinedButton.styleFrom(

                      foregroundColor: Colors.white,

                      side: const BorderSide(
                        color: Colors.white24,
                      ),

                      shape: RoundedRectangleBorder(

                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),

                    child: const Row(

                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Text(

                          'G',

                          style: TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        SizedBox(width: 12),

                        Text(

                          'CONTINUAR COM GOOGLE',

                          style: TextStyle(

                            fontWeight:
                                FontWeight.bold,

                            fontSize: 15,

                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Center(

                  child: Row(

                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Text(

                        'New to the platform? ',

                        style: TextStyle(
                          color:
                              Colors.white.withOpacity(0.7),
                        ),
                      ),

                      GestureDetector(

                        onTap: () {

                          Navigator.pushReplacement(

                            context,

                            MaterialPageRoute(

                              builder: (_) =>
                                  const SignupScreen(),
                            ),
                          );
                        },

                        child: const Text(

                          'CREATE ACCOUNT',

                          style: TextStyle(

                            color:
                                Color(0xFF39FF14),

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(

    String label,

    TextEditingController controller,

    IconData icon, {

    bool obscure = false,

  }) {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(

          label,

          style: TextStyle(

            color: Colors.white.withOpacity(0.75),

            fontSize: 13,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        TextField(

          controller: controller,

          obscureText: obscure,

          style: const TextStyle(
            color: Colors.white,
          ),

          decoration: InputDecoration(

            hintText: label,

            hintStyle: const TextStyle(
              color: Colors.white38,
            ),

            prefixIcon: Icon(
              icon,
              color: Colors.white54,
            ),

            filled: true,

            fillColor: const Color(0xFF081225),

            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),

            border: OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(12),

              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(12),

              borderSide: BorderSide(
                color: Colors.white10,
              ),
            ),

            focusedBorder: OutlineInputBorder(

              borderRadius:
                  BorderRadius.circular(12),

              borderSide: const BorderSide(
                color: Color(0xFF39FF14),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}