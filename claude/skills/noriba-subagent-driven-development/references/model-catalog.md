# Model Catalog & CLI Reference (Late 2026 Baseline)

This catalog specifies recommended model identifiers and reasoning effort flags for each supported AI CLI engine.

## 1. Supported CLI Engines

### Claude Code (`claude`)
- **Fast / Cheap Worker**: `--model haiku` (`claude-haiku-5-5`)
- **Balanced Worker**: `--model sonnet` (`claude-sonnet-5-5`)
- **Capable / Reviewer / Lead**: `--model opus` (`claude-opus-5-5`)
- **Reasoning Flag**: `--effort <low|medium|high|xhigh|max>`
- **Permissions Bypass**: `--dangerously-skip-permissions`

### Antigravity CLI (`agy`)
- **Fast / Cheap Worker**: `--model gemini-3.8-flash-low`
- **Balanced Worker**: `--model gemini-3.8-flash-high`
- **Capable / Reviewer / Lead**: `--model gemini-4-argon-high`
- **Reasoning Flag**: `--effort <low|medium|high|xhigh|max>`

### OpenAI Codex CLI (`codex`)
- **Fast / Cheap Worker**: `-m gpt-6-luna`
- **Balanced Worker**: `-m gpt-6-sol`
- **Capable / Reviewer / Lead**: `-m gpt-6-astra`
- **Reasoning Flag**: `-c reasoning_effort="<low|medium|high|xhigh|max|ultra>"`

## 2. Selection Matrix

| Role | Claude Code Flag | Antigravity Flag | Codex Flag |
| :--- | :--- | :--- | :--- |
| **Worker (Unit Implementer)** | `--model haiku` | `--model gemini-3.8-flash-low` | `-m gpt-6-luna` |
| **Worker (Complex Subsystem)**| `--model sonnet` | `--model gemini-3.8-flash-high` | `-m gpt-6-sol` |
| **Spec Reviewer** | `--model opus --effort high` | `--model gemini-4-argon-high --effort high` | `-m gpt-6-astra -c reasoning_effort="high"` |
| **Code Quality Reviewer** | `--model opus --effort high` | `--model gemini-4-argon-high --effort high` | `-m gpt-6-astra -c reasoning_effort="high"` |
| **Sub-Controller (Area Lead)** | `--model opus --effort high` | `--model gemini-4-argon-high --effort high` | `-m gpt-6-astra -c reasoning_effort="high"` |
