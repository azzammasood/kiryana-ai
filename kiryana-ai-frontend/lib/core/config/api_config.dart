import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api_base_url_resolver.dart';

/// Resolves API base URL: web env.js → dart-define → assets/config.json → localhost.
class ApiConfig {
  ApiConfig._();

  static late String baseUrl;

  static Future<void> initialize() async {
    var url = readWebApiUrl();
    if (url.isEmpty) {
      const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
      if (fromDefine.isNotEmpty) {
        url = fromDefine;
      }
    }
    if (url.isEmpty) {
      try {
        final raw = await rootBundle.loadString('assets/config.json');
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final fromAsset = map['apiBaseUrl']?.toString() ?? '';
        if (fromAsset.isNotEmpty) {
          url = fromAsset;
        }
      } catch (_) {}
    }
    baseUrl = url.isNotEmpty ? _normalize(url) : 'http://127.0.0.1:8000';
    debugPrint('[ApiConfig] API base URL: $baseUrl');
  }

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
