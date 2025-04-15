import 'package:flutter/material.dart';

import 'screens/LoginScreen.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  runApp(MyApp(
    
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      theme: ThemeData(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.blue,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      elevation: 0,
    ),
  ),
    );
  }
}
