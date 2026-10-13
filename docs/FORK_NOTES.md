# Fork notes

Maintainer notes for this fork of [blaise-io/acelink](https://github.com/blaise-io/acelink). Not user-facing documentation.

## Why this fork exists

The Ace Stream engine only ships as an x86_64 binary. The original app forced Docker to run a `linux/amd64` image, which relies on Rosetta. Future macOS releases will drop Rosetta, so this fork publishes a multi-arch image (`linux/amd64`, `linux/arm64`) where the engine runs through [box64](https://github.com/ptitSeb/box64) on arm64, and no longer forces `amd64`.

The original maintainer is not reviewing pull requests, so changes live here instead of upstream. The MIT license and the original copyright notice are kept, and the README credits Blaise Kal.

## What differs from upstream

- `Dockerfile` builds box64 on arm64 and runs the x86_64 engine through it.
- `DOCKER_DEFAULT_PLATFORM=linux/amd64` was removed from `Process.swift` and the Makefile.
- macOS deployment target is 12.0.
- The image is published to `ghcr.io/piazzean/acelink` (not Docker Hub). The workflow logs in with `GITHUB_TOKEN`, so no secret is needed.
- The update checker and release links point to `piazzean/acelink`.
- Issue templates are assigned to `piazzean`.

## Releasing

1. Set the new version in `VERSION`. Do not reuse a tag that exists upstream (2.1.0 and older).
2. `make build` bumps the version in `Info.plist` and the README, then archives the app. It rewrites every `x.y.z` in `README.md`, so keep only links that should follow the version there.
3. Create the DMG as `Ace.Link.<version>.dmg` (see `make release`; it also opens Finder and the releases page). The README download link depends on that exact filename.
4. Commit the `VERSION`, `Info.plist` and README changes and push to `master`.
5. On GitHub, create a release with tag `<version>` targeting `master` and attach the DMG. The tag must match `VERSION`, because the app pulls `ghcr.io/piazzean/acelink:<version>`.
6. Publishing the release triggers the workflow, which pushes both `:latest` and the version tag. This is the only trigger. A failed run can only be re-run from the Actions tab.
7. After the first build ever, set the GHCR package to Public (profile > Packages > acelink > Package settings > Change visibility). New packages are private by default.
8. Test the DMG on an Apple Silicon Mac, once the image build has finished.

The app is unsigned. The build is universal (x86_64 and arm64).

## Open decisions

- **Bundle ID.** Still `io.blaise.acelink` (`Info.plist`, `project.pbxproj`). Changing it resets users' saved settings and lets the fork install next to the original. Left unchanged on purpose.
- **Homebrew.** `brew install --cask ace-link` installs the original developer's release, and the README labels it that way. Option: a separate tap (`homebrew-acelink` repo with `Casks/ace-link.rb`, updated on each release). Not done.
- **Manual workflow runs.** The workflow has no `workflow_dispatch` trigger.
