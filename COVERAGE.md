# Test coverage baseline

Companion to the project decisions 0003 (90 percent floor per repository,
95 percent for every file the project writes) and 0004 (shell tests: bats,
kcov, one sourceable library per script). This fork never had a
`docs/coverage-baseline` branch; the first measurement is the one below.

## Measured baseline on 19.x: 99 percent (2026-09-26)

Pull request #1 merged on 2026-09-26 (merge commit ad4e8fe) with
`tests/coverage.sh`, which runs `tests/layer` under kcov 43:

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 183 of 183 | 100 percent |
| bt-layer | 99 of 100 | 99 percent (the missing line is the continuation of a multi-line command) |

The gate in `.github/workflows/tests.yml` is set to 99, the lowest file
rounded down, and is only ever raised.

Command, from the repository root with `kcov`, `zstd` and `git` installed:

    tests/coverage.sh            # threshold 95, or COVERAGE_THRESHOLD, or the first argument

## Not measured

`tests/appname-version` and `tests/signature` exercise the inherited
`bin/appname-version` and `generate-signature` scripts by hand and are not
run under kcov; the other `bt-*` scripts (about 40 shell files) have no
test. They follow the 0004 treatment when the project touches them, and the
repository total is remeasured then.
