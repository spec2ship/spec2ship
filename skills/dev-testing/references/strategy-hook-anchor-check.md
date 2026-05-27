# Strategy Hook Anchor Drift Check

> **Status**: dev-testing reference (TECH-002 Phase 4, Option B safety net)
> **Purpose**: validate that `## Strategy hooks` opening lines in `roundtable-strategies/references/*.md` still match the regex anchors codified in `roundtable-execution/references/strategy-hook-resolution.md`.
> **When to run**: before merging any PR that touches `roundtable-strategies/references/*.md` (especially edits to `## Strategy hooks` sections). Also part of Phase 4.5 regression check.

## Invocation

From the spec2ship repo root:

```bash
bash <(cat <<'EOF'
#!/usr/bin/env bash
# Strategy hook anchor drift check (TECH-002 Phase 4)
# Exit codes: 0=clean, 1=drift detected (action: update either docs or fixture)

set -e
STRATEGIES=(standard consensus-driven debate disney six-hats)
DOCS_DIR="skills/roundtable-strategies/references"
FIXTURE="skills/roundtable-execution/references/strategy-hook-resolution.md"

declare -A EXPECTED_REGEX=(
  ["standard"]="^No per-round hooks\."
  ["consensus-driven"]="^No per-round hooks\."
  ["debate"]="^Facilitator-driven, LLM-emergent"
  ["disney"]="^Phase progression determined by"
  ["six-hats"]="^No per-round overrides"
)

drift_count=0
for strategy in "${STRATEGIES[@]}"; do
  doc="$DOCS_DIR/$strategy.md"
  if [[ ! -f "$doc" ]]; then
    echo "MISSING: $doc"
    drift_count=$((drift_count+1))
    continue
  fi
  # Extract first non-empty line of "## Strategy hooks" section
  opening=$(awk '/^## Strategy hooks/{flag=1;next} flag && NF{print; exit}' "$doc")
  if [[ -z "$opening" ]]; then
    echo "EMPTY ## Strategy hooks section: $doc"
    drift_count=$((drift_count+1))
    continue
  fi
  regex="${EXPECTED_REGEX[$strategy]}"
  if [[ "$opening" =~ $regex ]]; then
    echo "OK: $strategy → \"$opening\" matches /$regex/"
  else
    echo "DRIFT: $strategy"
    echo "  Doc opening line: $opening"
    echo "  Expected regex:   $regex (per $FIXTURE)"
    drift_count=$((drift_count+1))
  fi
done

if [[ $drift_count -eq 0 ]]; then
  echo ""
  echo "All 5 strategy hook anchors aligned (no drift)."
  exit 0
else
  echo ""
  echo "DRIFT DETECTED in $drift_count strategy doc(s)."
  echo "Action required: either"
  echo "  (a) revert the docs change to restore the opening line phrase, OR"
  echo "  (b) update the regex in $FIXTURE to match the new opening line."
  echo "If (b), also update the EXPECTED_REGEX array in this script."
  exit 1
fi
EOF
)
```

## Maintenance

The `EXPECTED_REGEX` array in this script is the local mirror of the anchor table in `strategy-hook-resolution.md`. Keep in sync: any regex change in the fixture must be replicated here.

## Future work (post v0.4.0)

If/when the plugin acquires CI infrastructure (e.g. GitHub Actions on the upstream repo), wire this script as a required check on PRs touching strategy docs. Pre-v0.4.0: manual invocation before docs PRs.

## Related

- ADR-0011 Phase 4 addendum: Option B fixture + drift check rationale
- `skills/roundtable-execution/references/strategy-hook-resolution.md`: authoritative fixture (this script validates against it)
- Phase 4 plan §4.2 step 7 + R1 mitigation
