#!/bin/bash
# Line coverage of bin/layer-lib and bt-layer under tests/layer, measured
# with kcov. Exits 1 when a measured file is below the threshold (default
# 95), 2 when a tool is missing.
#
#   tests/coverage.sh [THRESHOLD]     (or COVERAGE_THRESHOLD in the environment)
#
# COVERAGE_DIR keeps the kcov report (default: a temporary directory).
# Needs the Debian packages kcov, zstd and git.
#
# tests/layer runs bt-layer from a scratch copy (it needs its own config
# directory), so kcov lists the copy next to the checkout: the two files are
# matched by name and, per name, the executed copy is the one measured.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
threshold="${1:-${COVERAGE_THRESHOLD:-95}}"

for tool in kcov zstd git; do
    if ! command -v "$tool" >/dev/null; then
        echo "$tool not found (apt-get install $tool)" >&2
        exit 2
    fi
done

report="${COVERAGE_DIR:-$(mktemp -d)}"
kcov --include-pattern=/bin/layer-lib,/bt-layer --exclude-pattern=/tests/ \
    "$report" "$here/layer"

json="$(find "$report" -mindepth 2 -maxdepth 2 -name coverage.json -not -path "*/kcov-merged/*" | head -1)"

# kcov writes one line per file:
#   {"file": "PATH", "percent_covered": "P", "covered_lines": "C", "total_lines": "T"},
echo
echo "kcov line coverage (threshold $threshold percent):"
awk -F'"' -v threshold="$threshold" '
    /^ *\{"file":/ {
        n = split($4, parts, "/")
        name = parts[n]
        if (!(name in covered) || $12 + 0 > covered[name]) {
            covered[name] = $12 + 0
            total[name] = $16 + 0
            percent[name] = $8 + 0
        }
    }
    END {
        for (name in covered) {
            mark = (percent[name] >= threshold) ? "ok" : "BELOW THRESHOLD"
            if (percent[name] < threshold) {
                low = 1
            }
            printf "%7.2f  %4s/%-4s  %-12s %s\n", percent[name], covered[name], total[name], name, mark
        }
        if (low) {
            print "coverage below threshold (report: '"$report"')" > "/dev/stderr"
        }
        exit low
    }' "$json"
