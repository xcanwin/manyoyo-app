import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

/// Abstraction over a WebSocket connection for testing.
abstract interface class TerminalSocket {
  Stream<dynamic> get messages;
  void send(dynamic data);
  Future<void> close();
}

/// Production implementation backed by dart:io WebSocket.
class _IoTerminalSocket implements TerminalSocket {
  _IoTerminalSocket(this._ws);

  final WebSocket _ws;

  @override
  Stream<dynamic> get messages => _ws;

  @override
  void send(dynamic data) => _ws.add(data);

  @override
  Future<void> close() => _ws.close();
}

class TerminalController extends ChangeNotifier {
  TerminalController() {
    _terminal = Terminal(maxLines: 10000);
  }

  late final Terminal _terminal;
  TerminalSocket? _socket;
  StreamSubscription<dynamic>? _sub;
  final StringBuffer _outputBuffer = StringBuffer();

  bool _isConnected = false;

  Terminal get terminal => _terminal;
  bool get isConnected => _isConnected;
  String get output => _outputBuffer.toString();

  /// Connect via a real WebSocket URL (production use).
  Future<void> connect({
    required String wsUrl,
    required String cookieHeader,
    required int cols,
    required int rows,
  }) async {
    final ws = await WebSocket.connect(
      wsUrl,
      headers: cookieHeader.isNotEmpty ? {'Cookie': cookieHeader} : null,
    );
    await connectWith(_IoTerminalSocket(ws), cols: cols, rows: rows);
  }

  /// Connect with an injected socket (testing use).
  Future<void> connectWith(
    TerminalSocket socket, {
    required int cols,
    required int rows,
  }) async {
    await _sub?.cancel();
    await _socket?.close();
    _socket = socket;
    _isConnected = true;

    // Wire terminal output → socket input
    _terminal.onOutput = (data) => sendInput(data);

    _sub = socket.messages.listen(
      _onMessage,
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
    );

    // Send initial resize
    _sendJson({'type': 'resize', 'cols': cols, 'rows': rows});
    notifyListeners();
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      if (type == 'output') {
        final data = msg['data'] as String? ?? '';
        _outputBuffer.write(data);
        _terminal.write(data);
        notifyListeners();
      } else if (type == 'status') {
        notifyListeners();
      }
    } catch (_) {}
  }

  void _onDisconnected() {
    _isConnected = false;
    _sub = null;
    _socket = null;
    notifyListeners();
  }

  void sendInput(String data) {
    _sendJson({'type': 'input', 'data': data});
  }

  void resize(int cols, int rows) {
    _sendJson({'type': 'resize', 'cols': cols, 'rows': rows});
  }

  void _sendJson(Map<String, dynamic> msg) {
    _socket?.send(jsonEncode(msg));
  }

  Future<void> disconnect() async {
    _sendJson({'type': 'close'});
    await _sub?.cancel();
    await _socket?.close();
    _onDisconnected();
  }
}
