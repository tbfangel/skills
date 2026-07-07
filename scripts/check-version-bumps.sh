#!/usr/bin/env bash
#
# Fail if a plugin's skills/ content changed relative to a base ref without a
# corresponding version bump in its .claude-plugin/plugin.json.
#
# Usage: scripts/check-version-bumps.sh [base-ref]
#   base-ref defaults to origin/main. In CI, pass the PR base SHA.
#
# Rationale: `claude plugin update` keys off the version string, so a skills
# change shipped without a version bump never reaches installed clients.

set -euo pipefail

base="${1:-origin/main}"

fail=0
checked=0

for plugin_json in plugins/*/.claude-plugin/plugin.json; do
  [ -e "$plugin_json" ] || continue
  plugin_dir=$(dirname "$(dirname "$plugin_json")")
  name=$(basename "$plugin_dir")

  # Only care about plugins whose skills/ content changed vs the base.
  if git diff --quiet "$base"...HEAD -- "$plugin_dir/skills/"; then
    continue
  fi
  checked=$((checked + 1))

  head_version=$(jq -r '.version // empty' "$plugin_json")
  if [ -z "$head_version" ]; then
    echo "✗ $name: skills changed but plugin.json has no version"
    fail=1
    continue
  fi

  # A plugin absent from the base is brand new — any version is fine.
  if base_json=$(git show "$base:$plugin_json" 2>/dev/null); then
    base_version=$(printf '%s' "$base_json" | jq -r '.version // empty')
  else
    echo "✓ $name: new plugin (version $head_version)"
    continue
  fi

  if [ "$head_version" = "$base_version" ]; then
    echo "✗ $name: skills changed but version not bumped (still $head_version)"
    fail=1
    continue
  fi

  # Require the version to move forward, not backward.
  greater=$(printf '%s\n%s\n' "$base_version" "$head_version" | sort -V | tail -n1)
  if [ "$greater" != "$head_version" ]; then
    echo "✗ $name: version must increase ($base_version -> $head_version)"
    fail=1
    continue
  fi

  echo "✓ $name: skills changed, version bumped $base_version -> $head_version"
done

if [ "$fail" -ne 0 ]; then
  cat >&2 <<'MSG'

A plugin changed its skills/ content without a forward version bump in its
.claude-plugin/plugin.json. Bump the version in the same change — minor for
new or changed skills, patch for fixes — so `claude plugin update` can pull it.
MSG
  exit 1
fi

if [ "$checked" -eq 0 ]; then
  echo "No plugin skills changed vs $base — nothing to check."
else
  echo "All changed plugins are version-bumped."
fi
