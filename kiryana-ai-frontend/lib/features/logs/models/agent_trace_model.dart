import 'package:flutter/material.dart';

enum AgentStepType {
  input,
  parsed,
  insight,
  action,
}

class AgentTraceStep {
  final int stepNumber;
  final String title;
  final String detail;
  final String status;
  final String timeLabel;
  final AgentStepType type;

  const AgentTraceStep({
    required this.stepNumber,
    required this.title,
    required this.detail,
    required this.status,
    required this.timeLabel,
    required this.type,
  });

  IconData get icon {
    switch (type) {
      case AgentStepType.input:
        return Icons.mic_none_rounded;
      case AgentStepType.parsed:
        return Icons.data_object_rounded;
      case AgentStepType.insight:
        return Icons.lightbulb_outline_rounded;
      case AgentStepType.action:
        return Icons.check_rounded;
    }
  }

  factory AgentTraceStep.fromApi(Map<String, dynamic> data) {
    final label = (data['step_label'] ?? '').toString().toLowerCase();
    AgentStepType type;
    if (label.contains('collection') || label.contains('input')) {
      type = AgentStepType.input;
    } else if (label.contains('pattern') || label.contains('anomaly')) {
      type = AgentStepType.parsed;
    } else if (label.contains('insight')) {
      type = AgentStepType.insight;
    } else {
      type = AgentStepType.action;
    }
    final createdAt = DateTime.tryParse((data['created_at'] ?? '').toString());
    final timeLabel = createdAt == null
        ? '--'
        : '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    return AgentTraceStep(
      stepNumber: (data['step_number'] as num?)?.toInt() ?? 0,
      title: (data['step_label'] ?? 'Step').toString(),
      detail: (data['step_detail'] ?? '').toString(),
      status: (data['status'] ?? 'success').toString(),
      timeLabel: timeLabel,
      type: type,
    );
  }
}

class AgentTraceSession {
  final int insightId;
  final String sessionId;
  final String summary;
  final DateTime? createdAt;

  const AgentTraceSession({
    required this.insightId,
    required this.sessionId,
    required this.summary,
    required this.createdAt,
  });

  String get dateLabel {
    final dt = createdAt;
    if (dt == null) return '--';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  factory AgentTraceSession.fromApi(Map<String, dynamic> data) {
    return AgentTraceSession(
      insightId: (data['insight_id'] as num?)?.toInt() ?? 0,
      sessionId: (data['session_id'] ?? '').toString(),
      summary: (data['summary'] ?? 'AI session').toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }
}
