# Fork Patches Manifest

Tracks active **A0 same-version republishes** from this fork to our local Verdaccio. See [`docs/adr/ADR-0002`](../../docs/adr/) in the `fork-restart` meta-repo for the full publishing/versioning decision.

## How A0 works

When an upstream package is broken (or we want to ship any patch), we:

1. Edit source in this fork (or accept current source as-is for broken-publish cases).
2. Push the appropriate per-package tag — e.g. `git tag sona-v0.1.6 && git push origin sona-v0.1.6`.
3. Upstream's per-package CD (`sona-napi.yml` etc., unchanged in our fork) builds and publishes to our Verdaccio via the `.npmrc` redirect.
4. **Same version number** is used — Verdaccio's "local wins" semantics shadows the upstream tarball for consumers caret-resolving via our registry.
5. Add an entry to this file documenting the patch.

## Drift handling

`scripts/check-fork-drift.sh` (scheduled daily via `.github/workflows/check-fork-drift.yml`) reads this file and compares each patched version to upstream's current `latest`. When upstream bumps past one of our patches, the workflow fails with a `DRIFT:` line; per ADR-0002, decide per-event:

- **Re-patch** at the new upstream version (forward-port the fix)
- **Drop** the patch (upstream's new version carries the fix)
- **No action** (patch remains valid; record the decision in the entry below)

When a patch is dropped, remove its entry. When re-patched, update the version field in place.

## Active patches

(none currently)

## Entry format

```
- @ruvector/sona@0.1.6 — broken publish (missing index.js); republished from current source on YYYY-MM-DD. Drop when upstream's next sona-v* publish includes the dispatcher.
- @ruvector/cli@0.1.29 — bin file dist/cli.js missing in upstream tarball; republished YYYY-MM-DD.
```

Each entry: `- <package>@<patched-version> — <reason>; republished <date>. <drop/keep guidance>`.

The drift detector matches the regex `^-\s+([@a-zA-Z0-9/.-]+)@([0-9a-zA-Z.+-]+)\s+` against each line.
