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

## bt-aplinfo added (2026-09-26)

`tests/coverage.sh` now runs `tests/layer` and `tests/aplinfo`, both under
kcov, and measures four files:

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 183 of 183 | 100 percent |
| bt-layer | 99 of 100 | 99 percent |
| bin/aplinfo-lib | 186 of 186 | 100 percent |
| bt-aplinfo | 47 of 47 | 100 percent |

The gate stays at 99.

Command, from the repository root with `kcov`, `zstd`, `git` and `gpg`
installed:

    tests/coverage.sh            # threshold 95, or COVERAGE_THRESHOLD, or the first argument

## Not measured

`tests/appname-version` exercises the inherited `bin/appname-version` by hand
and is not run under kcov; the other `bt-*` scripts (about 40 shell files)
have no test. They follow the 0004 treatment when the project touches them,
and the repository total is remeasured then.

## 2026-09-26: the build audit

`layer_audit_packages` reads the built rootfs's dpkg status and refuses a
layer that carries an unconfigured or half-installed package, and `bt-layer`
now treats a non-zero `make` as fatal instead of relying on the stamp alone.
Both are covered by `tests/layer` (audit clean and audit unconfigured).

## 2026-09-26: the signing identity

`bin/generate-signature` no longer hardcodes TurnKey's release key. Its logic
moved into `bin/signature-lib` under the 0004 split and `tests/signature`,
rewritten with throwaway keys generated inside the test, is the third suite
`tests/coverage.sh` runs:

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 195 of 196 | 99 percent |
| bt-layer | 101 of 102 | 99 percent |
| bin/aplinfo-lib | 186 of 186 | 100 percent |
| bt-aplinfo | 47 of 47 | 100 percent |
| bin/signature-lib | 76 of 76 | 100 percent |
| bin/generate-signature | 87 of 87 | 100 percent |

The gate stays at 99. The stub `tests/layer` puts where `bt-layer` expects
`generate-signature` is excluded by its scratch path, so the stub's 100
percent cannot stand in for the real script's number.

## 2026-09-27: the cipher list of a child layer

`layer_needs_ssl_ciphers` decides whether a child layer has to run
`turnkey.d/zz-ssl-ciphers`, and it now looks at the overlays the child
applies as well as the conf scripts it runs: nginx keeps the `ZZ_SSL_CIPHERS`
mark in `overlays/nginx/etc/nginx/snippets/ssl.conf`, not in a conf script,
so a layer built on an nginx stack shipped the literal mark as its cipher
list and nginx refused to start. Two cases in `tests/layer`, an overlay that
carries the mark and one that does not.

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 207 of 208 | 99 percent |
| bt-layer | 101 of 102 | 99 percent |
| bin/aplinfo-lib | 186 of 186 | 100 percent |
| bt-aplinfo | 47 of 47 | 100 percent |
| bin/signature-lib | 76 of 76 | 100 percent |
| bin/generate-signature | 87 of 87 | 100 percent |

The gate stays at 99.
