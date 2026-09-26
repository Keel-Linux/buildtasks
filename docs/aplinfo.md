# bt-aplinfo: the Proxmox appliance index

`pveam update` on a Proxmox VE host downloads `aplinfo.dat.gz` and
`aplinfo.dat.asc` from each source hardcoded in pve-manager
(`PVE::APLInfo::get_apl_sources`), verifies the signature with `sqv` against
its own trusted keyring, and parses the file. `bt-aplinfo` writes that file
for Keel templates. Being listed by `pveam` still needs pve-manager to carry
our host and key; until then the index is consumed by `keel-pve` on the
Proxmox host (see `docs/proxmox-distribution.md` in the Keel repository).

## Usage

    bt-aplinfo [-u|--url BASE_URL] [-o|--output DIR] template...

The templates are the files `keel assemble` produces, with the `.sha512`
file next to each one. Example, indexing two templates for a host reached
over IPv6 and signing with the build key:

    export BT_GPGKEY=<fingerprint of the signing subkey>
    bt-aplinfo -u "http://[2001:db8::1]/pve/" -o /var/www/pve \
        /turnkey/builds/templates/debian-13-keel-core_19.1-1_amd64.tar.zst \
        /turnkey/builds/templates/debian-13-keel-lamp_19.1-1_amd64.tar.zst

Output in the directory (default `$BT_BUILDS/aplinfo`):

| File | Content |
|------|---------|
| `aplinfo.dat` | the index, one record per template, records separated by a blank line |
| `aplinfo.dat.gz` | `gzip -n -9` of the index (no name, no timestamp: same input, same bytes) |
| `aplinfo.dat.asc` | armored detached signature over `aplinfo.dat`, only when `BT_GPGKEY` is set |

Without `BT_GPGKEY` the script prints a warning and writes no `.asc`, and
removes a stale one, because pveam refuses an index it cannot verify. The
signing subkey is pending (Keel decision 0005), so every index produced today
is unsigned and says so.

## The record

One record per template, fields in the order TurnKey publishes them:

    Package: keel-core
    Version: 19.1-1
    Type: lxc
    OS: debian-13
    Section: keellinux
    Architecture: amd64
    Location: https://releases.keellinux.org/pve/debian-13-keel-core_19.1-1_amd64.tar.zst
    Infopage: https://keellinux.org/core
    ManageUrl: http://__IPADDRESS__/
    sha512sum: 3f2a...128 hex characters
    Description: Keel Core
     Keel Core - Debian 13 with batteries included

Where each value comes from:

- `Package`, `Version`, `OS`, `Architecture`: parsed from the template file
  name (below).
- `Location`: the base URL (`--url`, default
  `https://releases.keellinux.org/pve/`) plus the template file name.
- `Infopage`: `https://keellinux.org/<app>` (`APLINFO_INFOPAGE_BASE` in the
  environment overrides the base).
- `sha512sum`: computed from the template; when a `.sha512` sidecar exists it
  must agree, so a template rebuilt without its sidecar is caught.
- `Description` and its continuation line: from the product directory
  `$BT_PRODUCTS/<app>` (or `$BT_PRODUCTS/keel-<app>`): a `pve-description`
  file (first line the headline, the remaining lines the continuation) or,
  failing that, the title line of `README.rst`, where the text before ` - `
  is the headline. Add a `pve-description` to a product when the README
  title is not what should appear in the Proxmox dialog.
- The `changelog` of the product is read for the version of its newest
  entry; a mismatch with the template version is reported as a warning.

Every record is validated before the index is assembled: all fields present,
`Type` is `lxc`, `Version` in the `<ver>-<rev>` shape pveam parses, a 128
hex character `sha512sum`, a `Location` ending in an accepted template
extension, a non-empty `Description` with one continuation line, no blank
line inside.

## Template file name

    debian-13-keel-<app>_<version>-<revision>_<arch>.tar.zst

for example `debian-13-keel-core_19.1-1_amd64.tar.zst`. This is the shape
`PVE::APLInfo` builds itself (`<os>-<package>_<version>_<arch>`) when a
record has no `Location`, with the package prefix `keel-` and the `.tar.zst`
`keel assemble` writes. The `.sha512` sidecar has the same name plus
`.sha512`.

### .tar.zst versus .tar.gz

TurnKey's index lists 111 `.tar.gz` templates; Proxmox's own
`aplinfo-pve-9.dat` lists 10 `.tar.zst`, 16 `.tar.xz` and one `.tar.gz`
(counted on 2026-09-26), so `.tar.zst` is already what the download dialog
serves for Proxmox's templates. What decides whether pveam accepts a
Location, verified the same day against the upstream sources:

- pve-storage `src/PVE/Storage.pm` line 118 defines the accepted template
  extensions:
  `our $VZTMPL_EXT_RE_1 = qr/\.(?|(tar)(?!\.)|tar\.(gz|xz|zst|bz2))/i;`
- pve-manager `PVE/APLInfo.pm` (`read_aplinfo_from_fh`) derives the template
  name from `Location` with that regex:
  `$template =~ s|.*/([^/]+$PVE::Storage::VZTMPL_EXT_RE_1)$|$1|;`
  and stores the record under that name.
- pve-manager `PVE/API2/Nodes.pm` (`apl_download`) downloads
  `$appliance->{location}` to `$tmpldir/$template` and checks it against
  `sha512sum` (`PVE::Tools::download_file_from_url` with `hash_required`).
- pve-storage `src/PVE/Storage/Plugin.pm` lists and parses `vztmpl` volumes
  with the same regex (`parse_volname`, `template_list`), so `pct create`
  sees a `.tar.zst` like any other template.

So `.tar.zst`, `.tar.gz`, `.tar.xz`, `.tar.bz2` and plain `.tar` are all
accepted, and there is no need for a `.tar.gz` switch: `bt-aplinfo` indexes
whatever extension the template carries, as long as it is one of these.

## Library

The logic lives in `bin/aplinfo-lib`, sourced by the script and by
`tests/aplinfo`; the script is the thin main. Functions:
`aplinfo_template_name`, `aplinfo_parse_template_name`, `aplinfo_location`,
`aplinfo_sha512`, `aplinfo_product_dir`, `aplinfo_changelog_version`,
`aplinfo_description`, `aplinfo_record_render`, `aplinfo_record_validate`,
`aplinfo_assemble`, `aplinfo_gzip`, `aplinfo_sign`, `aplinfo_parse_args`.
Each reads its arguments, prints to stdout and returns non-zero with a
message on stderr.

## Tests

    tests/aplinfo          # scratch templates, throwaway signing key
    tests/coverage.sh 99   # both suites under kcov

The test generates an Ed25519 key in a scratch `GNUPGHOME`, signs the index
and verifies it with `sqv` when installed (the tool pveam uses), otherwise
with `gpg --verify`. A parser check splits the produced file on blank lines
and asserts every key pveam reads in every record, in the TurnKey order.
