# bt-layer-measure: the three-build comparison

Handbook decision 0010 accepts splitting components out of the shared `common`
tree on one condition, stated in step 3 of its order of work: components move
one at a time, "re-running this three-build comparison for each, including the
control-vs-control run". This is that comparison. Before this script existed
the capture half was a scratch file in root's home directory on the build host
and the comparison half was never written down, so two component extractions
(keel-mariadb#11, keel-postgresql#7) were approved on a number only their
author could produce.

## Why three builds, and why four is better

Two builds of the *same* recipe are not identical. They differ in install-time
state: clocks, log lines, Perl hash order, a database data directory created
when a conf script starts the server. That set is the **noise floor**, and it
is the only reason a build of a *changed* recipe is allowed to differ from the
control at all. Without a second control build there is nothing to subtract,
so no difference can be attributed to the change, which is what the third
build is for.

The floor is not a fixed set either. On the mariadb captures of 2026-09-27 one
control pair differs by 179 files and another by 182, and the count
attributable to the unit form is **3** against the first pair and **0**
against the second. A single pair therefore decides the verdict by accident.
`--control-again` is repeatable, the floor is the union over every pair of
controls, and the block prints what each single pair would have said so the
swing is visible rather than lucky.

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
    export BT_BUILDS=/mnt/builds
    export SOURCE_DATE_EPOCH=1700000000

`BT_BUILDS` is the one `bt-layer` refuses to run without, and it is not in
root's environment on the build host. `bt-layer-measure` reads
`$BT_PATH/config/common.cfg` the way `bt-layer` does, so the default of
`/mnt/builds` applies either way, but exporting it keeps the command honest
about what it depends on.
    M=/mnt/builds/measure/mariadb-$(date +%Y%m%d)

    # 1. the control: the recipe as it is on the default branch
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag control

    # 2. the unit: the same recipe with the component supplied through unit.d
    #    (check out the branch that does that, then)
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag unit

    # 3. the control again, from the same tree as step 1
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag control-again

    # 3b. a third control, because one control pair is not a floor
    $BT_PATH/bt-layer-measure capture --dir $M --layer mariadb --parent core --tag control-third

    # 4. the result the pull request quotes
    $BT_PATH/bt-layer-measure attribute --dir $M --unit unit \
        --control control --control-again control-again \
        --control-again control-third [--cleared waivers.tsv]

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
| `state-paths.txt` | the state path list this capture was taken against |
| `manifest.txt` | the layer manifest `bt-layer` wrote |
| `build.log` | the builder's output |

A tag is never overwritten. Re-measuring means a new tag or a new directory,
so the numbers a pull request quoted stay on disk next to the ones that
replaced them.

**Retention.** A capture holds byte-for-byte copies of `/etc/shadow`, of host
keys and of database files. `capture` creates the directory `0700` and `cp`
preserves each file's own mode, but nothing expires them: a capture directory
is as sensitive as the image it came from. Keep it on the build host, off any
shared filesystem, and delete it once the pull request it supports is merged.
A `mariadb` capture with the cap raised past `ib_logfile0` is about 150 MiB,
so four of them are roughly 600 MiB.

`attribute` reads the state path list from the captures, never from the
environment. The list is what decides which bytes were kept, so a run cannot
be made to look clean afterwards by pointing `MEASURE_STATE_PATHS` at a
narrower file: all the captures must carry the same list, and their recorded
digests must match it.

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
accounts, credentials, host keys, database directories, `/etc/machine-id`.
For those, `capture` keeps the bytes and `attribute` classifies each one.

### A position is not enough

The first version of this tool compared *positions*: the line numbers or byte
offsets at which two files differ, subtracting one set from another. That
cancels a real difference against a coincidental one at the same place. All
four of these were reported as noise, with the evidence suppressed because
they were noise:

- an account added to `/etc/shadow` at the line number the control pair also
  appends at,
- a root password set on the line the control pair rewrites for a clock
  reason,
- a binary differing at the same eight offsets as the control pair, with
  different byte values,
- a file 3584 bytes shorter, against a control pair that varies by one byte.

So the controls are the model, and the model has content in it. At each
position the controls vary at, the longest common prefix and suffix of their
variants is the *shape* of that variation, and the unit is admitted only if
its line has that shape. `# written 1790475089` against `# written 1790475323`
gives the shape `# written ...`, which `# written 1790475511` fits and
`root:$y$hash:...` does not.

| Verdict | Meaning | Run |
|---------|---------|-----|
| `noise` | every differing line is at a position the controls vary at and has the shape they vary with there | passes |
| `overlapping` | it coincides with the controls' variation but cannot be shown to be that variation | **fails** unless cleared |
| `real` | it differs where the controls do not vary, or with content or a magnitude they never show | **fails** |
| `not sampled` | no bytes were kept on some side | **fails** |
| `unchanged` | the path differs in mode only; the bytes are identical | passes |

A binary is never `noise`. Bytes carry no shape: a timestamp and an account
record look the same at the byte level, so the most that can be said is that
the unit coincides with the controls in position, in size delta and in how
much differs. That is `overlapping`, and it fails until somebody reads the
bytes and says so in `--cleared`. For mariadb that is the honest answer for
`/var/lib/mysql/**`, which is 173 of the 179 files in the floor and holds
`mysql/global_priv` and `mysql/user.*`.

A mask with neither a prefix nor a suffix is what two unrelated lines have in
common, which is no evidence about a third, so it never yields `noise` either.

`not sampled` fails on purpose: a measurement that could not read a file must
not pass as if the file were unchanged. Raise `--state-max-bytes` (default
16 MiB per file) or clear the path in writing.

### Waivers

`--cleared FILE` takes lines of `PATH<TAB>REASON`, and `PATH` may be a glob,
because a real data directory is 173 files that one sentence explains:

    ./var/lib/mysql/**	InnoDB and Aria creation stamps, read byte by byte on 2026-09-28

A waiver clears `overlapping` and nothing else: it cannot clear a `real`
difference. Every path a waiver covered is named in the block, so a reviewer
sees what was waived and on what grounds, and the file itself is committed
next to the component.

### What the floor removed

Every path the floor subtracted that is *not* a state path is named in the
block, not just counted, because 176 subtracted paths as a single number told
the reviewer of this tool's first version nothing. Any of them whose name
looks like state (`share/layer-state-suspect`: `*shadow*`, `*passwd*`,
`*.pem`, `*.key`, `*machine-id*` and so on) fails the run, with two ways out
and both of them committed: add the path to `share/layer-state-paths` so its
bytes are compared, or clear it with a reason. State at a path nobody listed
is the original defect relocated, so the list is treated as a failure mode
rather than as a list.

### Preconditions

`attribute` refuses to run unless the captures share their `layer`, `parent`
and `SOURCE_DATE_EPOCH`, were built with an epoch at all, carry the same state
path list, and are distinct from one another. The note this implements says
those must hold "or nothing the comparison prints means anything"; recording
them and never checking them is the same as not recording them.

## What it said about mariadb, 2026-09-28

The first real use, four captures on the build host, `SOURCE_DATE_EPOCH`
1700000000, `core` as parent, three of them controls. The block is
reproducible from `/mnt/builds/measure/mariadb-gate`.

    attributable differences: 0
    (also 0 against each single control pair)
    state paths the unit pair differs at: 167
      noise 102, overlapping 33, real 32, not sampled 0
    subtracted as floor noise, and not state paths: 6
    verdict: FAIL (0 attributable, 32 real, 33 overlapping and uncleared)

Zero attributable, which is what the experiment in decision 0010 concluded,
now against the union of three control pairs rather than one. What is new is
the 167 state paths, which that measurement subtracted by name without
opening.

The 32 called `real` are almost all Aria index files, `*.MAI`, and the reason
is worth knowing before the next component is measured: the Aria index header
carries a Unix timestamp, and in 30 of the 32 it increases strictly in capture
order. Three control builds moved only its low bytes; the unit build, four
minutes later, carried into the byte above. So the difference is a clock whose
carry three controls did not span. The evidence block prints the bytes from
every capture at the first differing offset, in capture order, which is what
makes that readable rather than a list of offsets:

          the 8 bytes at offset 181, in capture order:
            control       b9 fe 1a 00 00 00 00 00
            control       b9 fe c6 00 00 00 00 00
            control       b9 ff 64 00 00 00 00 00
            unit          ba 00 04 00 00 00 00 00

The 33 called `overlapping` are almost all `*.frm`, whose create and update
timestamps sit at fixed offsets that every build moves together.

`mysql/user.frm` is the one that came out `noise`, and correctly: `mysql.user`
is a view over `global_priv`, its `.frm` really is a text file, and its only
difference between builds is one `timestamp=` line that the mask the three
controls establish there admits.

This FAIL is the honest state of that measurement and not a defect in the
component. Reaching PASS needs a decision that is not the tool's to make:
either more control captures, until the floor spans the counter's carry, or a
committed `--cleared` waiver saying the Aria header clock was read and
accepted. Both are on the record; silently subtracting 167 paths was not.

## Layout

Capture and formats in `bin/layer-measure-lib`, the verdicts in
`bin/layer-compare-lib`, the blocks and the preconditions in
`bin/layer-report-lib`, a thin main in `bt-layer-measure`. Tests in
`tests/measure` and `tests/compare`, measured by `tests/coverage.sh` (Keel
decisions 0003 and 0004). Nothing is built in the tests: the builder is a stub that copies a
fixture rootfs into place, so every capture the suite makes is a real capture
of a real tree, including a path with a space in it, a symlink whose target
has a space, a text state file, a binary state file and a state file above the
sample cap.
