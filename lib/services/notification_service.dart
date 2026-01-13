// lib/services/notification_service.dart
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
      print('Permissão de notificação negada pelo usuário');
      return;
    }

    // 2. Configuração das notificações locais (Android + iOS)
    const AndroidInitializationSettings android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(initSettings);

    // 3. Notificação quando o app está aberto (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
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

        // Som e vibração local (Android + iOS)
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

    // 4. Pega o token (com proteção pro simulador iOS)
    final token = await getToken();
    if (token != null) {
      print('FCM TOKEN GERADO COM SUCESSO: $token');
    } else {
      print('FCM TOKEN NÃO GERADO (normal no simulador iOS)');
    }
  }

  // FUNÇÃO FINAL — FUNCIONA NO SIMULADOR E NO CELULAR REAL
  static Future<String?> getToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          print('APNS token não disponível (simulador iOS ou permissão negada)');
          return null;
        }
      }

      final fcmToken = await _messaging.getToken();
      return fcmToken;
    } catch (e) {
      print('Erro ao gerar FCM token: $e');
      return null;
    }
  }
}