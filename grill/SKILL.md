---
name: grill
description: One-question-at-a-time interview that extracts what the user actually wants and sharpens plans or designs. Use only when the user explicitly says "grill me", "interview me", "stress-test my thinking", or "are we sure?". User-invoked only.
metadata:
  opencode/autoinvoke: false
---

# Grill

What people ask for and what they actually want are different things. They ask for "a dashboard" because that's the convention, not because it solves their problem. They present a plan they've already rationalized into "good enough." The cheapest moment to find the gap is before any spec or code exists — once building starts, switching costs lock the misfit in.

This skill has two phases. **Phase A** extracts real intent from a vague ask. **Phase B** stress-tests an existing plan or design. Run the phase that fits; run both when a vague ask already grew a plan.

Project `AGENTS.md` and existing codebase conventions override this skill.

## When to use

- The ask is missing at least one of: **who** benefits, **why** now, what **success** looks like, the binding **constraint**
- The request is conventional ("build me X", "make it faster") and you can't unpack the convention without guessing
- A plan or design exists and hasn't survived hostile questions yet
- You're tempted to start with assumptions you haven't surfaced
- The user explicitly invokes: "grill me", "interview me", "before we start, are we sure?", "stress-test my thinking"

**When NOT to use:**

- The ask is unambiguous and self-contained ("rename this variable", "fix this typo")
- The user asked for speed over verification
- Pure information requests or mechanical operations (renames, formats, moves)
- Non-interactive contexts (CI pipelines, scheduled runs, autonomous loops) — this skill needs a live user. Flag underspecification as a blocker instead of guessing.

## Phase A — Extract intent

### A1. Hypothesize, with a confidence number

Before asking anything, state your best read in **one sentence** plus an honest confidence number:

```
HYPOTHESIS: You want a way to answer "how are we doing?" in standup, and "dashboard" was the convention that came to mind.
CONFIDENCE: ~30% — missing: who it's for, what "metrics" means, what success looks like
```

Below ~70%, the reason on the same line is mandatory — it tells the user what the interview must surface. If you can't predict the user's reactions to the next three questions you'd ask, the number is too high.

### A2. One question at a time, each with a guess

```
Q: <one focused question>
GUESS: <your hypothesis for the answer, with the reasoning that produced it>
```

Wait for the reaction before the next question. Batches encourage skim-reading, lock in wrong framing (question 3 often depends on answer 1), and burn finite thinking energy. Attaching a guess commits you to something visibly wrong — reacting is faster than generating from scratch and it surfaces *your* assumptions. Mitigate agreeableness by being visibly willing to be wrong; occasionally guess where you expect pushback.

### A3. Listen for "want vs. should want"

Danger signals: best-practice talk without specifics ("scalable", "clean architecture"), deference to convention ("the standard approach"), "I should probably…", buzzwords as goals ("modern", "robust"). When you hear them, ask:

> *"If you didn't have to justify this to anyone, what would you actually want?"*

That question often does more work than the previous five.

### A4. Restate, then require an explicit yes

Keep it tight (5–8 lines), in the user's language, confirmable line by line:

```
Here's what I now think you want:

- Outcome:      <one line>
- User:         <one line — who benefits>
- Why now:      <one line — what changed>
- Success:      <one line — how we know it worked>
- Constraint:   <one line — the binding limit>
- Out of scope: <one line — what we're explicitly NOT doing>

Yes / no / refine?
```

"Out of scope" is non-negotiable — half of misalignment is silent disagreement about non-goals. The gate is an explicit "yes." These are **not** yes: "whatever you think is best" (delegation — re-ask with two concrete options), "sounds good" (ambiguous — ask "anything you'd refine?"), "sure, let's go" (often a polite exit). On correction, fold it in and restate.

### The 95% stop test

Done when you can answer yes to: *can I predict the user's reaction to the next three questions I would ask?* If yes, restate. If several rounds pass with confidence flat, stop and say so — that's information about the ask, not a reason to grind.

## Phase B — Grill the plan or design

Same mechanics as Phase A, aimed at the artifact instead of the ask. One load-bearing assumption per question, each with your guess attached. Work through:

1. **Goal fit** — does this artifact serve the Phase A intent? Which line of the restate does each major piece trace to? Pieces with no trace are scope suspects.
2. **Trade-offs** — every design buys something by selling something. Name both sides aloud; "no trade-off" means one hasn't been found yet.
3. **Failure modes** — what breaks first under load, bad input, or partial outage? Which failure is silent?
4. **Scope pressure** — what gets cut if this must ship in half the time? If nothing can be cut, the plan is too big, not too tight.
5. **Reversibility** — which decisions are one-way doors? Those are ADR candidates (see Docs).

Record contested decisions and new domain terms as you go — they become ADR/glossary drafts, written only on confirmation.

## Docs — offer, write on yes only

On confirmation, offer any that apply; write only on explicit yes:

- **Intent** → `docs/intent/[topic].md` (the Phase A restate)
- **ADRs** → one per one-way-door decision from Phase B (decision, context, options considered, consequence)
- **Glossary** → domain terms surfaced during the interview, in the user's words

Match the project's existing ADR/glossary locations and formats first per the `adr-skill` convention rule; use the paths above only when no convention exists.

## Terminal turn (critical)

On explicit confirmation: deliver the confirmed statement, offer the docs, then **stop the turn immediately**. No tool calls, no downstream work, no spec or plan drafting in this turn. Hand control back.

## Red flags

- Three or more questions in one message (batching, not interviewing)
- A question without your guess (surveying, not committing)
- Accepting "whatever you think" as confirmation
- Spec, plan, or code before explicit restate confirmation
- Tools or downstream work on the confirmation turn
- Sophistication-signaling answer accepted without the A3 probe
- Confidence below ~70% with no reason attached
- Missing "Out of scope" line in the restate
- Docs written before the user confirmed

## Verification

- [ ] Hypothesis + confidence stated in the first turn; sub-70% numbers carry reasons
- [ ] Questions asked one at a time, each with a guess
- [ ] A3 probe ran on at least one convention-signaling answer
- [ ] Restate covers Outcome / User / Why now / Success / Constraint / Out of scope
- [ ] Explicit yes obtained; Phase B run when an artifact exists
- [ ] Confirmation turn stopped with no tool calls; docs only on yes
