// lib/screens/onboarding/onboarding_gate.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/api/onboarding_service.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService().hasProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFA4815)),
              ),
            ),
          );
        }

        final hasProfile = snapshot.data ?? false;

        if (!hasProfile) {
          // Usuário NUNCA fez onboarding → força o fluxo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OnboardingFlow.maybeStart(context, force: true);
          });
        }

        // Em ambos os casos (com ou sem perfil), vai direto pra MainScreen
        return const MainScreen();
      },
    );
  }
}