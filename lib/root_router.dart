import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding/onboarding_gate.dart';
import 'screens/splash/splash_screen.dart';



class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  Future<bool> _hasCompletedOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('onboarding_done') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasCompletedOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final didOnboard = snapshot.data!;

        if (!didOnboard) {
          /// 1º acesso → sem splash → onboarding
          return const OnboardingGate();
        }

        /// Próximos acessos → splash → main
        return const SplashScreen();

      },
    );
  }
}
