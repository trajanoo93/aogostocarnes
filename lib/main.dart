// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ao_gosto_app/widgets/global_message_banner.dart'; 
import 'package:ao_gosto_app/firebase_options.dart';
import 'package:ao_gosto_app/screens/main_screen.dart';
import 'package:ao_gosto_app/utils/app_theme.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_gate.dart';
import 'package:ao_gosto_app/screens/onboarding/onboarding_flow.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/state/customer_provider.dart';
import 'package:ao_gosto_app/root_router.dart';
import 'package:ao_gosto_app/screens/update/forced_update_screen.dart';
import 'package:ao_gosto_app/services/version_service.dart';
import 'package:ao_gosto_app/services/notification_service.dart';
import 'package:ao_gosto_app/services/remote_config_service.dart';  // ✅ NOVO
import 'package:ao_gosto_app/screens/maintenance/maintenance_screen.dart';  // ✅ NOVO

/// Handler chamado quando uma notificação é recebida
/// com o app em **background** ou **terminado**.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('🔵 Mensagem recebida em BACKGROUND: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 Handler para mensagens em background / app fechado
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🔔 Quando o usuário toca na notificação e abre o app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🟡 App aberto pela notificação: ${message.messageId}');
  });

  // Inicializa FCM + locais + gera token
  await NotificationService.initialize();

  // 🔔 Inscreve o dispositivo no tópico de promoções
  try {
    await FirebaseMessaging.instance.subscribeToTopic('promocoes');
    debugPrint('✅ Inscrito no tópico "promocoes"');
  } catch (e) {
    debugPrint('❌ Erro ao inscrever no tópico "promocoes": $e');
  }

  // === CARREGA O CLIENTE ===
  final sp = await SharedPreferences.getInstance();
  final phone = sp.getString('customer_phone');
  final name = sp.getString('customer_name');

  if (phone != null && name != null && phone.isNotEmpty && name.isNotEmpty) {
    await CustomerProvider.instance.loadOrCreateCustomer(
      name: name,
      phone: phone,
    );
  }

  // ✅ VERIFICA SE PRECISA FORÇAR ATUALIZAÇÃO
  final needsUpdate = await VersionService.needsForcedUpdate();

  if (needsUpdate) {
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ForcedUpdateScreen(),
      ),
    );
    return;
  }

  // ✅ VERIFICA CONFIGURAÇÕES REMOTAS (OMS)
  final remoteConfig = await RemoteConfigService.fetchConfig();

  

  // ✅ TUDO OK, INICIA APP NORMALMENTE
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: CartController.instance),
        ChangeNotifierProvider.value(value: CustomerProvider.instance),
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