# Messaging Protocol & Lifecycle Specification

This specification governs all inter-terminal communication in `noriba-subagent-driven-development` via `noriba-cli msg`.

## 1. Transport & Ingestion

- **Command**: `noriba-cli msg send (<ID> | --role <ROLE>) "<PAYLOAD>"`
- **Direct Terminal Targeting**: In SDD orchestration, all message deliveries to subagents MUST target the specific terminal UUID (`<ID>` or `$TID`) returned by `noriba-cli terminal open`. The `--role <ROLE>` flag is used during terminal creation for role assignment and bus discovery, but direct `<ID>` addressing eliminates delivery collisions, ambiguity, and ghost tabs when multiple subagent terminals exist simultaneously or iterate rapidly.
- **Injection Mechanism**: Bracketed paste with `--auto-enter` (`\r`) into the target terminal's PTY.
- **Header Format**: Noriba automatically prepends `[noriba msg from <role>@<host> <id>]\n` to delivered payloads.

## 2. Two-Step Subagent Activation

Subagents are activated in a decoupled two-step procedure:

1. **Terminal Open (Bare Launch & UUID Capture)**:
   ```bash
   TID=$(noriba-cli terminal open --background --role <ROLE> -- <ENGINE_CMD>)
   ```
   The agent engine is spawned in interactive mode with its permission bypass and model flags, without any initial prompt argument. `noriba-cli terminal open` prints the created terminal UUID to standard output.
2. **Bootstrap Prompt Delivery**:
   ```bash
   noriba-cli msg send "$TID" "<BOOTSTRAP_PROMPT>"
   ```
   Because terminals spawned with `--role` run under `--auto-enter` in noriba's message delivery pipeline, the bootstrap prompt is pasted and automatically submitted via a trailing carriage return (`\r`) directly into the target terminal's PTY, seamlessly starting execution without manual user interaction or multi-tab role collisions.

## 3. Normalized Status Strings

All status messages returned to the controller or lead must strictly follow this envelope:

### Worker -> Controller
- `Status: READY_FOR_REVIEW - <task-id>`: Task implementation and unit tests are complete; ready for two-stage review.
- `Status: BLOCKED - <reason>`: Task cannot proceed due to environmental or dependency failure.

### Reviewer -> Controller
- `Status: PASS - <task-id>`: The review stage passed with zero defects.
- `Status: CHANGES_REQUESTED - <task-id> (Round <n>)`: Specific defects found; brief contains pointers to `task-<id>-review-findings.md`.

### Sub-Controller -> Root Controller
- `Status: SUB-PLAN COMPLETE - <area>`: All tasks in the delegated sub-plan are verified and pushed to the target branch.
- `Status: SUB-PLAN BLOCKED - <area> (<reason>)`: Sub-plan execution blocked.

## 4. Pointer-Based Storage Contracts

To maintain strict bounds on command-line argument lengths and shell quotation, all substantive task definitions live on disk under `.superpowers/sdd/<plan>/`:
- `task-<id>-brief.md`: Requirements, interfaces, file lists, and test assertions.
- `task-<id>-report.md`: Files modified, unit test output, commit hashes.
- `task-<id>-review-findings.md`: Line-by-line defect reports from reviewers.

## 5. Terminal Lifecycle & Immediate Teardown

Because interactive AI CLI engines (Claude Code, Antigravity CLI, OpenAI Codex) remain active at their prompt after executing commands or messaging, subagent terminals rarely exit autonomously. The parent controller must explicitly manage and tear down terminal sessions:

1. **Immediate Reviewer Teardown**:
   The controller must execute `noriba-cli terminal close "$REVIEWER_TID"` immediately upon receiving ANY reviewer verdict (`PASS` or `CHANGES_REQUESTED`). Reviewer tabs must never accumulate.
2. **Worker Teardown**:
   The controller must execute `noriba-cli terminal close "$WORKER_TID"` immediately upon passing Stage 2 (Code Quality) review.
3. **Whole-Branch Reviewer Teardown**:
   The controller must execute `noriba-cli terminal close "$FINAL_REVIEWER_TID"` immediately upon receiving the whole-branch review verdict.
4. **Sub-Controller Teardown**:
   The controller must execute `noriba-cli terminal close "$SUB_CONTROLLER_TID"` immediately upon receiving `Status: SUB-PLAN COMPLETE`.
5. **Phase 3 Terminal Cleanup Sweep**:
   Before presenting human integration choices in Phase 3, the controller must list all active terminals via `noriba-cli terminal list` and forcefully close any remaining auxiliary terminals (`noriba-cli terminal close <TID>`), guaranteeing that only the primary controller terminal remains open.
