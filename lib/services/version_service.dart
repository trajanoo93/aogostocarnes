import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  static const String _versionUrl =
      'https://ao-gosto-app-c0b31.web.app/app_version.json';

  /// Retorna true se o usuário PRECISA atualizar (forçado)
  static Future<bool> needsForcedUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version; // ex: "13.0.3"
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0; // ex: 130004

      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final data = json.decode(response.body) as Map<String, dynamic>;

      final forceUpdate = data['force_update'] as bool? ?? false;
      if (!forceUpdate) return false;

      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final platformData = data[platformKey] as Map<String, dynamic>?;

      if (platformData == null) return false;

      final minimumVersion = (platformData['minimum_version'] as String?) ?? '0.0.0';
      final minimumBuild = (platformData['minimum_build'] as num?)?.toInt() ?? 0;

      final currentV = _parseVersion(currentVersion);
      final minimumV = _parseVersion(minimumVersion);

      // 1) Se versão atual < mínima -> força
      if (currentV < minimumV) return true;

      // 2) Se versão atual == mínima e build atual < mínimo -> força
      if (currentV == minimumV && currentBuild < minimumBuild) return true;

      return false;
    } catch (_) {
      return false; // nunca trava o app se der erro
    }
  }

  /// Retorna a URL correta da loja (por plataforma)
  static Future<String> getStoreUrl() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return _fallbackStoreUrl();
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final platformData = data[platformKey] as Map<String, dynamic>?;

      final storeUrl = platformData?['store_url'] as String?;
      if (storeUrl == null || storeUrl.isEmpty) return _fallbackStoreUrl();

      return storeUrl;
    } catch (_) {
      return _fallbackStoreUrl();
    }
  }

  static String _fallbackStoreUrl() {
    return Platform.isIOS
        ? 'https://apps.apple.com/br/app/ao-gosto-carnes/id6444686962'
        : 'https://play.google.com/store/apps/details?id=br.com.app.gpu2907388.gpu56a2b15e2a377eaf273ff3023830b24d';
  }

  /// Converte "13.0.3" → 130003 (comparação simples e estável)
  static int _parseVersion(String version) {
    final parts = version
        .split('.')
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();

    while (parts.length < 3) {
      parts.add(0);
    }

    return parts[0] * 10000 + parts[1] * 100 + parts[2];
  }
}
