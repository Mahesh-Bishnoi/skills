# Observability Checklist

At-a-glance version of the Verification list in `SKILL.md`, plus the pre-launch instrumentation gate.

## Pre-launch instrumentation gate

- [ ] On-call questions (2–4) written down for this feature
- [ ] Each question maps to at least one signal (log / metric / trace)
- [ ] RED metrics planned for every new endpoint and external dependency
- [ ] Correlation ID + entry-point field planned for every log sink
- [ ] Symptom-based alerts drafted with runbook links

## Verification

- [ ] On-call questions written down, each signal maps to one
- [ ] All log output structured, stable event names, correlation ID on every line
- [ ] Multi-entry-point sinks carry an entry-point field set at run start
- [ ] No secrets, tokens, or unredacted PII in any log line (spot-check actual output)
- [ ] RED metrics exist for every new endpoint and external dependency, bounded labels
- [ ] Latency is a histogram; p95/p99 queryable (never average-only)
- [ ] Single request traceable end-to-end, no broken spans
- [ ] Every new alert symptom-based, runbook-linked, test-fired once
- [ ] Induced staging failure located via telemetry alone
