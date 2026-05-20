import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('window.KIRYANA_API_BASE_URL')
external String? get _windowApiBaseUrl;

/// Reads API URL from index.html meta tag, then window.KIRYANA_API_BASE_URL.
String readWebApiUrl() {
  final meta = web.document.querySelector('meta[name="kiryana-api-base"]');
  final fromMeta = meta?.getAttribute('content')?.trim() ?? '';
  if (fromMeta.isNotEmpty) {
    return fromMeta;
  }
  final fromWindow = _windowApiBaseUrl?.trim() ?? '';
  if (fromWindow.isNotEmpty) {
    return fromWindow;
  }
  return '';
}
