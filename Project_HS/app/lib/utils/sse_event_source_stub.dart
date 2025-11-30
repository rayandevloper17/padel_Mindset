// Cross-platform stub for SSE EventSource.
// Provides a no-op implementation for non-web platforms where dart:html is unavailable.

typedef MessageHandler = void Function(String data);
typedef ErrorHandler = void Function();

class SseEventSource {
  void connect(String url, {MessageHandler? onMessage, ErrorHandler? onError}) {
    // No-op on non-web platforms.
    // You can optionally implement a polling fallback here if needed.
    onError?.call();
  }

  void close() {
    // No-op
  }
}