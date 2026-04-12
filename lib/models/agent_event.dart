sealed class AgentEvent {
  const AgentEvent();

  factory AgentEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'meta' => MetaEvent.fromJson(json),
      'trace' => TraceEvent.fromJson(json),
      'content_delta' => ContentDeltaEvent.fromJson(json),
      'result' => ResultEvent.fromJson(json),
      'error' => ErrorEvent.fromJson(json),
      _ => throw ArgumentError('Unknown AgentEvent type: $type'),
    };
  }
}

class MetaEvent extends AgentEvent {
  const MetaEvent({
    required this.containerName,
    required this.sessionName,
    required this.agentProgram,
    required this.resumeAttempted,
    required this.resumeSucceeded,
    this.contextMode,
  });

  final String containerName;
  final String sessionName;
  final String agentProgram;
  final bool resumeAttempted;
  final bool resumeSucceeded;
  final String? contextMode;

  factory MetaEvent.fromJson(Map<String, dynamic> json) => MetaEvent(
    containerName: json['containerName'] as String? ?? '',
    sessionName: json['sessionName'] as String? ?? '',
    agentProgram: json['agentProgram'] as String? ?? '',
    resumeAttempted: (json['resumeAttempted'] as bool?) ?? false,
    resumeSucceeded: (json['resumeSucceeded'] as bool?) ?? false,
    contextMode: json['contextMode'] as String?,
  );
}

class TraceEvent extends AgentEvent {
  const TraceEvent({required this.text, this.traceEvent});

  final String text;
  final Map<String, dynamic>? traceEvent;

  factory TraceEvent.fromJson(Map<String, dynamic> json) => TraceEvent(
    text: json['text'] as String? ?? '',
    traceEvent: json['traceEvent'] as Map<String, dynamic>?,
  );
}

class ContentDeltaEvent extends AgentEvent {
  const ContentDeltaEvent({required this.content});

  final String content;

  factory ContentDeltaEvent.fromJson(Map<String, dynamic> json) =>
      ContentDeltaEvent(content: json['content'] as String? ?? '');
}

class ResultEvent extends AgentEvent {
  const ResultEvent({
    required this.exitCode,
    required this.output,
    required this.resumeAttempted,
    required this.resumeSucceeded,
    required this.interrupted,
    this.contextMode,
  });

  final int exitCode;
  final String output;
  final bool resumeAttempted;
  final bool resumeSucceeded;
  final bool interrupted;
  final String? contextMode;

  factory ResultEvent.fromJson(Map<String, dynamic> json) => ResultEvent(
    exitCode: (json['exitCode'] as int?) ?? 0,
    output: json['output'] as String? ?? '',
    resumeAttempted: (json['resumeAttempted'] as bool?) ?? false,
    resumeSucceeded: (json['resumeSucceeded'] as bool?) ?? false,
    interrupted: (json['interrupted'] as bool?) ?? false,
    contextMode: json['contextMode'] as String?,
  );
}

class ErrorEvent extends AgentEvent {
  const ErrorEvent({required this.error});

  final String error;

  factory ErrorEvent.fromJson(Map<String, dynamic> json) =>
      ErrorEvent(error: json['error'] as String? ?? '');
}
