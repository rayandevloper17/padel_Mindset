// Web-only SSE client wrapper using EventSource
// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

typedef MessageHandler = void Function(String data);
typedef ErrorHandler = void Function();

class SseEventSource {
  html.EventSource? _es;

  void connect(String url, {MessageHandler? onMessage, ErrorHandler? onError}) {
    _es = html.EventSource(url, withCredentials: false);
    _es!.onMessage.listen((evt) => onMessage?.call(evt.data as String));
    _es!.onError.listen((_) => onError?.call());
  }

  void close() {
    _es?.close();
    _es = null;
  }
}
