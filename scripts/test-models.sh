#!/bin/zsh
# Copyright (C) 2026 gsanz.dev
# GNU GPL version 3 only; see LICENSE and ATTRIBUTION.md.

set -euo pipefail
cd "${0:A:h:h}"
build_dir="$(mktemp -d /tmp/repit-model-tests.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
cp -R Repit/Resources/es.lproj "$build_dir/es.lproj"
xcrun swiftc -module-cache-path "$build_dir/cache" Repit/Models/Localization.swift Repit/Models/Workout.swift Repit/Models/RoutineStore.swift Tests/ModelTests.swift -o "$build_dir/tests"
"$build_dir/tests"
