// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ao_gosto_app/firebase_options.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';
import 'package:ao_gosto_app/utils/app_theme.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_gate.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/state/customer_provider.dart'; // ← NOVO
import 'package:ao_gosto_app/root_router.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // === CARREGA O CLIENTE LOGO NO INÍCIO DO APP ===
  final sp = await SharedPreferences.getInstance();
  final phone = sp.getString('customer_phone');
  final name = sp.getString('customer_name');

  if (phone != null && name != null && phone.isNotEmpty && name.isNotEmpty) {
    // Tenta carregar o cliente do Firestore (ou cria se não existir)
    await CustomerProvider.instance.loadOrCreateCustomer(
      name: name,
      phone: phone,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: CartController.instance),
        ChangeNotifierProvider.value(value: CustomerProvider.instance), // ← ADICIONADO
      ],
      child: MaterialApp(
        title: 'Ao Gosto Carnes',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const ScrollBehavior().copyWith(overscroll: false),

        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return const SizedBox.shrink();
          };

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
              boldText: false,
            ),
            child: child!,
          );
        },

        theme: AppTheme.lightTheme,
        home: const RootRouter(),
      ),
    );
  }
}

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
      CartController.instance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}