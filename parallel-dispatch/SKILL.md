---
name: parallel-dispatch
description: Fan out two or more independent tasks to background subagents, then collect and synthesize results. Use when parallelizing independent work with self-contained prompts.
---

Run independent tasks concurrently via background subagents. OpenCode has one `subagent` tool: foreground (default) blocks until done; `background=true` returns immediately with a `sessionID` you continue later to collect. There is no messaging, waiting-room, or kill primitive — this skill covers fan-out/fan-in only.

## Dispatch rule

Fan out iff ALL hold; otherwise run sequential foreground calls:

- No task needs another task's output.
- No two tasks edit the same files.
- Failures are actually independent: if fixing one might fix the others, investigate together first instead of dispatching.
- There are at least two tasks (never dispatch for a single task).

## Fan-out

1. Issue one `subagent` call per task with `background=true`, all in the same block (same-block calls run concurrently).
2. Keep prompts self-contained: workers get fresh context and share no history. Never reference "the other task" — inline every file path, constraint, and convention each worker needs. Each prompt needs four parts: scope (one problem domain, e.g. one test file), goal, constraints (e.g. "don't change code outside X"), and output shape (e.g. "return root cause + changes"). Paste the actual error messages — "fix the race condition" without context fails.
3. Pick the narrowest agent: `explore` for read-only research, `general` for multi-step work. Neither can launch further subagents — don't ask them to.
4. Cap at 3–4 workers. If a launch is denied by `subagent` permissions, do that task inline instead.

## Fan-in

1. Wait for the `subagent` tool's completion notification for each worker, then continue it via its `sessionID` to collect results. The tool notifies on completion — do not poll.
2. Synthesize, don't concatenate: dedupe overlapping findings and resolve contradictions explicitly (state which worker won and why).
3. Verify yourself: re-run the full check suite after integrating — workers make systematic errors, so spot-check their changes rather than trusting summaries.
4. Report per-worker outcome: what each did, files changed, checks run.

## Anti-patterns

- Overbroad prompts ("fix all the tests") instead of one scoped domain per worker.
- Dispatching dependent tasks and hoping ordering works out.
- Parallel edits to the same files (ends in conflicts).
- Firing workers then collecting each serially before doing anything else — interleave your own work between fan-out and fan-in.
- Long-lived worker pools or worker-to-worker coordination — unsupported; do the coordination yourself in the parent session.
