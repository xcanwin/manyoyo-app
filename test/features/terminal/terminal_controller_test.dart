import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:manyoyo_app/features/terminal/terminal_controller.dart';

/// A fake WebSocket that records sent messages and lets tests inject received messages.
class _FakeSocket implements TerminalSocket {
  final List<dynamic> sent = [];
  final _controller = StreamController<dynamic>.broadcast();
  bool closed = false;

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  void send(dynamic data) => sent.add(data);

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void inject(dynamic data) => _controller.add(data);
}

void main() {
  test('initial state: not connected, no output', () {
    final controller = TerminalController();
    expect(controller.isConnected, isFalse);
    expect(controller.output, isEmpty);
  });

  test('sends resize message on connect', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);

    final resizeMsg = _sent(socket, 'resize');
    expect(resizeMsg, isNotNull);
    expect(resizeMsg!['cols'], equals(80));
    expect(resizeMsg['rows'], equals(24));
    expect(controller.isConnected, isTrue);

    await controller.disconnect();
  });

  test('output message appended to buffer', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);
    socket.inject(jsonEncode({'type': 'output', 'data': 'hello\r\n'}));
    // Allow stream listener to fire.
    await Future<void>.delayed(Duration.zero);

    expect(controller.output, contains('hello\r\n'));

    await controller.disconnect();
  });

  test('sendInput sends input message', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);
    controller.sendInput('ls\n');

    final inputMsg = _sent(socket, 'input');
    expect(inputMsg, isNotNull);
    expect(inputMsg!['data'], equals('ls\n'));

    await controller.disconnect();
  });

  test('resize sends resize message', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);
    // Clear initial resize message.
    socket.sent.clear();
    controller.resize(120, 36);

    final resizeMsg = _sent(socket, 'resize');
    expect(resizeMsg, isNotNull);
    expect(resizeMsg!['cols'], equals(120));
    expect(resizeMsg['rows'], equals(36));

    await controller.disconnect();
  });

  test('disconnect sends close message and closes socket', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);
    await controller.disconnect();

    expect(socket.closed, isTrue);
    expect(controller.isConnected, isFalse);
  });

  test('disconnect remains safe when controller is disposed immediately', () async {
    final controller = TerminalController();
    final socket = _FakeSocket();

    await controller.connectWith(socket, cols: 80, rows: 24);
    final pendingDisconnect = controller.disconnect();
    controller.dispose();
    await pendingDisconnect;

    expect(socket.closed, isTrue);
  });
}

Map<String, dynamic>? _sent(_FakeSocket socket, String type) {
  for (final raw in socket.sent) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      if (msg['type'] == type) return msg;
    } catch (_) {}
  }
  return null;
}
