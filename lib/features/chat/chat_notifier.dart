import 'package:flutter/foundation.dart';

import 'package:manyoyo_app/models/agent_event.dart';
import 'package:manyoyo_app/models/message.dart';

class ChatNotifier extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _error;
  ChatMessage? _currentAssistant;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  void loadHistory(List<dynamic> rawMessages) {
    _messages.clear();
    for (final raw in rawMessages) {
      _messages.add(ChatMessage.fromJson(raw as Map<String, dynamic>));
    }
    notifyListeners();
  }

  void addUserMessage(String content) {
    _messages.add(ChatMessage(role: MessageRole.user, content: content));
    notifyListeners();
  }

  Future<void> processStream(Stream<AgentEvent> stream) async {
    _isStreaming = true;
    _error = null;
    _currentAssistant = null;
    notifyListeners();

    try {
      await for (final event in stream) {
        _handleEvent(event);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _currentAssistant = null;
      _isStreaming = false;
      notifyListeners();
    }
  }

  void _handleEvent(AgentEvent event) {
    switch (event) {
      case MetaEvent():
        break;
      case TraceEvent(:final text):
        if (_currentAssistant == null) {
          _currentAssistant = ChatMessage(
            role: MessageRole.assistant,
            content: '',
          );
          _messages.add(_currentAssistant!);
        }
        _currentAssistant!.traces.add(text);
        notifyListeners();
      case ContentDeltaEvent(:final content):
        if (_currentAssistant == null) {
          _currentAssistant = ChatMessage(
            role: MessageRole.assistant,
            content: '',
          );
          _messages.add(_currentAssistant!);
        }
        _currentAssistant!.content += content;
        notifyListeners();
      case ResultEvent():
        _currentAssistant = null;
      case ErrorEvent(:final error):
        _error = error;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
