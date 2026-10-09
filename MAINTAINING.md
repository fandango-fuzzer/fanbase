# Maintaining the registry's settings (GitHub and Zenodo)

What an admin of `fandango-fuzzer/fanbase` sets up once, and why. The workflows in `.github/workflows/` assume it.
Commands are for the `gh` command line, logged in as an admin (`gh auth status`).

## 1. The workflow token: read by default

Workflows ask for the permissions they need, job by job. The default for any that does not should be to read:

```bash
gh api -X PUT repos/fandango-fuzzer/fanbase/actions/permissions/workflow -f default_workflow_permissions=read
```

## 2. The secrets: an Environment that only `main` can use

The mail jobs of `evaluate-main.yml` and `quality.yml` use the Environment `incidents`, so that a workflow started on
any other branch cannot read the secrets that are in it.

```bash
echo '{"deployment_branch_policy":{"protected_branches":false,"custom_branch_policies":true}}' | gh api -X PUT repos/fandango-fuzzer/fanbase/environments/incidents --input -
gh api -X POST repos/fandango-fuzzer/fanbase/environments/incidents/deployment-branch-policies -f name=main -f type=branch
```

The Environment holds `INCIDENT_EMAIL`, `FANBASE_SMTP_HOST`, `FANBASE_SMTP_USER` and `FANBASE_SMTP_FROM` (and `FANBASE_SMTP_PORT`
if it is not 465):

```bash
gh secret set FANBASE_SMTP_HOST --env incidents --repo fandango-fuzzer/fanbase --body smtp.gmail.com
```

**`FANBASE_SMTP_PASSWORD` is still a secret of the repository, not of the Environment.** A job that uses an Environment sees the
repository's secrets too, so the mail jobs work, but so does a workflow that someone with write access starts on another branch.
It is the app password of a Gmail account that only sends these mails, and what they carry is encrypted; that is why it has not
been moved yet. Do move it when more people get write access. A Gmail app password cannot be read back, so make a new one
(https://myaccount.google.com/apppasswords), copy it to the clipboard (never type it into a command), and:

```bash
export FANBASE_SMTP_PASSWORD="$(pbpaste | tr -d ' ')"; printf %s "$FANBASE_SMTP_PASSWORD" | gh secret set FANBASE_SMTP_PASSWORD --env incidents --repo fandango-fuzzer/fanbase
```

Clear the clipboard and `unset` the variable afterwards. Then remove the secrets of the same names from the repository itself, so
that only the Environment has them: `gh secret delete NAME --repo fandango-fuzzer/fanbase`, and revoke the old app password.

## 3. GitHub Pages (`site.yml`)

```bash
gh api -X POST repos/fandango-fuzzer/fanbase/pages -f build_type=workflow
```

The site is then at https://fandango-fuzzer.github.io/fanbase/ after the first run of `site.yml`.

## 4. The image of `coverage/` (`coverage-image.yml`, `quality.yml`)

Public packages must be allowed for the organization: github.com/organizations/fandango-fuzzer/settings/packages, "Package
creation": public. After the first run of `coverage-image.yml`, the package `fanbase-coverage` is under the organization's
packages (it is linked to this repository by the label in the Dockerfile); open it, Package settings, "Change visibility",
Public. Until then `quality.yml` cannot pull it.

## 5. Zenodo (`.zenodo.json`, `release.yml`)

Zenodo archives each published GitHub release of an enabled repository, as a record with a DOI that is permanent. Do it
on the sandbox first (sandbox.zenodo.org: the same, with records and DOIs that mean nothing), then on zenodo.org:

1. Log in with GitHub at zenodo.org (and sandbox.zenodo.org), Account, GitHub.
2. The organization has to allow Zenodo to see its repositories: github.com/organizations/fandango-fuzzer/settings/oauth_application_policy,
   approve Zenodo. Then "Sync now" on Zenodo's GitHub page.
3. Switch the repository `fandango-fuzzer/fanbase` on. The sandbox first.
4. Make a release (see 6). Look at the record on the sandbox: the title, the creator (The Fandango Fuzzer Team), the license, the
   description. Only when it is right, switch the repository on at zenodo.org, before the next release: a release made before is
   not archived there.

`.zenodo.json` says what the record says. There is no `CITATION.cff` (what GitHub's "Cite this repository" shows) until the paper is accepted.

## 6. A release

`release.yml` publishes one on the 1st of each month if the registry changed, and on request (Actions, release, Run workflow).
The index is signed first, by hand (see CONTRIBUTING.md): `fanbase reindex && fanbase sign --key ~/.fanbase-secrets/fanbase-signing`,
commit `index.yml.sig`, then the release is made. A release whose signature does not match is refused by clients, so
`release.yml` checks it against the maintainer's key (the one built into fanbase) and fails, without releasing, if the
index is not signed or was changed after it was signed. A failed run on the 1st of a month means: sign, then run it again.

A run started by hand (Actions, release, Run workflow) has the option **force**: it releases even if nothing changed since the
last release, for a milestone such as the version a paper cites. The index must still be signed, and with Zenodo switched on the
release is archived under a permanent DOI, so look before you tick it.

### The order of a release

A release is made in this order, and each step runs only if the one before passed:

1. **decide**: what changed since the last release, the tag, and that the index is signed (above);
2. **tests**: `check.yml`, the registry is in order and every spec makes Fandango produce inputs;
3. **quality**: `quality.yml`, every spec measured against the parsers (all of them again: `refresh`), about 45 minutes, with the mail of the private record;
4. **site**: `site.yml`, built with the numbers of step 3 and deployed with GitHub Pages;
5. **release**: the GitHub release, with `quality.json` attached.

The release is last because Zenodo archives it, permanently, the moment it is published. It is not made as a draft first, since
Zenodo also reacts to the `created` event that saving a draft sends. The numbers do not hold a release back (a spec whose files a
parser does not accept as often as its `decodes` says is something to read in the report); a step that fails does.

To try a change to `release.yml` or the workflows it calls, run it by hand with **dry_run** ticked (and, say, `count` 30 and
`budget` 15): it does steps 1 to 3 and builds the site, and neither deploys the site nor makes a release. On a branch other than
`main` the mail of the private record is skipped too, since the Environment `incidents` is only for `main`.

## 7. The weekly quality run, and what it does not measure again

`quality.yml` runs on Sundays (and by hand) with **one fixed seed** and `fanbase evaluate --reuse` on the `quality.json` of the
latest release: a spec that nothing it depends on has changed for since then is not measured again, and its earlier result is
kept. What a result depends on is a hash stored with it (`fingerprint`): the spec and everything it extends, each target that
judges it (its files and the version the parser reports), Fandango's and fanbase's versions, and the settings. So a week in which
nothing changed takes minutes, and a week in which one spec changed measures that spec, and the ones that build on it.

- **A release measures everything again** (`refresh: yes`, set by `release.yml`), since the fingerprint does not know the Python
  packages a spec imports, nor anything about the machine that no version string says. Run `quality.yml` by hand with **refresh**
  set to `yes` to do the same without a release.
- **The seed is fixed on purpose.** It is part of the fingerprint: a seed that changed every week would make every spec a change
  every week. Hunting for crashes needs new inputs, and that is `evaluate-main.yml`'s job: its seed changes every week, and it is
  the run that keeps the encrypted private record.
- **The first run after an upgrade of fanbase measures everything**, since fanbase's version is part of the fingerprint.
- The stamp `fanbase: x.y.z` in `metadata.yml` and `index.yml` is the version that last ran `reindex`. The checks ignore it, so
  it does not have to follow each release of fanbase, and changing it changes `index.yml`, which has to be signed again.
