import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/models/session.dart';

void main() {
  test('AgentSession.fromJson parses correctly', () {
    final json = {
      'sessionRef': 'mycontainer~agent1',
      'sessionName': 'agent1',
      'containerName': 'mycontainer',
      'agentId': 'agent1',
      'yolo': 'claude',
      'contextMode': 'resume',
      'isHistoryOnly': false,
      'running': true,
    };
    final s = AgentSession.fromJson(json);
    expect(s.sessionRef, equals('mycontainer~agent1'));
    expect(s.sessionName, equals('agent1'));
    expect(s.containerName, equals('mycontainer'));
    expect(s.agentId, equals('agent1'));
    expect(s.yolo, equals('claude'));
    expect(s.contextMode, equals('resume'));
    expect(s.isHistoryOnly, isFalse);
    expect(s.running, isTrue);
  });

  test('AgentSession.fromJson handles null optional fields', () {
    final json = {
      'sessionRef': 'c~a',
      'sessionName': 'a',
      'containerName': 'c',
      'agentId': 'a',
      'isHistoryOnly': false,
      'running': false,
    };
    final s = AgentSession.fromJson(json);
    expect(s.yolo, isNull);
    expect(s.contextMode, isNull);
  });

  test('ContainerGroup.fromJson parses with agents', () {
    final json = {
      'containerName': 'mycontainer',
      'agents': [
        {
          'sessionRef': 'mycontainer~a1',
          'sessionName': 'a1',
          'containerName': 'mycontainer',
          'agentId': 'a1',
          'isHistoryOnly': false,
          'running': false,
        },
        {
          'sessionRef': 'mycontainer~a2',
          'sessionName': 'a2',
          'containerName': 'mycontainer',
          'agentId': 'a2',
          'isHistoryOnly': true,
          'running': false,
        },
      ],
    };
    final g = ContainerGroup.fromJson(json);
    expect(g.containerName, equals('mycontainer'));
    expect(g.agents.length, equals(2));
    expect(g.agents[0].agentId, equals('a1'));
    expect(g.agents[1].isHistoryOnly, isTrue);
  });

  test('SessionsResponse.fromJson parses list', () {
    final json = {
      'containers': [
        {
          'containerName': 'c1',
          'agents': [],
        },
        {
          'containerName': 'c2',
          'agents': [],
        },
      ],
    };
    final r = SessionsResponse.fromJson(json);
    expect(r.containers.length, equals(2));
    expect(r.containers[0].containerName, equals('c1'));
  });
}
