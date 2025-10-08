
import 'package:flutter/material.dart';
import 'package:aogosto_carnes_flutter/api/onboarding_service.dart';
import 'package:aogosto_carnes_flutter/screens/onboarding/onboarding_flow.dart';
import 'package:aogosto_carnes_flutter/screens/main_screen.dart';

class OnboardingGate extends StatelessWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OnboardingService().hasProfile(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final needsOnboarding = !(snap.data ?? false);
        return _Gate(needsOnboarding: needsOnboarding);
      },
    );
  }
}

class _Gate extends StatefulWidget {
  final bool needsOnboarding;
  const _Gate({required this.needsOnboarding});

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    // Dispara o onboarding novo apenas uma vez quando necessário.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_kicked && mounted && widget.needsOnboarding) {
        _kicked = true;
        await OnboardingFlow.maybeStart(context, force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A app principal abre normalmente; se precisar, o OnboardingFlow aparece em cima.
    return const MainScreen();
  }
}
