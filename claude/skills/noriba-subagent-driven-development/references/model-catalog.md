# Model Catalog & CLI Reference (Late 2026 Baseline)

This catalog specifies recommended model identifiers, reasoning effort flags, and data privacy boundaries for each supported AI CLI engine.

---

## 1. Data Privacy & Compliance Boundaries

Before selecting a CLI engine, determine the data confidentiality requirements:

### Work / Confidential Projects (`privacy_mode: work`)
- **Prohibited**: Antigravity CLI (`agy`) under consumer subscription tiers (such as "Google AI Pro"), where transmitted prompt and code data are used for model training.
- **Allowed**:
  - **Claude Code (`claude`)**: Anthropic commercial API tier (Zero-Data-Retention / no model training on customer prompts).
  - **OpenAI Codex CLI (`codex`)**: API commercial tier (no model training on customer inputs).
  - Enterprise-managed instances with explicit data training opt-outs.

### Non-Work / Personal / Open Source Projects (`privacy_mode: non-work`)
- **Allowed**: All CLI engines including `agy` (`gemini-3.8-flash-low`, `gemini-4-argon-high`).
- Highly recommended to use `agy` with Gemini 3.8 Flash for maximum execution speed and cost efficiency.

---

## 2. Supported CLI Engines & Invariant Flags

> [!IMPORTANT]
> **Mandatory Model Flag Rule**: Subagents must NEVER be spawned without an explicit `--model <MODEL>` flag. Omitting the model flag falls back to the host machine's default model (often the most expensive model, e.g. Opus 5.5), violating cost control invariants.

### Claude Code (`claude`)
- **Worker (Fast / Cheap)**: `--model haiku` (`claude-haiku-5-5`) with `--effort low`
- **Worker (Standard / Balanced)**: `--model sonnet` (`claude-sonnet-5-5`) with `--effort low`
- **Reviewer / Lead (Capable)**: `--model opus` (`claude-opus-5-5`) with `--effort high`
- **Permissions Bypass**: `--dangerously-skip-permissions`
- **Full Invocations**:
  - Worker: `claude --model sonnet --effort low --dangerously-skip-permissions`
  - Reviewer: `claude --model opus --effort high --dangerously-skip-permissions`

### Antigravity CLI (`agy`) *(Non-Work Only)*
- **Worker (Fast / Cheap)**: `--model gemini-3.8-flash-low` with `--effort low`
- **Worker (Standard / Balanced)**: `--model gemini-3.8-flash-medium` with `--effort low`
- **Reviewer / Lead (Capable)**: `--model gemini-4-argon-high` with `--effort high`
- **Permissions Bypass**: `--dangerously-skip-permissions`
- **Full Invocations**:
  - Worker: `agy --model gemini-3.8-flash-low --effort low --dangerously-skip-permissions`
  - Reviewer: `agy --model gemini-4-argon-high --effort high --dangerously-skip-permissions`

### OpenAI Codex CLI (`codex`)
- **Worker (Fast / Cheap)**: `-m gpt-6-luna` with `-c reasoning_effort="low"`
- **Worker (Standard / Balanced)**: `-m gpt-6-sol` with `-c reasoning_effort="low"`
- **Reviewer / Lead (Capable)**: `-m gpt-6-astra` with `-c reasoning_effort="high"`
- **Permissions Bypass**: `--dangerously-bypass-approvals-and-sandbox`
- **Full Invocations**:
  - Worker: `codex -m gpt-6-sol -c reasoning_effort="low" --dangerously-bypass-approvals-and-sandbox`
  - Reviewer: `codex -m gpt-6-astra -c reasoning_effort="high" --dangerously-bypass-approvals-and-sandbox`

> [!IMPORTANT]
> **Pure Messaging Invariant**: Subagents are NEVER given prompt strings or initial instruction flags as CLI arguments (such as positional `<prompt>` or `-i "<prompt>"`). Instead, subagents are launched bare and interactively, awaiting their initial bootstrap instructions delivered exclusively via `noriba-cli msg send`.

---

## 3. Role-Based Selection Matrix

Token economics dictate where compute is spent:
- **Workers** consume ~80–90% of total plan tokens through multi-turn tool loops, test runs, and compiler error cycles. Low-latency, cost-effective models with low reasoning effort maximize speed while preventing cost explosion.
- **Reviewers** consume <15% of total tokens in a single read-only turn. High reasoning models with deep thinking effort maximize bug detection ROI.

| Role | Claude Code Flag | Antigravity Flag *(Non-Work)* | Codex Flag |
| :--- | :--- | :--- | :--- |
| **Worker (Unit Implementer)** | `--model sonnet --effort low`<br>*(small tasks: `--model haiku`)* | `--model gemini-3.8-flash-low --effort low` | `-m gpt-6-sol -c reasoning_effort="low"` |
| **Worker (Complex Subsystem)**| `--model sonnet --effort low` | `--model gemini-3.8-flash-medium --effort low` | `-m gpt-6-sol -c reasoning_effort="low"` |
| **Spec Reviewer** | `--model opus --effort high` | `--model gemini-4-argon-high --effort high` | `-m gpt-6-astra -c reasoning_effort="high"` |
| **Code Quality Reviewer** | `--model opus --effort high` | `--model gemini-4-argon-high --effort high` | `-m gpt-6-astra -c reasoning_effort="high"` |
| **Sub-Controller (Area Lead)** | `--model sonnet --effort medium` | `--model gemini-4-argon-medium --effort medium` | `-m gpt-6-sol -c reasoning_effort="medium"` |
