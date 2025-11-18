// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ao_gosto_app/firebase_options.dart';

import 'package:ao_gosto_app/screens/main_screen.dart';
import 'package:ao_gosto_app/utils/app_theme.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_gate.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartController.instance,
      child: MaterialApp(
        title: 'Ao Gosto Carnes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const OnboardingGate(),
      ),
    );
  }
}

// REMOVA O MainScreenWrapper SE NÃO FOR USADO!
// Se você ainda usa ele no onboarding_gate.dart, mantenha abaixo:

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
      CartController.instance; // Garante que o carrinho carregue
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}