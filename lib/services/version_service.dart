import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  // URL QUE VOCÊ ACABOU DE GERAR NO FIREBASE
  static const String _versionUrl =
      'https://ao-gosto-app-c0b31.web.app/app_version.json';

  /// Retorna true se o usuário PRECISA atualizar (forçado)
  static Future<bool> needsForcedUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // ex: 1.0.0

      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final minimumVersion = data['minimum_version'] as String;
      final forceUpdate = data['force_update'] as bool? ?? true;

      if (!forceUpdate) return false;

      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(minimumVersion);

      return current < minimum;
    } catch (e) {
      return false; // nunca trava o app se der erro
    }
  }

  /// Converte "1.2.3" → 10203
  static int _parseVersion(String version) {
    final parts = version.split('.').map(int.tryParse).whereType<int>().toList();
    while (parts.length < 3) parts.add(0);
    return parts[0] * 10000 + parts[1] * 100 + parts[2];
  }

  /// Pega a URL correta da loja
  static Future<String> getStoreUrl() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      final data = json.decode(response.body);
      return Platform.isIOS
          ? data['update_url_ios']
          : data['update_url_android'];
    } catch (e) {
      return Platform.isIOS
          ? 'https://apps.apple.com/br/app/ao-gosto-carnes/id6444686962'
          : 'https://play.google.com/store/apps/details?id=br.com.app.gpu2907388.gpu56a2b15e2a377eaf273ff3023830b24d&pli=1';
    }
  }
}