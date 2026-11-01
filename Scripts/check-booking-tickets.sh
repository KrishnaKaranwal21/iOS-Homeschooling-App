#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/homeschool-ticket-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -module-cache-path "$check_dir/modules" \
  "$repo_dir/Homeschool/Core/Models/Event.swift" \
  "$repo_dir/Homeschool/Core/Models/Registration.swift" \
  "$repo_dir/Homeschool/Features/Gather/BookingCode.swift" \
  "$repo_dir/Tests/BookingTicketChecks.swift" \
  -o "$check_dir/checks"
"$check_dir/checks" "$@"
