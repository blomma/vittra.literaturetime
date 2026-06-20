---
name: git-commit
description: generate a git commit message for staged changes
---

## Usage Restrictions (IMPORTANT)

Scope: restricted to generating commit messages for staged changes only. Do not run any other git operations beyond the optional `git commit` step described below.

- DO NOT auto-trigger this skill based on conversation context.
- ONLY invoke if the user explicitly uses the command "/git-commit".
- If the task seems relevant but the command is not used, simply inform the user the tool is available.

Review every file currently in the git staging area (the full output of `git diff --cached`) and generate a single git commit message that summarizes all of those staged changes, regardless of the variety of changes, following the Conventional Commits format.

**Format:**

```
<type>(<scope>): <short summary>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`

**Rules (apply in order, one step at a time):**

1. **Type**: pick one value from the type list above based on the primary change.
2. **Scope** (optional): a single lowercase noun for the affected module or area. Example: `auth`, `parser`.
3. **Summary line**: write in imperative mood, all lowercase, no trailing period, 72 characters or fewer. Example: `add retry logic to upload client`.
4. **Body**: Explain _why_ the change was made, not _what_ changed, using ONLY factual, verifiable information from the diff, wrap lines at 72 characters.
5. **Footer** (optional): reference issue numbers, e.g. `Closes #42`, or note a breaking change, e.g. `BREAKING CHANGE: drops support for Node 16`.

**Example:**

```
fix(parser): handle trailing commas in array literals

The previous tokenizer treated trailing commas as syntax errors, which
broke compatibility with JSON5 inputs accepted elsewhere in the pipeline.

Closes #128
```

Show the generated commit message to the user, then ask: **"Would you like to commit the staged changes with this message? (yes/no)"**

- If **yes**: run `git commit -m "<message>"` using the terminal. Confirm success or report any error.
- If **no**: stop and let the user know they can adjust the message manually.
