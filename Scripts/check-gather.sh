#!/bin/bash
# Run the production Gather filter logic against calendar and discovery cases.
set -euo pipefail
repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/homeschool-gather-checks.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
# These models use UIKit; compile and run against the iOS simulator SDK.
xcrun swiftc -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" \
  -target "$(uname -m)-apple-ios18.0-simulator" -module-cache-path "$check_dir/modules" \
  "$repo_dir/Homeschool/Core/Models/Event.swift" \
  "$repo_dir/Homeschool/Features/Gather/GatherFeedFilter.swift" \
  "$repo_dir/Homeschool/Features/Gather/EventPresentation.swift" \
  "$repo_dir/Homeschool/Features/Gather/EventLocationStore.swift" \
  "$repo_dir/Tests/GatherFilterChecks.swift" \
  -o "$check_dir/checks"
xcrun simctl spawn "${IOS_SIMULATOR_ID:-booted}" "$check_dir/checks"
