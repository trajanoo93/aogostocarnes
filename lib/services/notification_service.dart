import 'dart:io'; // ESSENCIAL pro Platform.isIOS
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Solicita permissão (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('❌ Permissão de notificação negada pelo usuário');
      return;
    }

    // 2. Inscrever nos Tópicos (A MÁGICA ACONTECE AQUI)
    await _subscribeToTopics();

    // 3. Configuração das notificações locais (Android + iOS)
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(initSettings);

    // 4. Notificação quando o app está aberto (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notificação recebida em Foreground: ${message.notification?.title}');
      
      final notification = message.notification;
      if (notification != null) {
        // Mostra o Banner colorido no topo
        showSimpleNotification(
          Text(
            notification.title ?? "Ao Gosto Carnes",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(notification.body ?? ""),
          background: AppColors.primary,
          foreground: Colors.white,
          duration: const Duration(seconds: 6),
          position: NotificationPosition.top,
        );

        // Som e vibração local (Android + iOS system tray)
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Notificações Importantes',
              channelDescription: 'Notificações de pedidos e promoções',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 5. Pega o token (com proteção pro simulador iOS)
    final token = await getToken();
    if (token != null) {
      debugPrint('✅ FCM TOKEN: $token');
    } else {
      debugPrint('⚠️ FCM TOKEN NÃO GERADO (normal no simulador iOS)');
    }
  }

  /// Gerencia a inscrição nos tópicos para o painel PHP funcionar
  static Future<void> _subscribeToTopics() async {
    try {
      // 1. Tópico Geral (Opção "Todos" do painel)
      await _messaging.subscribeToTopic('promocoes');
      debugPrint('✅ Inscrito no tópico: promocoes');

      // 2. Tópico por Sistema (Opção "Android/iOS" do painel)
      if (Platform.isAndroid) {
        await _messaging.subscribeToTopic('android');
        debugPrint('✅ Inscrito no tópico: android');
      } else if (Platform.isIOS) {
        await _messaging.subscribeToTopic('ios');
        debugPrint('✅ Inscrito no tópico: ios');
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao inscrever nos tópicos: $e');
    }
  }

  // FUNÇÃO FINAL — FUNCIONA NO SIMULADOR E NO CELULAR REAL
  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          // No simulador iOS isso sempre retorna null e é normal
          return null;
        }
      }

      final fcmToken = await _messaging.getToken();
      return fcmToken;
    } catch (e) {
      debugPrint('Erro ao gerar FCM token: $e');
      return null;
    }
  }
}