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

## 2026-09-27: units in the layer manifest

`bt-layer` records the components a layer carries as fab units, and a child
layer subtracts the ones its parent applied instead of applying them again.
Ten new functions in `bin/layer-lib` (`layer_unit_content`,
`layer_unit_digest`, `layer_unit_version`, `layer_unit_check`, `layer_units`,
`layer_units_version`, `layer_child_units`, `layer_units_merge`,
`layer_unit_paths`, `layer_manifest_opt`) and six cases in `tests/layer`
covering a rootfs layer with a unit, a child that composes the same unit, a
child that adds one, a child with none of its own, a version conflict and a
unit whose `conf` fab would skip.

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 331 of 332 | 99 percent |
| bt-layer | 110 of 111 | 99 percent |
| bin/aplinfo-lib | 186 of 186 | 100 percent |
| bt-aplinfo | 47 of 47 | 100 percent |
| bin/signature-lib | 76 of 76 | 100 percent |
| bin/generate-signature | 87 of 87 | 100 percent |

The gate stays at 99. Both missing lines are the continuation of a
multi-line command, which kcov cannot attribute; every function added here
is fully covered, so nothing new was written in that shape.

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

## 2026-09-28: the three-build comparison

`bt-layer-measure` makes handbook decision 0010 step 3 executable: a capture
subcommand that builds a layer and records its package list, file tree,
symlinks and state paths, a compare subcommand over two captures and an
attribute subcommand over the three or more the decision asks for. The logic
is split three ways under decision 0004: `bin/layer-measure-lib` (capture and
formats), `bin/layer-compare-lib` (whether a difference is noise) and
`bin/layer-report-lib` (the blocks and the preconditions), with
`bt-layer-measure` a thin main over them. `tests/coverage.sh` runs
`tests/measure` and `tests/compare` as its fourth and fifth suites and
measures ten files:

| File | Lines covered | Cover |
|------|---------------|-------|
| bin/layer-lib | 331 of 332 | 99 percent |
| bt-layer | 110 of 111 | 99 percent |
| bin/aplinfo-lib | 186 of 186 | 100 percent |
| bt-aplinfo | 47 of 47 | 100 percent |
| bin/signature-lib | 76 of 76 | 100 percent |
| bin/generate-signature | 87 of 87 | 100 percent |
| bin/layer-measure-lib | 204 of 204 | 100 percent |
| bin/layer-compare-lib | 298 of 298 | 100 percent |
| bin/layer-report-lib | 253 of 253 | 100 percent |
| bt-layer-measure | 71 of 71 | 100 percent |

The gate stays at 99, the lowest file rounded down. All four new files are at
100 percent line and branch: every subcommand, every exit code (0, 1, 2 and
3), every verdict and every error path, including the two guards that must
never fire, which `tests/measure` reaches by replacing `measure_verdict` with
a stub.

## 2026-09-28: what the first version of the comparison got wrong

Worth recording, because the defect was in the same direction as the one the
tool exists to correct and the suite did not catch it.

The first implementation compared *positions*: the line numbers or byte
offsets at which two files differ, subtracting the control pair's set from
the control-unit set. Two unrelated changes at one position annihilate. Four
cases came back as `noise`, exit 0, with the evidence suppressed because they
were noise: an account added to `/etc/shadow` at the line number the control
pair also appends at; a root password set on the line the control pair
rewrites for a clock reason; a binary differing at the same eight offsets
with different byte values; a file 3584 bytes shorter against a control pair
that varies by one.

`tests/compare` is that list. The controls are now the model and the model
carries content: at each position the controls vary at, the longest common
prefix and suffix of their variants is the shape the unit has to fit. A mask
with nothing in it proves nothing, and bytes carry no shape at all, so a
binary coincidence is `overlapping` and fails until it is cleared in writing.
The evidence is printed for every verdict, `noise` included, because the one
mistake the scheme can still make is the one nobody would otherwise see.

## 2026-09-28: a mask that constrained only the ends of a line

The second review found the first fix incomplete in the same direction. The
mask pinned a line's common prefix and common suffix and left the region
between them free: no length, no character class, no resemblance to anything
a control put there. So wherever the controls vary at random, the mask
degenerates to the line's fixed framing and any value carrying that framing
was admitted as `noise`. A hardcoded `ssh_host_ed25519_key.pub`, a baked-in
root password hash, a free region grown by 400 characters, and a SQL payload
planted on the real `mysql/user.frm` of the gate run all came back `noise`.

The fix is the rule already written in the file applied to the other branch.
`bin/layer-compare-lib` argues that bytes carry no shape, so a binary
coincidence is never `noise`; a per-build random text field carries no more
shape than a random byte field. `noise` now requires the controls to pin the
free region: they must agree on its length, it must be no longer than
`MEASURE_FREE_MAX`, and every character of it must be in the class they used
there, which may only be digits and the punctuation of a date. A line a
control itself produced is admitted whatever its shape, because that is a
value the recipe makes on its own.

This also removes the dependence the review named on when the gate happened
to run. The `user.frm` mask was 21 characters of prefix only because four
builds landed inside the same thousand seconds; across a digit carry it
collapses to 9. `tests/compare` runs that case: the clock is `noise` and the
payload is not, at either prefix length, because the criterion is now the
field's width and class rather than how much framing survived.

## 2026-09-28: pipefail in the three older suites

`tests/layer`, `tests/aplinfo` and `tests/signature` did not set `pipefail`
while `bt-layer`, `bt-aplinfo` and `bin/generate-signature` all do, so a
library function that inherits a pipeline's status fails in production and
passes in the suite. That is exactly how `measure_signature` shipped broken
once. All five suites now set it. One assertion had to change with it:
`tests/signature` piped `generate-signature --help` into `grep`, and usage
exits non-zero by convention, so the output is captured first.

## Not measured

`tests/appname-version` exercises the inherited `bin/appname-version` by hand
and is not run under kcov; the other `bt-*` scripts have no test. They follow
the 0004 treatment when the project touches them, and the repository total is
remeasured then.
