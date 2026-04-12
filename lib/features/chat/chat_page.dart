import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manyoyo_app/core/api_client.dart';
import 'package:manyoyo_app/features/chat/chat_notifier.dart';
import 'package:manyoyo_app/models/agent_event.dart';
import 'package:manyoyo_app/models/message.dart';

// ── palette (dark terminal green) ───────────────────────────────────────────
const _kBg = Color(0xFF0F1A14);
const _kSurface = Color(0xFF172217);
const _kBorder = Color(0xFF2B4035);
const _kAccent = Color(0xFF3DDB87);
const _kAccentDim = Color(0xFF0B6E4F);
const _kTextHigh = Color(0xFFE8F5EE);
const _kTextMid = Color(0xFF7FA88E);
const _kTextLow = Color(0xFF3D5446);
const _kUserBubble = Color(0xFF1C3228);

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.sessionRef});

  final String sessionRef;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatNotifier _notifier;
  late final ApiClient _client;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  CancelToken? _cancelToken;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _client = context.read<ApiClient>();
    _notifier = ChatNotifier();
    _loadHistory();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>(
        '/api/sessions/${Uri.encodeComponent(widget.sessionRef)}/messages',
      );
      final raw = resp.data;
      if (raw != null && raw['messages'] is List) {
        _notifier.loadHistory(raw['messages'] as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingHistory = false);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final prompt = _inputController.text.trim();
    if (prompt.isEmpty || _notifier.isStreaming) return;

    _inputController.clear();
    _notifier.addUserMessage(prompt);
    _scrollToBottom();

    _cancelToken = CancelToken();
    try {
      final resp = await _client.post<ResponseBody>(
        '/api/sessions/${Uri.encodeComponent(widget.sessionRef)}/agent/stream',
        data: {'prompt': prompt},
        options: Options(
          responseType: ResponseType.stream,
          cancelToken: _cancelToken,
        ),
      );

      final eventStream = _parseNdjsonStream(resp.data!.stream);
      await _notifier.processStream(eventStream);
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        _notifier.clearError();
      }
    } finally {
      _cancelToken = null;
      _scrollToBottom();
    }
  }

  Stream<AgentEvent> _parseNdjsonStream(
    Stream<List<int>> byteStream,
  ) async* {
    final lines = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        yield AgentEvent.fromJson(json);
      } catch (_) {}
    }
  }

  void _stopAgent() {
    _cancelToken?.cancel();
    _client.post<dynamic>(
      '/api/sessions/${Uri.encodeComponent(widget.sessionRef)}/agent/stop',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatNotifier>.value(
      value: _notifier,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Column(
          children: [
            _TopBar(
              sessionRef: widget.sessionRef,
              onStop: _notifier.isStreaming ? _stopAgent : null,
            ),
            Expanded(
              child: _loadingHistory
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kAccent,
                        ),
                      ),
                    )
                  : _MessageList(scrollController: _scrollController),
            ),
            _ComposerBar(
              controller: _inputController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.sessionRef, this.onStop});

  final String sessionRef;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 8,
        right: 12,
        bottom: 10,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: _kTextMid),
            onPressed: () => context.go('/sessions'),
            tooltip: '返回',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              sessionRef,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _kTextHigh,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Consumer<ChatNotifier>(
            builder: (_, notifier, __) => notifier.isStreaming
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: _kAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: onStop,
                        child: const Text(
                          'stop',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFFE06C5B),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatNotifier>(
      builder: (context, notifier, _) {
        if (notifier.messages.isEmpty) {
          return const _EmptyChat();
        }
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: notifier.messages.length,
          itemBuilder: (context, i) =>
              _MessageBubble(message: notifier.messages[i]),
        );
      },
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showTraces = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Row(
              children: [
                Icon(Icons.smart_toy_rounded, size: 12, color: _kAccentDim),
                SizedBox(width: 5),
                Text(
                  'agent',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _kTextLow,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            ),
            decoration: BoxDecoration(
              color: isUser ? _kUserBubble : _kSurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 2),
                bottomRight: Radius.circular(isUser ? 2 : 12),
              ),
              border: isUser
                  ? null
                  : Border.all(color: _kBorder, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: isUser
                ? Text(
                    widget.message.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kTextHigh,
                      height: 1.5,
                    ),
                  )
                : MarkdownBody(
                    data: widget.message.content.isEmpty
                        ? '▋'
                        : widget.message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        color: _kTextHigh,
                        height: 1.6,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: _kAccent,
                        backgroundColor: Color(0xFF0F1A14),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFF0F1A14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kBorder),
                      ),
                      h1: const TextStyle(color: _kTextHigh, fontSize: 18),
                      h2: const TextStyle(color: _kTextHigh, fontSize: 16),
                      h3: const TextStyle(color: _kTextHigh, fontSize: 15),
                      blockquoteDecoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: _kAccentDim, width: 3),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.only(left: 10),
                    ),
                  ),
          ),
          // Trace panel (collapsible)
          if (!isUser && widget.message.traces.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _showTraces = !_showTraces),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTraces
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 14,
                      color: _kTextLow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.message.traces.length} trace${widget.message.traces.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: _kTextLow,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showTraces)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1A14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.message.traces
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: _kTextMid,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatNotifier>(
      builder: (context, notifier, _) {
        return Container(
          decoration: const BoxDecoration(
            color: _kSurface,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.paddingOf(context).bottom + 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !notifier.isStreaming,
                  maxLines: 5,
                  minLines: 1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: _kTextHigh,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    hintStyle: const TextStyle(
                      color: _kTextLow,
                      fontFamily: 'monospace',
                    ),
                    filled: true,
                    fillColor: _kBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _kAccentDim, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: notifier.isStreaming ? null : onSend,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notifier.isStreaming ? _kTextLow : _kAccentDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Color(0xFFE8F5EE),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_rounded, size: 36, color: _kTextLow),
          SizedBox(height: 12),
          Text(
            'send a message to start',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: _kTextLow,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
