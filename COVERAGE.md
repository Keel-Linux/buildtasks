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

## 2026-09-29: the private key audit

`layer_audit_keys` refuses a layer whose tree holds a private key, since every
machine built from the layer would share it (keel-core#8). It runs from
`layer_check_build`, before anything is packed, and names every key it
finds by its path in the image. The only keys it accepts are the inert
package examples in `conf/layer-inert-keys`, each at its own path and digest.
`tests/layer` covers each key format, a key after a certificate, the quoted
marker, a binary, a symlink out of the tree, the list at its path and digest
and nowhere else, a grep that fails or is missing, and a `bt-layer` run whose
build leaks a host key (refused, no tarball, no manifest). Mutating the
pattern, the digest match, the grep status check, `-I` or the symlink rule
each turns the suite red. Coverage: layer-lib and bt-layer unchanged at one
uncovered line each, the same lines as on 19.x.

## 2026-10-01: the machine-id of the ISO and the images made from it

`bin/reset-machine-id` applies `layer_reset_machine_id` to any rootfs, and
`bin/iso-machine-id-check` refuses an ISO whose live squashfs carries an id,
read with `layer_machine_id_is_reset` (Keel-Linux/tracker#24). `bt-iso` builds
`root.patched` first, resets it, then lets fab squash it, and checks the ISO
before screenshots and release, `-u` included. `bin/rootfs-cleanup`, which
every image made from the ISO's rootfs runs last (bt-vm, bt-container,
bt-xen, bt-openstack, bt-ec2, bt-otc, bt-docker and the others), resets the
id after the chroot work. The new suite `tests/machine-id` makes small ISOs
with mksquashfs and xorriso, so CI installs `squashfs-tools` and `xorriso`.
Reverting the `bt-iso` or the `rootfs-cleanup` change each turns it red.
Coverage: bin/reset-machine-id 9 of 9, bin/iso-machine-id-check 30 of 30,
bin/rootfs-cleanup 11 of 11, layer-lib 390 of 391 (the predicate covered in
`tests/layer`, the same one uncovered line as on 19.x), bt-layer unchanged.

## 2026-09-30: the machine-id reset

`layer_reset_machine_id` leaves every exported layer with an empty
`/etc/machine-id` and `/var/lib/dbus/machine-id` as a link to it, so systemd
gives each machine its own id at boot (docs/traps.md, "Every appliance built
from core has the same machine-id"). `bt-layer` runs it after
`layer_check_build`, before the rootfs copy and the tarball. `tests/layer`
covers a populated id and D-Bus copy, a tree already reset left untouched
(file and link), a missing id, a symlinked id, a D-Bus link elsewhere, no
D-Bus copy, no `/etc`, a directory in the way of either, the `core` tarball
and rootfs of a build that wrote an id, and a `bt-layer` run whose id cannot
be reset (refused, no tarball). Mutating each condition or the mode turns the
suite red. Coverage: layer-lib 383 of 384 and bt-layer 111 of 112, the same
one uncovered line each as on 19.x.

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
| bin/layer-measure-lib | 206 of 206 | 100 percent |
| bin/layer-compare-lib | 330 of 330 | 100 percent |
| bin/layer-report-lib | 273 of 273 | 100 percent |
| bt-layer-measure | 78 of 78 | 100 percent |

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

## 2026-09-28: the exemption that inverted the property

The third review found one line that undid the pinning rule it sat inside.
`measure_mask_admits` admitted a unit line identical to *any* control's line
at that position, ahead of every pin, on the grounds that it was "a value this
recipe makes on its own". The base capture is the first control, so a value
copied from the second or third differs from the base, is flagged as a
differing position, and was then waved through. Verified against three
controls: a unit shipping the host key control 2 produced came out `noise`,
the machine-id control 3 produced came out `noise`, a replayed root hash came
out `noise`, and a *fresh random* key at the same path came out
`overlapping`. The safe case was the one that failed.

The rationale was true and did not support the conclusion. What makes a
generated secret safe is that it is different every build, so matching a
control is evidence of pinning rather than of freshness; `docs/traps.md`,
"Every appliance built from `core` has the same machine-id", is that defect
already recorded in this project. The early return is deleted. It cost
nothing: a genuinely pinned field still passes on length and class, and two
independent random values do not collide, so the branch only ever admitted
replays. `tests/compare` carries the three replays and the fresh-key control.

Also in that round, and each of them a measure that was easier to write than
to defend:

`MEASURE_WAIVER_MIN_LITERAL` counted the literal characters of a glob, and
`./etc/ss*` has exactly the eight it required while covering an SSH host key
and a TLS private key together. A rule is now an exact path or a named
directory's subtree written `DIR/**`, with at least two components below
`./`, and the paths it actually covers must sit under one immediate child of
that directory. A directory is a thing somebody chose; a character count is
not.

`justified-against` was printed and never read, which is the shape
`state_paths_sha256` had two rounds ago. The capture directory it names is now
compared with `--dir` and the run fails when they differ.

`share/layer-waivers.example` set `max-position` to the sample cap, which is
past the end of anything that was sampled and so bounds nothing, on the line
a maintainer copies. The template now carries real observed maxima, one rule
per file shape, and a value at or past the cap is refused.

The abbreviation cap hid 115 of the 135 non-`real` paths, and `noise` passes,
so the one remaining route to a bad `noise` landed where no bytes were
printed. Only `overlapping` is abbreviated now.

## 2026-09-28: the third measure of glob breadth

Two measures of how broad a waiver rule is were tried and both were wrong the
same way, by being easier to write than to defend. Counting the literal
characters of the glob let `./etc/ss*` through, which waives an SSH host key
and a TLS private key under one sentence. Counting its components below `./`
let `./var/lib/**` through, which is the common parent of the six subtrees
`share/layer-state-paths` declares separately, so a justification about MariaDB
accounts could clear PostgreSQL state in a later run whose count happened to
match; and the counts coinciding is not luck, because the same component shape
produces the same number of state files.

The measure is now the project's own statement of what state is: a glob rule's
directory has to be a directory the capture's state path list declares, or
below one. `./var/lib/mysql/**` is allowed because the list names that
directory, `./var/lib/**` is refused because nothing names `./var/lib`, and
`./etc/ssh/**` stays allowed because `./etc/ssh/ssh_host_*` names it. A glob
with no wildcard in its last component declares a file and no directory, so
`./etc/shadow` does not license a waiver over `./etc`. `MEASURE_WAIVER_MIN_DEPTH`
is gone, and the waiver vocabulary is the vocabulary of the thing being waived.
The list is already digest checked across the captures, so this adds no new
thing to trust.

`justified-against` was a substring test, which accepted a waiver justified
against `mariadb-gate2` for a run on `mariadb-gate`. Its first comma separated
component is now compared for equality.

## 2026-09-28: anchoring the state path list to the repository

The licensing rule of the previous section made `state-paths.txt` load bearing
twice: it decides which bytes a capture keeps, and it decides which waiver
rules are legal. `measure_preconditions` checked that every capture carried a
byte identical list whose recorded digest matched, which says the operator was
consistent with themselves and nothing more. Four captures taken against a
list with `./var/lib/**` added agree with each other, license a `./var/lib/**`
waiver, and let one sentence about MariaDB accounts clear PostgreSQL state.
`share/layer-state-suspect` cannot catch it, and reports `0 subtracted but
state shaped` throughout, because widening the list makes more paths state
paths so nothing new is subtracted.

`attribute` now also compares the capture's copy with the committed
`share/layer-state-paths` and refuses on mismatch. A run against another list
has to declare a reason with `--state-paths-override`, which the block prints
as `OVERRIDE` beside both digests, and the block prints both digests in any
case, because one digest with nothing to check it against is what the round
about `state_paths_sha256` was about.

Refusal rather than a printed warning, for the same reason: every other
precondition here refuses, and the defect being closed is a field that was
recorded and never read. A warning relies on somebody noticing.

The anchor has no environment override. `MEASURE_STATE_PATHS` is a capture
time knob and `attribute` ignores it entirely, including as a way of moving
the anchor, so the property that pointing it at a narrower file changes
nothing after the fact is unchanged. `tests/measure` now takes its captures
against the committed list rather than a fixture list, which is the real
configuration.

### What the number does and does not say

A mutation test of the six branches added with the licensing rule: three fail
the suite when removed, which is coverage doing work (the
wildcard-in-last-component guard in `measure_state_dirs`, the equality clause
in `measure_dir_at_or_below`, and loosening that function's path boundary to a
prefix match). Two survive because they are redundant, since removing them the
licensing loop refuses the same inputs anyway: the no-wildcard-in-directory
and empty-list guards in `measure_waiver_rule_shape`. They stay as defence in
depth and a surviving mutant is the correct result for them.

The sixth, the `*/*` guard in `measure_state_dirs` that skips a malformed
entry with no slash in it, executed without being tested. It is tested now,
`state-dirs-noslash` in `tests/compare`, because 100 percent line coverage
with one line in it that no assertion would miss is a number claiming more
than it has.

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
