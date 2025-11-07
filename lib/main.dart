import 'package:flutter/material.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';
import 'package:ao_gosto_app/utils/app_theme.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_gate.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart'; 
import 'package:ao_gosto_app/state/cart_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ao Gosto Carnes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingGate(),
    );
  }
}

// Wrapper opcional (pode manter ou remover)
class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingFlow.maybeStart(context);
      CartController.instance; // Carrega frete
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}