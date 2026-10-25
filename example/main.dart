// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_crewai/otel_crewai.dart';

/// Traces CrewAI execution calls with OpenTelemetry.
///
/// `otel_crewai` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each CrewAI execution call in
/// [tracedCrewai]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'crewai-example');

  // Wraps a CrewAI execution call in a CLIENT span.
  final crewaiId = await tracedCrewai<String>(
    operation: 'crew.kickoff',
    invoke: () async {
      // Make the CrewAI execution call here, then report what it returned.
      const id = 'crewai_8f3a2c';
      return const CrewaiCallResult(
          value: id,
          result: CrewaiResult(
              crewName: 'example',
              crewId: 'crew_8f3a2c',
              process: 'sequential',
              agentRole: 'example',
              agentId: 'agent_8f3a2c',
              taskId: 'task_8f3a2c',
              taskDescription: 'example',
              toolName: 'example',
              toolStatus: 'success',
              delegated: true,
              delegationTo: 'example',
              iterations: 1,
              maxIterations: 1,
              promptTokens: 128,
              completionTokens: 128,
              totalTokens: 128,
              modelName: 'standard',
              executionMs: 120,
              statusCode: 200));
    },
  );
  OTelLog.info('tracedCrewai crew.kickoff returned $crewaiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCrewaiInstrumentationAsync.
  await runWithoutCrewaiInstrumentationAsync(
    () => tracedCrewai<String>(
      operation: 'crew.kickoff',
      invoke: () async {
        const id = 'crewai_8f3a2c';
        return const CrewaiCallResult(
            value: id,
            result: CrewaiResult(
                crewName: 'example',
                crewId: 'crew_8f3a2c',
                process: 'sequential',
                agentRole: 'example',
                agentId: 'agent_8f3a2c',
                taskId: 'task_8f3a2c',
                taskDescription: 'example',
                toolName: 'example',
                toolStatus: 'success',
                delegated: true,
                delegationTo: 'example',
                iterations: 1,
                maxIterations: 1,
                promptTokens: 128,
                completionTokens: 128,
                totalTokens: 128,
                modelName: 'standard',
                executionMs: 120,
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
