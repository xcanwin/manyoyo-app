enum MessageRole { user, assistant }

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    List<String>? traces,
  }) : traces = traces ?? [];

  final MessageRole role;
  String content;
  final List<String> traces;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'user';
    return ChatMessage(
      role: roleStr == 'assistant' ? MessageRole.assistant : MessageRole.user,
      content: json['content'] as String? ?? '',
    );
  }
}
