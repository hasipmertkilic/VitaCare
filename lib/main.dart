import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vitacare/screens/welcome/welcome_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).timeout(const Duration(seconds: 15));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaCare',
      theme: ThemeData(useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}
