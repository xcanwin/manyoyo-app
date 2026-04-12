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
    final rawContainers = (json['containers'] as List<dynamic>?) ?? [];
    return SessionsResponse(
      containers: rawContainers
          .map((c) => ContainerGroup.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
