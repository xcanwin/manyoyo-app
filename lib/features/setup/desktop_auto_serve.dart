import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const String _desktopAutoServeEnv = 'MANYOYO_DESKTOP_AUTO_SERVE';
const String _desktopAutoServeListenEnv = 'MANYOYO_DESKTOP_AUTO_SERVE_LISTEN';
const String _desktopAutoServeRootEnv = 'MANYOYO_DESKTOP_AUTO_SERVE_ROOT';
const String _desktopAutoServeNodeEnv = 'MANYOYO_DESKTOP_AUTO_SERVE_NODE';
const String _defaultListen = '127.0.0.1:3000';

bool isTruthyEnv(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'on';
}

bool supportsDesktopAutoServe() => Platform.isMacOS || Platform.isWindows;

bool shouldAutoServeOnDesktop() {
  return supportsDesktopAutoServe() &&
      isTruthyEnv(Platform.environment[_desktopAutoServeEnv]);
}

String randomToken([int length = 16]) {
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < length; i += 1) {
    buffer.write(random.nextInt(16).toRadixString(16));
  }
  return buffer.toString();
}

String? findRepoRootFromDirectory(Directory? start) {
  if (start == null || start.path.trim().isEmpty) return null;
  final sep = Platform.pathSeparator;
  var current = start.absolute;
  while (true) {
    if (File('${current.path}${sep}bin${sep}manyoyo.js').existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
  }
  return null;
}

String? resolveDesktopAutoServeRepoRoot() {
  final envRoot = (Platform.environment[_desktopAutoServeRootEnv] ?? '').trim();
  if (envRoot.isNotEmpty) {
    return findRepoRootFromDirectory(Directory(envRoot));
  }
  final candidates = <Directory>[
    Directory.current,
    File(Platform.resolvedExecutable).parent,
  ];
  final pwd = (Platform.environment['PWD'] ?? '').trim();
  if (pwd.isNotEmpty) candidates.add(Directory(pwd));
  for (final candidate in candidates) {
    final root = findRepoRootFromDirectory(candidate);
    if (root != null) return root;
  }
  return null;
}

class DesktopAutoServeResult {
  const DesktopAutoServeResult({
    required this.baseUrl,
    required this.authUser,
    required this.authPass,
    required this.process,
  });

  final String baseUrl;
  final String authUser;
  final String authPass;
  final Process process;
}

Future<bool> isProcessExited(Process process) async {
  final exitFuture = process.exitCode.then((_) => true);
  final timeoutFuture = Future<bool>.delayed(
    const Duration(milliseconds: 10),
    () => false,
  );
  return Future.any<bool>([exitFuture, timeoutFuture]);
}

Future<bool> probeManyoyo(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response =
        await request.close().timeout(const Duration(seconds: 2));
    await response.drain<void>();
    return response.statusCode >= 200 && response.statusCode < 500;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}

Future<void> waitForServerReady(
  Process process,
  Uri baseUri,
  String Function() getLog,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 25));
  while (DateTime.now().isBefore(deadline)) {
    if (await isProcessExited(process)) {
      final log = getLog();
      throw StateError(log.isEmpty ? 'manyoyo serve 已提前退出。' : log);
    }
    if (await probeManyoyo(baseUri)) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('等待 MANYOYO 服务启动超时。');
}

Future<Cookie> fetchAuthCookie(
  Uri baseUri,
  String authUser,
  String authPass,
) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.postUrl(baseUri.replace(path: '/auth/login'));
    request.followRedirects = false;
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'username': authUser, 'password': authPass}));
    final response =
        await request.close().timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await utf8.decoder.bind(response).join();
      throw StateError(body.isEmpty ? '自动登录失败。' : body);
    }
    Cookie? cookie;
    for (final item in response.cookies) {
      if (item.name == 'manyoyo_web_auth') {
        cookie = item;
        break;
      }
    }
    await response.drain<void>();
    if (cookie == null) throw StateError('未获取到 manyoyo_web_auth Cookie。');
    return cookie;
  } finally {
    client.close(force: true);
  }
}

Future<DesktopAutoServeResult> startDesktopAutoServe({
  required void Function(String) onLog,
}) async {
  final repoRoot = resolveDesktopAutoServeRepoRoot();
  if (repoRoot == null) {
    throw StateError(
      '未找到 manyoyo 仓库根目录。可设置 MANYOYO_DESKTOP_AUTO_SERVE_ROOT=/abs/path 后再重试。',
    );
  }

  final listen =
      (Platform.environment[_desktopAutoServeListenEnv] ?? '').trim().isEmpty
      ? _defaultListen
      : (Platform.environment[_desktopAutoServeListenEnv] ?? '').trim();
  final nodeBin =
      (Platform.environment[_desktopAutoServeNodeEnv] ?? '').trim().isEmpty
      ? 'node'
      : (Platform.environment[_desktopAutoServeNodeEnv] ?? '').trim();
  final authUser = 'manyoyo_flutter_${randomToken(8)}';
  final authPass = randomToken(24);
  final baseUrl = 'http://$listen';
  final sep = Platform.pathSeparator;
  final binPath = '$repoRoot${sep}bin${sep}manyoyo.js';

  final process = await Process.start(
    nodeBin,
    [binPath, 'serve', listen, '-U', authUser, '-P', authPass],
    workingDirectory: repoRoot,
    includeParentEnvironment: true,
  );

  final logBuffer = StringBuffer();
  void appendLog(String chunk) {
    if (chunk.isEmpty) return;
    if (logBuffer.length > 8000) {
      final trimmed = logBuffer.toString().substring(logBuffer.length - 4000);
      logBuffer.clear();
      logBuffer.write(trimmed);
    }
    logBuffer.write(chunk);
    onLog(chunk);
  }

  process.stdout.transform(utf8.decoder).listen(appendLog);
  process.stderr.transform(utf8.decoder).listen(appendLog);

  try {
    await waitForServerReady(
      process,
      Uri.parse(baseUrl),
      () => logBuffer.toString().trim(),
    );
  } catch (_) {
    process.kill();
    rethrow;
  }

  return DesktopAutoServeResult(
    baseUrl: baseUrl,
    authUser: authUser,
    authPass: authPass,
    process: process,
  );
}
