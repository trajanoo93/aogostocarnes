import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/screens/splash/splash_screen.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  Future<bool> _needsOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    final done = sp.getBool('onboarding_done') ?? false;
    return !done; // true = precisa fazer onboarding
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _needsOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFA4815)),
            ),
          );
        }

        final needsOnboarding = snapshot.data!;

        if (needsOnboarding) {
          /// Abre o onboarding APÓS o layout construir
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OnboardingFlow.maybeStart(context, force: true);
          });
        }

        /// Depois do onboarding → Splash → MainScreen
        return const SplashScreen();
      },
    );
  }
}
