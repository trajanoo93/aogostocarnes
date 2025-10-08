import 'package:flutter/material.dart';
import 'package:aogosto_carnes_flutter/screens/main_screen.dart';
import 'package:aogosto_carnes_flutter/utils/app_theme.dart';
import 'package:aogosto_carnes_flutter/screens/onboarding/onboarding_gate.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingGate(),
    );
  }
}