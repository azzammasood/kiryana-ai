import 'package:flutter/material.dart';

enum AiLogStepType {
  input,
  parsed,
  insight,
  action,
}

class AiLogStep {
  final AiLogStepType type;
  final String title;
  final String time;
  final IconData icon;

  const AiLogStep({
    required this.type,
    required this.title,
    required this.time,
    required this.icon,
  });
}

class AiLogSession {
  final String traceId;
  final String date;
  final String summary;
  final List<AiLogStep> steps;

  const AiLogSession({
    required this.traceId,
    required this.date,
    required this.summary,
    required this.steps,
  });
}

class MockAiLogsData {
  static const List<AiLogSession> sessions = [
    AiLogSession(
      traceId: 'TRC-8924-A',
      date: 'Today, 10:30 AM',
      summary: 'Sold 500 Rs Atta',
      steps: [
        AiLogStep(
          type: AiLogStepType.input,
          title: 'Input Received',
          time: '10:30 AM',
          icon: Icons.mic_none_rounded,
        ),
        AiLogStep(
          type: AiLogStepType.parsed,
          title: 'Parsed Intent',
          time: '10:30:01 AM',
          icon: Icons.data_object_rounded,
        ),
        AiLogStep(
          type: AiLogStepType.insight,
          title: 'Insight Generation',
          time: '10:30:05 AM',
          icon: Icons.lightbulb_outline_rounded,
        ),
        AiLogStep(
          type: AiLogStepType.action,
          title: 'Action Executed',
          time: '10:30:06 AM',
          icon: Icons.check_rounded,
        ),
      ],
    ),
    AiLogSession(
      traceId: 'TRC-7711-X',
      date: 'Today, 09:15 AM',
      summary: 'Electricity Bill Rs 4000',
      steps: [
        AiLogStep(
          type: AiLogStepType.input,
          title: 'Input Received',
          time: '09:15 AM',
          icon: Icons.mic_none_rounded,
        ),
        AiLogStep(
          type: AiLogStepType.parsed,
          title: 'Parsed Intent',
          time: '09:15:02 AM',
          icon: Icons.data_object_rounded,
        ),
        AiLogStep(
          type: AiLogStepType.action,
          title: 'Action Executed',
          time: '09:15:04 AM',
          icon: Icons.check_rounded,
        ),
      ],
    ),
  ];
}
