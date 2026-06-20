---
name: plan-feature
description: Break a feature into independent steps that can each be completed in a separate conversation without prior chat context. Use when designing a multi-step implementation plan for a meaty feature.
---

# Plan Feature

Create an implementation plan for the requested feature, broken into steps where **each step can be executed in a fresh conversation** given only the codebase and a one-paragraph task description.

## Inputs

- Required: a feature description (what to build, desired behavior, constraints).
- Optional: max files per step, whether to flag parallelizable steps.

If the feature is ambiguous, ask one clarifying question before planning.

## Step Requirements

Every step in the plan MUST satisfy all of these:

1. **Self-contained** — completable given only the codebase and a one-paragraph description of what to do. If it can't be described in one paragraph, split further.
2. **Compiles and tests pass** — no step leaves the codebase in a broken state. Each step is a valid stopping point.
3. **Names exact files** — list the files to create or modify and the contract (types, inputs, outputs, public API) the step must satisfy.
4. **Externalizes decisions** — any design choices or rationale that a future conversation would need to know are noted as "record in code comment" or "add to AGENTS.md" within that step's description.

## Output Format

```
## Feature: <name>

### Overview
<1-2 sentence summary of the full feature>

### Step 1: <title>
**Files:** <list of files to touch>
**Do:** <one paragraph — what to implement>
**Contract:** <types/signatures/invariants this step establishes>
**Decisions to record:** <any rationale to persist in code or docs>
**Depends on:** none | Step N

### Step 2: <title>
...
```

## Persist the Plan

After generating the plan, save it to a file in the project root:

- **Path:** `PLAN-<feature-slug>.md` (e.g. `PLAN-weather-system.md`). Use lowercase kebab-case for the slug derived from the feature name.
- **Content:** the full plan output (Overview + all Steps) exactly as shown in the Output Format above.
- Confirm the file was written and tell the user the path so they can reference it in future conversations.

## Guidelines

- Prefer steps that touch ≤ 3 files.
- Flag which steps have ordering dependencies vs. which can be done in parallel.
- Place data types / shared contracts early in the plan so later steps can reference them from the codebase rather than from conversation memory.
- If a step requires a non-obvious design decision, make that decision in the plan and mark it for recording — don't defer it to the implementing conversation.
- Follow all conventions in AGENTS.md (naming, tier boundaries, collider placement, etc.).
