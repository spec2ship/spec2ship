# Dogfood e2e procedure (piloted or user-driven)

> **NOT SHIPPED** — contributor process documentation. First executed end-to-end for
> v0.8.0 (exp50, 2026-07-12, piloted); v0.5.0/v0.6.0 ran the user-driven variant.

How to run the end-of-cycle dogfood that verifies instruction-layer changes: fixture
seeding, scenario derivation, drive, verification, and where the artifacts land. The
hermetic `tests/` suite covers script-layer changes; everything markdown-only verifies
ONLY through a driven run — this procedure is that run.

## The invariants (do not renegotiate per cycle)

1. **One synthetic dogfood per cycle**, batched at the end (decision record D3, lean
   path). Instruction fixes do NOT get per-PR dogfoods.
2. **Environment**: one fresh `exp*` worktree in the local-only dogfood repo
   (bare + worktree-per-experiment). Never reuse a dirty exp; reset a clean one to the
   pre-init commit when the init path is in scope.
3. **Data split**: raw outputs (sessions, dumps, generated docs, plans) commit in the
   dogfood repo; ONLY a structural summary (schema invariants, counts, per-finding
   verdicts, no domain text) goes to `.s2s/test-baselines/vX.Y.Z-dogfood.md`,
   referencing the raw commit SHAs.
4. **Scenarios derive from findings**: each in-scope finding's `proposed_test` (or the
   backlog item's acceptance criteria) becomes one or more `[assert]` lines in the
   runbook. No generic "run it and see".
5. **Plugin under test**: installed from the branch/ref under test via
   `/plugin marketplace add <url>#<ref>` + install + `/reload-plugins`. To verify a fix
   BEFORE merging, point at the fix branch; restore `#develop` when done.

## Runbook template

One runbook per cycle, colocated in the exp worktree (committed with the fixture):

```markdown
# expNN — vX.Y.Z dogfood runbook

## Step 0 — plugin at <ref>
/plugin marketplace remove <mp> · add <url>#<ref> · install · /reload-plugins
Verify the cache really has the changes (grep a marker string in the cached files).

## Scenario <n> — <workflow> (<finding ids>)
Seeds: <what the fixture plants and why>
1. Run /s2s:<command> <flags>.
2. `[assert]` <structural check, verifiable from files/transcripts>
...

## Wrap-up
1. Commit raw outputs in this worktree.
2. Structural summary → spec2ship/.s2s/test-baselines/ (via PR).
3. Flip the verified backlog checkboxes/items.

## Per-finding verdict sheet
| Finding | Scenario | Check | Verdict |
```

Fixture design rules of thumb:
- Seed **contradictions** you expect the tool to catch (two mutually exclusive
  features in the baseline; inject one live via "Type something" mid-round).
- Seed **code-vs-docs drift** when plan grounding is in scope (implementation that
  disagrees with the docs in countable ways: type counts, value scales, naming).
- Seed **pre-existing files** whose preservation matters (.gitignore with entries,
  hand-written requirements doc).
- Include the previous cycle's carry-over checks.

## Driving modes

**User-driven** (default per the dogfood cadence): contributor prepares fixture +
runbook, the user drives the sessions from a Claude Code session with cwd in the exp
worktree, contributor verifies afterwards via absolute paths.

**Piloted** (v0.8.0 pattern, requires explicit user authorization since it changes the
cadence): a Claude session drives a second Claude Code session inside a local tmux.
Mechanics that matter (learned the hard way):

- Launch: `tmux new-session -d -s dogfood -x 200 -y 50 -c <exp-path>` then send
  `claude --dangerously-skip-permissions` (throwaway worktree ⇒ acceptable risk).
- **Submit is the kitty sequence `ESC[13u]`**, not Enter:
  `tmux send-keys -t dogfood -H 1b 5b 31 33 75`. Type text first with
  `send-keys -l -- '<msg>'` (single line only).
- **Slash commands**: the autocomplete popup eats the submit — send `Escape` after
  typing, then the submit sequence.
- **Dialogs** (AskUserQuestion, trust prompts): plain `send-keys Enter` selects the
  highlighted option; number keys jump to an option. Multi-question dialogs chain:
  answer each, then "Submit answers".
- **State detection** from `capture-pane`: `esc to interrupt` or a spinner line ⇒
  working; `Waiting for N background agent` or a running `◯` agent row ⇒ still
  working; only the bare `bypass permissions on` bar ⇒ idle. Poll with a background
  watcher that requires N consecutive non-working reads before settling.
- **Verification NEVER from the pane scrollback**: the TUI runs in the alternate
  screen, history is not retained. Verify from files on disk and from the piloted
  session's transcript JSONL under `~/.claude/projects/<cwd-key>/<session-id>.jsonl`
  (assistant `text` blocks = what was actually displayed; tool_use blocks = what was
  actually invoked, e.g. which subagent_type).
- **Do not type while Claude is exiting** (`/exit` → relaunch): trailing bytes land in
  the shell and corrupt the next command. Wait for the shell prompt, `C-c` to clear,
  then relaunch, then wait for idle before sending anything.
- **The prompt line can show ghost placeholders** (suggestions rendered like typed
  text). Never submit what you did not type.
- Restart the piloted claude between workflows (fresh context ≈ what a real user does,
  and roundtables are token-heavy).

Reference transport helper: `tm.sh` (send / sendcmd / submit / read / state / key) +
`watch.sh` (settle watcher) — see the appendix; a maintained copy belongs to the
contributor's own tooling, this appendix is the spec.

## Verification sources, per assert type

| Assert about | Verify from |
|--------------|-------------|
| Generated docs (sections, ids, diagrams) | the files, with grep/diff against the session YAML id set |
| Session behavior (gates, coverage, warnings) | session YAML (`validation_override`, `validation.warnings`, `related_to`) |
| What was displayed | transcript JSONL assistant text blocks (NOT the tmux pane) |
| What was invoked | transcript JSONL tool_use blocks (`subagent_type`, prompts) |
| Instruction-compliance failures | instruction read in transcript + absent display/artifact = the BUG-013 pattern; prefer artifact-backed fixes |

## Appendix: transport helper spec

```bash
#!/usr/bin/env bash
# tm.sh {send|sendcmd|submit|read|state|key} — pilot a local Claude Code tmux pane
set -euo pipefail
S="${TM_SESSION:-dogfood}"
case "${1:?cmd}" in
  send)    # plain message: type literally, settle, kitty-submit
    msg="${2:?msg}"; case "$msg" in *$'\n'*) echo "multi-line" >&2; exit 1;; esac
    tmux send-keys -t "$S" -l -- "$msg"; sleep 0.5
    tmux send-keys -t "$S" -H 1b 5b 31 33 75 ;;
  sendcmd) # slash command: Escape closes the autocomplete before submit
    tmux send-keys -t "$S" -l -- "${2:?msg}"; sleep 0.5
    tmux send-keys -t "$S" Escape; sleep 0.3
    tmux send-keys -t "$S" -H 1b 5b 31 33 75 ;;
  submit)  tmux send-keys -t "$S" -H 1b 5b 31 33 75 ;;
  read)    tmux capture-pane -t "$S" -p -S "-${2:-100}" ;;
  key)     tmux send-keys -t "$S" "${2:?key}" ;;
  state)
    out="$(tmux capture-pane -t "$S" -p -S -30)"
    if   echo "$out" | grep -q "esc to interrupt"; then echo working
    elif echo "$out" | grep -qE '^[✢✽✻✶✳✦·\*][[:space:]].*(…|\.\.\.)'; then echo working
    elif echo "$out" | grep -qE 'Waiting for [0-9]+ background agent'; then echo working
    elif echo "$out" | grep -qE '^  ◯ s2s:'; then echo working
    elif echo "$out" | grep -q "bypass permissions on"; then echo idle
    else echo unknown; fi ;;
esac
```

```bash
#!/usr/bin/env bash
# watch.sh [max_seconds] — exit when the pane stops working (3 stable reads)
set -u; SP="$(dirname "$0")"; MAX="${1:-900}"; elapsed=0; stable=0; sleep 8
while [ "$elapsed" -lt "$MAX" ]; do
  st="$("$SP/tm.sh" state)"
  [ "$st" != "working" ] && stable=$((stable+1)) || stable=0
  [ "$stable" -ge 3 ] && { echo "SETTLED state=$st after ${elapsed}s"; exit 0; }
  sleep 5; elapsed=$((elapsed+5))
done
echo "TIMEOUT still $("$SP/tm.sh" state) after ${MAX}s"; exit 1
```
