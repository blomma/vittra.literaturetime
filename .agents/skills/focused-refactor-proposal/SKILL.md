---
name: focused-refactor-proposal
description: Inspect one specified file for a small responsibility-focused refactor, then show only before/after code without editing files. Use when the user asks to reason about a file and find one place to fold, gather, relocate, streamline, or better document logic.
---

# Focused Refactor Proposal

Use this skill when the user wants a reusable "inspect this file and propose one targeted refactor" workflow, especially when they explicitly do not want files edited.

## Inputs

- Required: a file path or clear target file.
- Optional: a specific theme, such as KCC logic, state handling, duplicate code, documentation, naming, or responsibility boundaries.

If the target file is missing or ambiguous, ask a single question to clarify, such as: 'What is the exact file path?' or 'Can you describe the file's role in more detail?'

## Workflow

1. Read the target file and enough local context to understand nearby conventions.
2. Find exactly one focused refactor opportunity where related logic can be folded, gathered, relocated, or documented better.
3. When choosing a change, rank priorities in this order: (1) preserve behavior, (2) improve clarity, (3) strengthen locality and invariants, (4) align with existing patterns and responsibility boundaries. Resolve conflicts by favoring the higher-ranked priority — for example, if improving clarity would alter behavior, preserve behavior instead.
4. Keep the proposal inside the same file unless the user explicitly asks to split files.
5. Do not edit files. Show the code the user should change.

## Selection Criteria

Prefer a target that has at least one of:

- Repeated code paths that should share a helper, if the change is only one line of code moved into a helper function then it would have to be very critical to warrant that.
- A domain invariant currently spread across multiple branches.
- Logic living in a caller when an existing helper or nearby concept should own it.
- A comment/doc gap around behavior that is easy to misuse.
- A small naming or structure mismatch with the file's existing patterns.

Avoid speculative abstractions, behavior changes, or changes that disturb ordering-sensitive pipelines.

## Output Format

Use this structure:

````text
One focused cleanup: <short target summary>.

Change this:

```rust
<current code>
```

to:

```rust
<replacement code>
```

Add this helper/comment near <location>:

```rust
<new helper or documentation>
```

<short practical rationale>
````

If there are multiple replacement blocks, show each current block followed by its replacement. Keep the rationale short and practical.

## Constraints

- Do not modify files.
- Do not propose more than one refactor.
- Preserve behavior unless the user explicitly asks for behavior changes.
- Preserve existing architecture and system ordering.
- Use existing naming, style, and helper patterns from the file.
- For Rust code, prefer compile-plausible snippets with imports and lifetimes accounted for.
