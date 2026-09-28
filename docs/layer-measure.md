# bt-layer-measure: the three-build comparison

Handbook decision 0010 accepts splitting components out of the shared `common`
tree on one condition, stated in step 3 of its order of work: components move
one at a time, "re-running this three-build comparison for each, including the
control-vs-control run". This is that comparison. Before this script existed
the capture half was a scratch file in root's home directory on the build host
and the comparison half was never written down, so two component extractions
(keel-mariadb#11, keel-postgresql#7) were approved on a number only their
author could produce.

## Why three builds

Two builds of the *same* recipe are not identical. They differ in install-time
state: clocks, log lines, Perl hash order, a database data directory created
when a conf script starts the server. That set is the **noise floor**, and it
is the only reason a build of a *changed* recipe is allowed to differ from the
control at all. Without a second control build there is nothing to subtract,
so no difference can be attributed to the change, which is what the third
build is for.

## Usage

    bt-layer-measure capture   --dir DIR --layer NAME [--parent NAME] --tag TAG
                               [--state-max-bytes N]
    bt-layer-measure compare   --dir DIR --a TAG --b TAG
    bt-layer-measure attribute --dir DIR --control TAG --unit TAG --control-again TAG

`--dir` is required by every subcommand and defaults to nothing, so the
directory holding the measurement is named in the command and a second person
runs the same command against the same directory. Nothing is kept in a home
directory on one machine.

## The whole procedure, as run on the build host

Three builds at one `SOURCE_DATE_EPOCH`, against one `common` commit and one
parent layer, or the comparison means nothing. `bt-layer-measure capture`
takes `/run/lock/keel-build.lock` with a bounded wait, so it queues behind
another build instead of racing it (handbook `docs/traps.md`, "Two builds on
one host, and one lock").

    export FAB_PATH=/turnkey/fab-keel RELEASE=debian/trixie FAB_ARCH=amd64
    export BT_PATH=/turnkey/buildtasks-keel BT_PRODUCTS=$FAB_PATH/products
    export TKLBAM_PATH=/turnkey/tklbam-profiles-keel BT_GPGKEY=
    export SOURCE_DATE_EPOCH=1700000000
    M=/mnt/builds/measure/mariadb-$(date +%Y%m%d)

    # 1. the control: the recipe as it is on the default branch
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag control

    # 2. the unit: the same recipe with the component supplied through unit.d
    #    (check out the branch that does that, then)
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag unit

    # 3. the control again, from the same tree as step 1
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag control-again

    # 4. the result the pull request quotes
    $BT_PATH/bt-layer-measure attribute --dir $M \
        --control control --unit unit --control-again control-again

Step 4 prints one block. Paste it into the pull request whole: it names the
command, the three captures with their epoch and capture time, the noise
floor, the attributable count and the verdict, so a claim like "0 attributable
differences" says which command produced it and a reviewer can run that
command again.

Exit status: 0 when the verdict is PASS, 1 when it is FAIL, 2 on a usage
error, 3 when a capture, a build or a tool is missing.

## What a capture holds

`DIR/TAG/`, all tab separated and keyed on the path in field 1:

| File | Content |
|------|---------|
| `meta.tsv` | `key<TAB>value`: layer, parent, epoch, capture time, builder, buildtasks commit, the state path list and its digest |
| `pkgs.tsv` | `name<TAB>version` for the installed packages, from the rootfs's own dpkg database |
| `tree.tsv` | `path<TAB>sha256<TAB>size<TAB>mode` for every regular file |
| `links.tsv` | `path<TAB>target` for every symlink |
| `state.tsv` | `path<TAB>sampled\|too-large<TAB>size` for every state path |
| `state/` | the bytes of every sampled state path |
| `manifest.txt` | the layer manifest `bt-layer` wrote |
| `build.log` | the builder's output |

A tag is never overwritten. Re-measuring means a new tag or a new directory,
so the numbers a pull request quoted stay on disk next to the ones that
replaced them.

### Why a tab, and why the path comes first

`sha256sum` prints `<hash>` then two spaces then the path, and a Debian
rootfs contains `setuptools/_vendor/jaraco/text/Lorem ipsum.txt`. Anything
splitting that on whitespace gets two fields out of one path, which never
matches itself, so it is reported as differing in every pair including the
control against itself. That is handbook `docs/traps.md`, "A path with a space
in it"; it cost the LAMP measurement of 2026-09-27 one phantom file in each of
its two counts. A capture therefore keys on `path<TAB>...`, and refuses a path
containing a tab, a newline or a backslash rather than mis-counting it.

## State paths: the part that is not a subtraction

For the mariadb component the noise floor is 179 files, of which 173 are
`./var/lib/mysql/**`. That directory holds `mysql/global_priv` and
`mysql/user.*`, and the component's build-time job includes deleting accounts.
Subtracting the whole floor by path therefore made the measurement blind
exactly where the thing being measured would show up. A path is put inside the
noise floor by its name; whether its difference really is noise is a question
about its bytes, and nothing was asking it.

`share/layer-state-paths` lists the paths that can hold state that matters:
accounts, credentials, host keys, database directories. For those, `capture`
keeps the bytes and `attribute` compares them in both pairs and classifies
each one:

| Verdict | Meaning |
|---------|---------|
| `noise` | every difference between the control and the unit is one the control also shows against itself, at the same line or the same byte offset |
| `real` | it differs at a line or a byte offset the control pair does not, so the change is what differs, whatever the path is called |
| `unsampled` | the bytes were not kept on some side, so neither can be said |

`real` and `unsampled` both fail the run. `unsampled` fails on purpose: a
measurement that could not read a file must not pass as if the file were
unchanged. Either raise `--state-max-bytes` (the default is 16 MiB per file)
or say in the pull request why that path does not matter.

The comparison is per line for a text file and per byte offset for a binary
one, and the noise floor is subtracted at that level rather than per path. A
clock that moves in every build touches the same line or the same offset in
both pairs, so it cancels. A deleted account row leaves a line or an offset
the control pair never produces, so it is reported, with a three-way diff of
the control, the unit and the second control printed underneath.

## Layout

Logic in `bin/layer-measure-lib`, a thin main in `bt-layer-measure`, tests in
`tests/measure`, measured by `tests/coverage.sh` (Keel decisions 0003 and
0004). Nothing is built in the tests: the builder is a stub that copies a
fixture rootfs into place, so every capture the suite makes is a real capture
of a real tree, including a path with a space in it, a symlink whose target
has a space, a text state file, a binary state file and a state file above the
sample cap.
