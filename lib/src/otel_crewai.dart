// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_crewai_suppression.dart';

const _tracerName = 'dartastic_otel_libs_crewai';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class CrewaiResult {
  const CrewaiResult({
    this.crewName,
    this.crewId,
    this.process,
    this.agentRole,
    this.agentId,
    this.taskId,
    this.taskDescription,
    this.toolName,
    this.toolStatus,
    this.delegated,
    this.delegationTo,
    this.iterations,
    this.maxIterations,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.modelName,
    this.executionMs,
    this.statusCode,
  });

  /// User-defined crew name.
  final String? crewName;

  /// Generated crew id.
  final String? crewId;

  /// `sequential` / `hierarchical` / `consensual` — execution model.
  final String? process;

  /// Agent role string (acts as the agent's identity).
  final String? agentRole;

  final String? agentId;

  final String? taskId;

  /// Task description (short — long descriptions are normalized to
  /// avoid bloating spans).
  final String? taskDescription;

  /// Tool name when this span wraps a tool call.
  final String? toolName;

  /// `success` / `error` / `timeout` / `not_found` / `rate_limited`
  /// — tool execution outcome.
  final String? toolStatus;

  /// `true` when the task was delegated to another agent (hierarchical
  /// process).
  final bool? delegated;

  /// Agent role the work was delegated to.
  final String? delegationTo;

  /// Number of think/act iterations executed.
  final int? iterations;

  /// Configured limit (helpful for runaway-loop diagnosis).
  final int? maxIterations;

  /// Token usage aggregated across the crew/task/agent run.
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  /// Underlying model used.
  final String? modelName;

  final int? executionMs;

  final int? statusCode;
}

class CrewaiCallResult<T> {
  const CrewaiCallResult({required this.value, this.result});
  final T value;
  final CrewaiResult? result;
}

/// Wraps a CrewAI execution call in a CLIENT span. [operation] is one
/// of `crew.kickoff`, `crew.kickoff_async`, `crew.kickoff_for_each`,
/// `crew.replay`, `agent.execute_task`, `task.execute`, `tool.use`,
/// `task.delegate`, `flow.kickoff`.
Future<T> tracedCrewai<T>({
  required String operation,
  required Future<CrewaiCallResult<T>> Function() invoke,
}) async {
  if (crewaiInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'crewai',
    'rpc.method': operation,
    'crewai.operation': operation,
  };

  final span = _tracer().startSpan(
    'crewai $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.crewName != null) {
        extras.add(OTel.attributeString(
          'crewai.crew.name',
          r.result!.crewName!,
        ));
      }
      if (r.result!.crewId != null) {
        extras.add(OTel.attributeString(
          'crewai.crew.id',
          r.result!.crewId!,
        ));
      }
      if (r.result!.process != null) {
        extras.add(OTel.attributeString(
          'crewai.process',
          r.result!.process!,
        ));
      }
      if (r.result!.agentRole != null) {
        extras.add(OTel.attributeString(
          'crewai.agent.role',
          r.result!.agentRole!,
        ));
      }
      if (r.result!.agentId != null) {
        extras.add(OTel.attributeString(
          'crewai.agent.id',
          r.result!.agentId!,
        ));
      }
      if (r.result!.taskId != null) {
        extras.add(OTel.attributeString(
          'crewai.task.id',
          r.result!.taskId!,
        ));
      }
      if (r.result!.taskDescription != null) {
        extras.add(OTel.attributeString(
          'crewai.task.description',
          r.result!.taskDescription!,
        ));
      }
      if (r.result!.toolName != null) {
        extras.add(OTel.attributeString(
          'crewai.tool.name',
          r.result!.toolName!,
        ));
      }
      if (r.result!.toolStatus != null) {
        extras.add(OTel.attributeString(
          'crewai.tool.status',
          r.result!.toolStatus!,
        ));
        if (r.result!.toolStatus == 'error' ||
            r.result!.toolStatus == 'timeout') {
          span.setStatus(
            SpanStatusCode.Error,
            'CrewAI tool ${r.result!.toolStatus}',
          );
        }
      }
      if (r.result!.delegated != null) {
        extras.add(OTel.attributeBool(
          'crewai.task.delegated',
          r.result!.delegated!,
        ));
      }
      if (r.result!.delegationTo != null) {
        extras.add(OTel.attributeString(
          'crewai.delegation.to',
          r.result!.delegationTo!,
        ));
      }
      if (r.result!.iterations != null) {
        extras.add(OTel.attributeInt(
          'crewai.iterations',
          r.result!.iterations!,
        ));
      }
      if (r.result!.maxIterations != null) {
        extras.add(OTel.attributeInt(
          'crewai.max_iterations',
          r.result!.maxIterations!,
        ));
        if (r.result!.iterations != null &&
            r.result!.iterations! >= r.result!.maxIterations!) {
          span.setStatus(
            SpanStatusCode.Error,
            'CrewAI hit max_iterations',
          );
        }
      }
      if (r.result!.promptTokens != null) {
        extras.add(OTel.attributeInt(
          'crewai.tokens.prompt',
          r.result!.promptTokens!,
        ));
      }
      if (r.result!.completionTokens != null) {
        extras.add(OTel.attributeInt(
          'crewai.tokens.completion',
          r.result!.completionTokens!,
        ));
      }
      if (r.result!.totalTokens != null) {
        extras.add(OTel.attributeInt(
          'crewai.tokens.total',
          r.result!.totalTokens!,
        ));
      }
      if (r.result!.modelName != null) {
        extras.add(OTel.attributeString(
          'crewai.model.name',
          r.result!.modelName!,
        ));
      }
      if (r.result!.executionMs != null) {
        extras.add(OTel.attributeInt(
          'crewai.execution_ms',
          r.result!.executionMs!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'CrewAI HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
