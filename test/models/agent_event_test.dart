import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/models/agent_event.dart';

void main() {
  test('MetaEvent parses correctly', () {
    final event = AgentEvent.fromJson({
      'type': 'meta',
      'containerName': 'c1',
      'sessionName': 'a1',
      'contextMode': 'resume',
      'resumeAttempted': true,
      'resumeSucceeded': true,
      'agentProgram': 'claude',
    });
    expect(event, isA<MetaEvent>());
    final meta = event as MetaEvent;
    expect(meta.containerName, equals('c1'));
    expect(meta.agentProgram, equals('claude'));
    expect(meta.resumeSucceeded, isTrue);
  });

  test('TraceEvent parses correctly', () {
    final event = AgentEvent.fromJson({
      'type': 'trace',
      'text': 'running tool: bash',
    });
    expect(event, isA<TraceEvent>());
    expect((event as TraceEvent).text, equals('running tool: bash'));
  });

  test('ContentDeltaEvent parses correctly', () {
    final event = AgentEvent.fromJson({
      'type': 'content_delta',
      'content': 'Hello, world!',
    });
    expect(event, isA<ContentDeltaEvent>());
    expect((event as ContentDeltaEvent).content, equals('Hello, world!'));
  });

  test('ResultEvent parses correctly', () {
    final event = AgentEvent.fromJson({
      'type': 'result',
      'exitCode': 0,
      'output': 'done',
      'contextMode': null,
      'resumeAttempted': false,
      'resumeSucceeded': false,
      'interrupted': false,
    });
    expect(event, isA<ResultEvent>());
    final result = event as ResultEvent;
    expect(result.exitCode, equals(0));
    expect(result.interrupted, isFalse);
  });

  test('ErrorEvent parses correctly', () {
    final event = AgentEvent.fromJson({
      'type': 'error',
      'error': 'container not found',
    });
    expect(event, isA<ErrorEvent>());
    expect((event as ErrorEvent).error, equals('container not found'));
  });

  test('unknown type throws ArgumentError', () {
    expect(
      () => AgentEvent.fromJson({'type': 'unknown_xyz'}),
      throwsArgumentError,
    );
  });
}
