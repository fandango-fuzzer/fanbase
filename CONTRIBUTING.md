# Contributing to Fanbase

Fanbase is a registry of [Fandango](https://fandango-fuzzer.github.io/) input specifications, and it
grows through pull requests. This page says how to write a spec, how to get it in, and what we check.

If you want to write a spec for a **new format**, please [open an issue](https://github.com/fandango-fuzzer/fanbase/issues/new/choose)
first: we may already have it in our queue, and we can tell you what we would like it to cover.

## What a spec is

A spec lives in `specs/<format>/<kind>/`:

```
specs/png/png-apng/png-apng.fan      the Fandango specification
specs/png/png-apng/metadata.yml      what it is, who wrote it, what it needs
```

The format's default spec is named after the format (`png`). Any other is `<format>-<what makes it different>`,
such as `png-apng`. `index.yml` is generated: never edit it, and run `fanbase reindex` (or `fanbase check`)
instead.

### `metadata.yml`

`description` is a line you write. `fanbase reindex` fills in `format`, `kind`, `fanbase`, `fandango` and
`requires`. The rest you write, and we ask for:

| key | |
|---|---|
| `description` | One line: what the spec produces, and what it leaves out. |
| `version` | A version number in quotes, like `'1.0'`. **Change it whenever you change the spec**: it is how users and our checks tell the new from the old. |
| `authors` | Who wrote it: names, or `{name: ..., orcid: ...}`. Keep the authors of a spec you build on. |
| `license` | The license of the spec, as an SPDX identifier. Contributions to this repository are under the Apache License 2.0 (see `LICENSE`); a spec made from someone else's work needs a license that allows that, and `source` saying what it was made from. |
| `source` | What it was made from: a URL, or a few words. |
| `extends` | Specs it builds on, see below. |
| `derived_from`, `derived_sha256` | The spec it was forked from, and the hash of its file at the time. `fanbase fork` writes these and `fanbase rebase` updates them. |
| `status` | `draft`, `stable` or `deprecated`. |
| `extensions`, `mime`, `reference`, `title` | The format's file name extensions, media type, specification, and name. |

The full list is in the [fanbase-cli README](https://github.com/fandango-fuzzer/fanbase-cli#metadatayml).

### Building on another spec

If your spec is a variant of one that exists, build on it instead of copying it. Say so in `metadata.yml`
(`extends: [png]`), `include("png/png.fan")` in the `.fan`, and redefine only what differs. This is what
lets a fix to `png` reach every variant, and what lets two people's work be combined. Specs of this
registry can extend each other; `fanbase deps png --reverse` shows what builds on a spec.

## How to contribute

Fork and clone this repository, install the tools, and from inside the clone:

```shell
$ pip install --upgrade fandango-fuzzer fanbase
$ fanbase new png-fancy --extends png --description "..."     # or: fanbase fork png-apng --as png-apng-mine
$ $EDITOR specs/png/png-fancy/png-fancy.fan
$ fanbase check                                               # does each spec still produce inputs?
$ fanbase publish                                             # branch, commit, push, pull request
```

or do the same with `git` and `gh` by hand. Either way, before you open the pull request:

1. `fanbase check` passes. It also runs for every pull request here, and fails if `index.yml` or a
   `metadata.yml` is out of date, if a spec extends something that does not exist or a version that is not
   there, or if a spec makes Fandango produce no input.
2. A spec you **changed** has a **new `version`**.
3. A spec you **added** has a `description`, `authors` and `license`.
4. If it is based on someone else's work, `source` says whose, and its license allows this.

We review the pull request; expect questions about structure and coverage. We would rather have a spec
that is valid and well documented than one that covers everything.

## Keeping a fork up to date

`fanbase fork` remembers which spec yours was made from, and its hash at the time. When the original has
changed since, `fanbase rebase png-fancy` merges its changes into yours. It uses `git merge-file`, so a conflict
looks like git's: fix it, and run `fanbase check`, which refuses a spec that still has one. Then give the fork a
new `version`. `--dry-run` says whether it would merge cleanly.

## What not to put in a spec or a pull request

Fanbase comes with [considerations about ethics](ETHICS.md), and they apply to contributions:

- **No concrete bug-triggering inputs**, and no descriptions of an unfixed vulnerability. A spec describes a
  format abstractly. If you have found a bug with Fanbase, report it to the maintainers of the affected
  software first, as responsible disclosure asks; please do not mention it in an issue or pull request here
  until it is fixed.
- Only test systems you are allowed to test.

## Questions

Open an [issue](https://github.com/fandango-fuzzer/fanbase/issues/new/choose). For anything else, see
"Contact us" in the [README](README.md).
