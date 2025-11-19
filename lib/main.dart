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

Future<void> main() async {
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

        // Remove overscroll azul do iOS / Android
        scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),

        // Remove erros visuais de overflow + mantém UI estável
        builder: (context, child) {
          // Evita caixas amarelas/pretas de overflow
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return const SizedBox.shrink();
          };

          // Trava escala de texto e bold do simulador
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
              boldText: false,
            ),
            child: child!,
          );
        },

        theme: AppTheme.lightTheme,
        home: const OnboardingGate(),
      ),
    );
  }
}

// -----------------------------------------------------------
// MAINSCREEN WRAPPER (Mantido pois pode ser usado no Onboarding)
// -----------------------------------------------------------

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
      OnboardingFlow.maybeStart(context);   // inicia onboarding se necessário
      CartController.instance;              // inicializa carrinho
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();              // tela principal do app
  }
}
