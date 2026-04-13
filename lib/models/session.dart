class AgentSession {
  const AgentSession({
    required this.sessionRef,
    required this.sessionName,
    required this.containerName,
    required this.agentId,
    required this.isHistoryOnly,
    required this.running,
    this.yolo,
    this.contextMode,
  });

  final String sessionRef;
  final String sessionName;
  final String containerName;
  final String agentId;
  final bool isHistoryOnly;
  final bool running;
  final String? yolo;
  final String? contextMode;

  factory AgentSession.fromJson(Map<String, dynamic> json) {
    return AgentSession(
      sessionRef: json['sessionRef'] as String,
      sessionName: json['sessionName'] as String,
      containerName: json['containerName'] as String,
      agentId: json['agentId'] as String,
      isHistoryOnly: (json['isHistoryOnly'] as bool?) ?? false,
      running: (json['running'] as bool?) ?? false,
      yolo: json['yolo'] as String?,
      contextMode: json['contextMode'] as String?,
    );
  }

  factory AgentSession.fromSummaryJson(Map<String, dynamic> json) {
    final sessionRef = (json['name'] as String?) ?? '';
    final containerName = (json['containerName'] as String?) ?? '';
    final agentId = (json['agentId'] as String?) ?? 'default';
    final status = (json['status'] as String?) ?? 'history';

    return AgentSession(
      sessionRef: sessionRef,
      sessionName: sessionRef,
      containerName: containerName,
      agentId: agentId,
      isHistoryOnly: status == 'history',
      running: status == 'running',
      yolo: json['agentProgram'] as String?,
      contextMode: null,
    );
  }
}

class ContainerGroup {
  const ContainerGroup({
    required this.containerName,
    required this.agents,
  });

  final String containerName;
  final List<AgentSession> agents;

  factory ContainerGroup.fromJson(Map<String, dynamic> json) {
    final rawAgents = (json['agents'] as List<dynamic>?) ?? [];
    return ContainerGroup(
      containerName: json['containerName'] as String,
      agents: rawAgents
          .map((a) => AgentSession.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SessionsResponse {
  const SessionsResponse({required this.containers});

  final List<ContainerGroup> containers;

  factory SessionsResponse.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List<dynamic>?) ?? [];
    if (rawSessions.isNotEmpty) {
      final grouped = <String, List<AgentSession>>{};

      for (final item in rawSessions) {
        if (item is! Map<String, dynamic>) continue;
        final session = AgentSession.fromSummaryJson(item);
        grouped.putIfAbsent(session.containerName, () => []).add(session);
      }

      final containers = grouped.entries
          .map(
            (entry) => ContainerGroup(
              containerName: entry.key,
              agents: entry.value,
            ),
          )
          .toList();

      return SessionsResponse(containers: containers);
    }

    final rawContainers = (json['containers'] as List<dynamic>?) ?? [];
    return SessionsResponse(
      containers: rawContainers
          .map((c) => ContainerGroup.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
