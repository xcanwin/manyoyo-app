import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A mock [HttpClientAdapter] that returns a fixed response.
///
/// Supports optional request capturing, custom response body, and
/// custom response headers.
class StubAdapter implements HttpClientAdapter {
  StubAdapter({
    required this.statusCode,
    this.body = '',
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;

  /// All captured request options (populated only when callers inspect them).
  final List<RequestOptions> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return ResponseBody.fromString(body, statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}
