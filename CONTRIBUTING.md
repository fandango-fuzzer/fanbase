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
| `decodes` | How often its files should be accepted by a parser: `always`, `mostly`, `rarely` or `never`. Many specs exist to make files that do not decode (say so); `fanbase evaluate` reports against it. |
| `targets` | The parsers to evaluate it against, if not those of its format (`specs/<format>/format.yml`). |
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
3. A spec you **added** has a `description`, `authors` and `license`, and says in `decodes` how often its files
   should be accepted by a parser.
4. If it is based on someone else's work, `source` says whose, and its license allows this.

We review the pull request; expect questions about structure and coverage. We would rather have a spec
that is valid and well documented than one that covers everything.

## How your spec does against real parsers

`fanbase evaluate png-fancy` produces inputs from your spec and asks the parsers of its format (the targets in
`targets/`, named in `specs/<format>/format.yml`) about each: how many it accepts, why it rejects the others, and how
fast the inputs come. Every pull request that changes a spec runs it for that spec and for what builds on it, and
shows the result in the job summary of the run; nothing in it fails the pull request. It reads best with a few
parsers in mind: a parser that rejects a file may lack a feature, and a file that none accepts may be what the spec
is for, so tell us in `decodes`. A parser that crashes or hangs on your inputs is counted, and is not named in the
public summary; if you see it yourself, treat it as the responsible disclosure above says.

`fanbase evaluate --coverage` goes further for the formats whose parsers are built to be measured (`coverage/`, run in
its image): it says how much of the library's code your spec's files run, how that grows from the first file to the
thousandth, and what they run that real files of the format do not, and the reverse. Once a week the same is measured
for every spec (`quality.yml`), together with how often each parser accepts its files and how fast they are made, and kept
as `quality.json` with the latest release: `fanbase list png --quality` shows it, and it is what to look at when choosing
between two grammars of one format. A curve that is flat from the first file says the spec makes files that are all alike.

The same evaluation runs on `main` for every spec, after each merge and once a week. There, the details of a crash
or a hang (the input, what the parser said, how to make the file again) are kept in one file that is encrypted to a
public key in [`.github/incident-recipients.txt`](.github/incident-recipients.txt), so that only the maintainer who
reports vulnerabilities can read it, and it is the same size whether or not anything broke. A pull request never
produces one, and nothing about a crash or a hang is ever in a public log, summary or comment. You do not have to do
anything for this; if you add a target, it runs in a job that has no secrets (see [`targets/`](targets/README.md)).

## Forking a spec that builds on others

`fanbase fork png-apng --as png-apng-mine` copies the one spec, and it keeps building on the originals. If you want
to change what it builds on too, add `--with-deps`: the whole family is copied (each under its own name, with its
own `derived_from`), and the copies build on each other instead. In a registry of your own this is also how you move
a spec of someone else's registry that builds on its neighbours.

## A DOI for a spec

A stable spec can have a [DOI](https://zenodo.org), so that it can be cited exactly as it was: `fanbase doi png-apng` says what
would be published, `--sandbox` tries it, and `--production` publishes it (Zenodo records are permanent, so it asks) and writes
`doi:` into the spec's `metadata.yml` for you to commit. It is up to the spec's authors; nothing here needs it.

## Keeping a fork up to date

`fanbase fork` remembers which spec yours was made from, and its hash at the time. When the original has
changed since, `fanbase rebase png-fancy` merges its changes into yours. It uses `git merge-file`, so a conflict
looks like git's: fix it, and run `fanbase check`, which refuses a spec that still has one. Then give the fork a
new `version`. `--dry-run` says whether it would merge cleanly.

If the original also changed what it `extends`, or its Fandango range, pip packages or file types, `rebase` offers to
adopt those too (your own additions stay); `--metadata adopt` says yes in advance, `--metadata keep` says no.

## Signing the index (maintainers)

Specs are code, so a user can ask that the registry's index be signed by a key they trust (`fanbase registry add URL --signer
KEY`); the index holds the hash of every spec, so the signature covers them all. To sign: keep the signing key off the
repository and off CI (ideally a hardware key, `ssh-keygen -t ed25519-sk`), and, at a release, `fanbase reindex && fanbase
sign --key KEY`, then commit `index.yml.sig` with the index before tagging (`release.yml` tags on the 1st of each month if the registry
changed, and when asked: sign before then, since a release whose signature does not match its index cannot be read verified). A signature does not move with the registry:
between a merge and the next signing, `main` is not signed, so users who want it verified read a release
(`fanbase --registry https://github.com/fandango-fuzzer/fanbase/tree/<tag>`). For a release to be checked by every
client without being asked, the public key goes into `DEFAULT_SIGNERS` in fanbase-cli's `signing.py`: that is how it reaches users from
somewhere other than the registry it signs. It applies to a release or a commit (`.../tree/<tag>`), never to `main`, which is
not signed between merges. Never put the private key in a secret of this repository.

The key that signs the releases is `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJlNdLap2I550dZDJB6NT3Db9gijDDRk+F2BczsrloXH`, fingerprint
`SHA256:mBALMSMJxkD+RjdVZWwFnHBSc+9FIEnM4xwrgTBb/rQ`. It is in fanbase-cli, so that `fanbase --registry
https://github.com/fandango-fuzzer/fanbase/tree/<tag> verify` needs no key from the user, and anyone can check a fingerprint
against this one. (A fingerprint is only worth the places it is published in: it should be on the project's site and in its
paper too, not only here.)

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
