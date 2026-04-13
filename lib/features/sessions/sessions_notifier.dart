import 'package:flutter/foundation.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/models/session.dart';

class SessionsNotifier extends ChangeNotifier {
  SessionsNotifier(this._client);

  final ApiClient _client;
  List<ContainerGroup> _containers = [];
  bool _isLoading = false;
  String? _error;

  List<ContainerGroup> get containers => _containers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _client.get<Map<String, dynamic>>('/api/sessions');
      final data = resp.data;
      if (data != null) {
        _containers = SessionsResponse.fromJson(data).containers;
      }
    } catch (e) {
      _error = e.toString();
      _containers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeSession(String sessionRef) async {
    try {
      await _client.post<dynamic>(
        '/api/sessions/${Uri.encodeComponent(sessionRef)}/remove',
      );
    } catch (_) {}
    await loadSessions();
  }

  Future<void> createSession({
    required String containerName,
    String? yolo,
  }) async {
    await _client.post<dynamic>(
      '/api/sessions',
      data: {'containerName': containerName, 'yolo': ?yolo},
    );
    await loadSessions();
  }

  Future<void> createAgent({required String sessionRef, String? yolo}) async {
    await _client.post<dynamic>(
      '/api/sessions/${Uri.encodeComponent(sessionRef)}/agents',
      data: {'yolo': ?yolo},
    );
    await loadSessions();
  }
}
