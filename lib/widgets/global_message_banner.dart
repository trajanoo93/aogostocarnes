// lib/widgets/global_message_banner.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/services/remote_config_service.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';

class GlobalMessageBanner extends StatelessWidget {
  const GlobalMessageBanner({super.key});

  MaterialColor _getColorByType(String type) {
    switch (type) {
      case 'warning':
        return Colors.amber;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'warning':
        return 'Alerta';
      case 'error':
        return 'Atenção';
      case 'success':
        return 'Mensagem';
      default:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RemoteConfig>(
      future: RemoteConfigService.fetchConfig(),
      builder: (context, snapshot) {
        final message = snapshot.data?.customMessage;

        // ✅ SÓ MOSTRA SE HABILITADO E TEM MENSAGEM
        if (message == null || !message.enabled || message.message.isEmpty) {
          return const SizedBox.shrink();
        }

        final color = _getColorByType(message.type);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Ícone
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconByType(message.type),
                    color: color.shade700,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 12),

                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}