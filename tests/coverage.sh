#!/bin/bash
# Line coverage of the project-authored shell code, measured with kcov:
#   bin/layer-lib and bt-layer under tests/layer
#   bin/aplinfo-lib and bt-aplinfo under tests/aplinfo
#   bin/signature-lib and bin/generate-signature under tests/signature
# Exits 1 when a measured file is below the threshold (default 95), 2 when a
# tool is missing.
#
#   tests/coverage.sh [THRESHOLD]     (or COVERAGE_THRESHOLD in the environment)
#
# COVERAGE_DIR keeps the kcov report (default: a temporary directory).
# Needs the Debian packages kcov, zstd, git and gpg.
#
# The tests run the bt-* scripts from a scratch copy (they need their own
# config directory), so kcov lists the copy next to the checkout: the two
# files are matched by name and, per name, the executed copy is the one
# measured. tests/layer also puts a two line stub where bt-layer expects
# generate-signature; that copy is excluded by its scratch path, since
# measuring it would hide the real script behind the stub's 100 percent.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
threshold="${1:-${COVERAGE_THRESHOLD:-95}}"

for tool in kcov zstd git gpg; do
    if ! command -v "$tool" >/dev/null; then
        echo "$tool not found (apt-get install $tool)" >&2
        exit 2
    fi
done

report="${COVERAGE_DIR:-$(mktemp -d)}"
measured=/bin/layer-lib,/bt-layer,/bin/aplinfo-lib,/bt-aplinfo,/bin/signature-lib,/bin/generate-signature
skipped=/tests/,/scratch-bt/bin/generate-signature
for suite in layer aplinfo signature; do
    kcov --include-pattern="$measured" --exclude-pattern="$skipped" \
        "$report" "$here/$suite"
done

mapfile -t json < <(find "$report" -mindepth 2 -maxdepth 2 -name coverage.json -not -path "*/kcov-merged/*" | sort)

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
    }' "${json[@]}"
