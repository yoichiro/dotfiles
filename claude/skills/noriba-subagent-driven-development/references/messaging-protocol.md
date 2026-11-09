# Messaging Protocol & Lifecycle Specification

This specification governs all inter-terminal communication in `noriba-subagent-driven-development` via `noriba-cli msg`.

## 1. Transport & Ingestion

- **Command**: `noriba-cli msg send (<ID> | --role <ROLE>) "<PAYLOAD>"`
- **Injection Mechanism**: Bracketed paste with `--auto-enter` (`\r`) into the target terminal's PTY.
- **Header Format**: Noriba automatically prepends `[noriba msg from <role>@<host> <id>]\n` to delivered payloads.

## 2. Normalized Status Strings

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

## 3. Pointer-Based Storage Contracts

To maintain strict bounds on command-line argument lengths and shell quotation, all substantive task definitions live on disk under `.superpowers/sdd/<plan>/`:
- `task-<id>-brief.md`: Requirements, interfaces, file lists, and test assertions.
- `task-<id>-report.md`: Files modified, unit test output, commit hashes.
- `task-<id>-review-findings.md`: Line-by-line defect reports from reviewers.
