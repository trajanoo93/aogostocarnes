import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    /// Aguarda 2.2s (tempo médio do Lottie) e redireciona para o MainScreen
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/lottie/LogoSplashScreen.json',
          width: 240,
          height: 240,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
