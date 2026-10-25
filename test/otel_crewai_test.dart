// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_crewai/otel_crewai.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_crewai-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('crew.kickoff records process + agent + tokens', () async {
    await tracedCrewai<String>(
      operation: 'crew.kickoff',
      invoke: () async => const CrewaiCallResult(
        value: 'ok',
        result: CrewaiResult(
          crewName: 'research_crew',
          process: 'hierarchical',
          agentRole: 'Senior Researcher',
          taskId: 't_1',
          taskDescription: 'Summarize Q4 industry trends',
          modelName: 'gpt-4o',
          iterations: 6,
          maxIterations: 25,
          promptTokens: 12500,
          completionTokens: 3200,
          totalTokens: 15700,
          executionMs: 18000,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('crewai crew.kickoff')!);
    expect(a['crewai.process'], 'hierarchical');
    expect(a['crewai.agent.role'], 'Senior Researcher');
    expect(a['crewai.iterations'], 6);
    expect(a['crewai.tokens.total'], 15700);
  });

  test('tool error sets span error', () async {
    await tracedCrewai<String>(
      operation: 'tool.use',
      invoke: () async => const CrewaiCallResult(
        value: 'ok',
        result: CrewaiResult(
          agentRole: 'Researcher',
          toolName: 'web_search',
          toolStatus: 'error',
        ),
      ),
    );
    expect(
      spans.findSpanByName('crewai tool.use')!.status,
      SpanStatusCode.Error,
    );
  });

  test('hit max_iterations sets span error', () async {
    await tracedCrewai<String>(
      operation: 'agent.execute_task',
      invoke: () async => const CrewaiCallResult(
        value: 'ok',
        result: CrewaiResult(
          iterations: 25,
          maxIterations: 25,
        ),
      ),
    );
    expect(
      spans.findSpanByName('crewai agent.execute_task')!.status,
      SpanStatusCode.Error,
    );
  });

  test('task.delegate records delegation chain', () async {
    await tracedCrewai<String>(
      operation: 'task.delegate',
      invoke: () async => const CrewaiCallResult(
        value: 'ok',
        result: CrewaiResult(
          agentRole: 'Manager',
          delegated: true,
          delegationTo: 'Senior Researcher',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('crewai task.delegate')!);
    expect(a['crewai.task.delegated'], true);
    expect(a['crewai.delegation.to'], 'Senior Researcher');
  });

  test('suppression skips spans', () async {
    await runWithoutCrewaiInstrumentationAsync(() async {
      await tracedCrewai<String>(
        operation: 'crew.kickoff',
        invoke: () async => const CrewaiCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('crewai '), isEmpty);
  });
}
