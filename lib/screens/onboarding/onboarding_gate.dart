// lib/screens/onboarding/onboarding_gate.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkOnboarding(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFA4815))));
        }

        if (snapshot.data == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OnboardingFlow.maybeStart(context, force: true);
          });
        }

        return const MainScreen();
      },
    );
  }

  Future<bool> _checkOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    final done = sp.getBool('onboarding_done') ?? false;
    return !done;
  }
}