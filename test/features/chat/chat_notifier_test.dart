import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/features/chat/chat_notifier.dart';
import 'package:manyoyo_app/models/agent_event.dart';
import 'package:manyoyo_app/models/message.dart';

// Build a mock stream from NDJSON lines.
Stream<AgentEvent> makeEventStream(List<Map<String, dynamic>> events) async* {
  for (final e in events) {
    yield AgentEvent.fromJson(e);
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('initial state is idle with no messages', () {
    final notifier = ChatNotifier();
    expect(notifier.messages, isEmpty);
    expect(notifier.isStreaming, isFalse);
    expect(notifier.error, isNull);
  });

  test('content_delta events accumulate into assistant message', () async {
    final notifier = ChatNotifier();

    final stream = makeEventStream([
      {'type': 'meta', 'containerName': 'c', 'sessionName': 'a', 'agentProgram': 'claude', 'resumeAttempted': false, 'resumeSucceeded': false},
      {'type': 'content_delta', 'content': 'Hello'},
      {'type': 'content_delta', 'content': ', world'},
      {'type': 'content_delta', 'content': '!'},
      {'type': 'result', 'exitCode': 0, 'output': '', 'resumeAttempted': false, 'resumeSucceeded': false, 'interrupted': false},
    ]);

    await notifier.processStream(stream);

    expect(notifier.messages, hasLength(1));
    expect(notifier.messages.first.role, equals(MessageRole.assistant));
    expect(notifier.messages.first.content, equals('Hello, world!'));
    expect(notifier.isStreaming, isFalse);
  });

  test('user message is prepended before streaming', () async {
    final notifier = ChatNotifier();

    final stream = makeEventStream([
      {'type': 'result', 'exitCode': 0, 'output': '', 'resumeAttempted': false, 'resumeSucceeded': false, 'interrupted': false},
    ]);

    notifier.addUserMessage('Hello agent');
    await notifier.processStream(stream);

    expect(notifier.messages.first.role, equals(MessageRole.user));
    expect(notifier.messages.first.content, equals('Hello agent'));
  });

  test('trace events are captured', () async {
    final notifier = ChatNotifier();

    final stream = makeEventStream([
      {'type': 'trace', 'text': 'Tool call: bash'},
      {'type': 'content_delta', 'content': 'done'},
      {'type': 'result', 'exitCode': 0, 'output': '', 'resumeAttempted': false, 'resumeSucceeded': false, 'interrupted': false},
    ]);

    await notifier.processStream(stream);

    expect(notifier.messages.first.traces, contains('Tool call: bash'));
  });

  test('error event sets error state', () async {
    final notifier = ChatNotifier();

    final stream = makeEventStream([
      {'type': 'error', 'error': 'container crashed'},
    ]);

    await notifier.processStream(stream);

    expect(notifier.error, equals('container crashed'));
    expect(notifier.isStreaming, isFalse);
  });

  test('loadHistory populates messages from JSON list', () {
    final notifier = ChatNotifier();

    notifier.loadHistory([
      {'role': 'user', 'content': 'hi'},
      {'role': 'assistant', 'content': 'hello'},
    ]);

    expect(notifier.messages, hasLength(2));
    expect(notifier.messages[0].role, equals(MessageRole.user));
    expect(notifier.messages[1].role, equals(MessageRole.assistant));
  });
}
