#!/bin/bash
# Run the production Gather filter logic against calendar and discovery cases.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/homeschool-gather-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -module-cache-path "$check_dir/modules" \
  "$repo_dir/Homeschool/Core/Models/Event.swift" \
  "$repo_dir/Homeschool/Features/Gather/GatherFeedFilter.swift" \
  "$repo_dir/Homeschool/Features/Gather/EventPresentation.swift" \
  "$repo_dir/Homeschool/Features/Gather/EventLocationStore.swift" \
  "$repo_dir/Tests/GatherFilterChecks.swift" \
  -o "$check_dir/checks"
"$check_dir/checks"
