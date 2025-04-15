// ignore_for_file: unused_element, unnecessary_string_interpolations

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dimensions.dart';
import '../url.dart';
import 'HomePage.dart';
import 'SignUpScreen.dart';
import 'package:http/http.dart' as http;


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isEmailHintVisible = true;
  bool _isPasswordHintVisible = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  Timer? _hintTimer;

  final FlutterSecureStorage storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      _handleFocusChange(_emailFocusNode, _emailController,
          (visible) => setState(() => _isEmailHintVisible = visible));
    });

    _passwordFocusNode.addListener(() {
      _handleFocusChange(_passwordFocusNode, _passwordController,
          (visible) => setState(() => _isPasswordHintVisible = visible));
    });
  }

  void _handleFocusChange(FocusNode focusNode, TextEditingController controller,
      void Function(bool visible) updateHintVisibility) {
    if (focusNode.hasFocus) {
      updateHintVisibility(false);
      _startHintTimer(controller, updateHintVisibility);
    } else if (controller.text.isEmpty) {
      updateHintVisibility(true);
      _cancelHintTimer();
    }
  }

  void _startHintTimer(TextEditingController controller,
      void Function(bool visible) updateHintVisibility) {
    _cancelHintTimer();
    if (controller.text.isEmpty) {
      _hintTimer = Timer(const Duration(seconds: 2), () {
        updateHintVisibility(true);
      });
    }
  }

  void _cancelHintTimer() {
    _hintTimer?.cancel();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String getApiUrl() {
    // Adjust URL based on the platform
    return "$baseUrl/login"; // Default for Android Emulator (192.168.0.31)


  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint("Please fix the errors in the form");
      return;
    }

    setState(() => _isLoading = true);

    final String apiUrl = getApiUrl();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    final Map<String, String> loginData = {
      "username": email, // Ensure this is the expected key for email in the API
      "password": password,
    };

    try {
      debugPrint("Sending login request to: $apiUrl");
      debugPrint("Login Data: $loginData");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey("token")) {
          String token = responseData["token"] ?? "";
          int userId = responseData["userid"] ?? 0;
          String role = responseData["role"] ?? "";

          // Securely store token and email
          await storage.write(key: "token", value: token);
          await storage.write(key: "email", value: email); // Store email
          await storage.write(key: "userId", value: userId.toString());

          // Store other user data in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt("userId", userId);
          await prefs.setString("role", role);

          debugPrint("Token Saved: $token");
          debugPrint("Email Saved: $email");

          if (!context.mounted) return;

          // Navigate to HomeScreen
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen()), //HomeScreen()), //MyCertificateList()),
          );
        } else {
          debugPrint("Login failed: Token missing in response");
        }
      } else {
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData["message"] ?? "Invalid credentials!";
        debugPrint("$errorMessage");
      }
    } catch (e) {
      debugPrint("Error: Unable to connect to server");
      debugPrint("Login Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _cancelHintTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFocused = _emailFocusNode.hasFocus || _passwordFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!isFocused)
              Container(
                height: Dimensions.fontSize(context, 340),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/blue_top_image.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: Dimensions.fontSize(context, 48),
                          letterSpacing: -0.5,
                          color: Color(0xFFFFFFFF),
                          shadows: [
                            Shadow(
                              color:
                                  // ignore: deprecated_member_use
                                  Colors.black.withOpacity(0.4), // Shadow color
                              blurRadius: 10, // Shadow blur radius
                              offset: Offset(2, 2), // Shadow offset
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Dimensions.fontSize(context, 20)),
                      CircleAvatar(
                        radius: Dimensions.iconSize(context, 85),
                        backgroundImage: AssetImage('assets/profile_pic.png'),
                      ),
                    ],
                  ),
                ),
              ),
            if (isFocused)
              Padding(
                padding: EdgeInsets.only(top: Dimensions.fontSize(context, 50)),
                child: Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: Dimensions.fontSize(context, 48),
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),
              ),
            SizedBox(height: isFocused ? Dimensions.fontSize(context, 40) : Dimensions.fontSize(context, 80)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.fontSize(context, 30)),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      showCursor: false,
                      decoration: InputDecoration(
                        hintText: _isEmailHintVisible ? 'Email ID' : null,
                        hintStyle: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: Dimensions.fontSize(context, 16),
                          height: Dimensions.fontSize(context, 1.33),
                          letterSpacing: 0.4,
                          color: Color(0xFF000000),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFA3A3A5),
                            width: 2.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF4680FE), width: 2.5),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFA3A3A5), width: 2.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // final emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        // if (!emailRegex.hasMatch(value))
                        if (!value.contains('@')) {
                          return 'Enter a valid email id';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: Dimensions.fontSize(context, 30)),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      showCursor: false,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: _isPasswordHintVisible ? 'Password' : null,
                        hintStyle: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: Dimensions.fontSize(context, 16),
                          height: Dimensions.fontSize(context, 1.33),
                          letterSpacing: 0.4,
                          color: Color(0xFF000000),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFA3A3A5),
                            width: 2.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF4680FE), width: 2.5),
                        ),
                        errorBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFA3A3A5), width: 2.5),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a valid password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: Dimensions.fontSize(context, 40)),
                    if (isFocused)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'New User? ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              fontSize: Dimensions.fontSize(context, 14),
                              letterSpacing: 0.4,
                              color: Color(0xFFA29595),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up Here',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                fontSize: Dimensions.fontSize(context, 14),
                                letterSpacing: 0.4,
                                color: Color(0xFF4680FE),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFF4680FE),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: Dimensions.fontSize(context, 10)),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4680FE),
                        padding:
                            EdgeInsets.symmetric(horizontal: Dimensions.fontSize(context, 100), vertical: Dimensions.fontSize(context, 15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: Dimensions.fontSize(context, 21),
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    if (!isFocused)
                      Column(
                        children: [
                          SizedBox(height: Dimensions.fontSize(context, 20)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'New User? ',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  fontSize: Dimensions.fontSize(context, 14),
                                  letterSpacing: 0.4,
                                  color: Color(0xFFA29595),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignUpScreen()),
                                  );
                                },
                                child: Text(
                                  'Sign Up Here',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w400,
                                    fontSize: Dimensions.fontSize(context, 14),
                                    letterSpacing: 0.4,
                                    color: Color(0xFF4680FE),
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF4680FE),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
