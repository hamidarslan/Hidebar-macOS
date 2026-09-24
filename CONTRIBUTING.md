# Contributing

## Development setup

Use a Mac with macOS 14 or newer and a Swift 6 toolchain (Xcode or Command Line Tools).

These are developer requirements only. Users download a self-contained app from Releases without installing build tools.

```sh
git clone https://github.com/hamidarslan/Hidebar-macOS.git
cd Hidebar-macOS
./script/test.sh
./script/build_and_run.sh
```

For contributions, fork this repository and open a pull request. Maintainers need an authenticated Git client to push; never put a token in source or a remote URL.

## Workflow for future ideas

1. Open an issue describing the problem, expected behavior, and a concrete acceptance check.
2. Start from updated `main`: `git switch main` then `git pull --ff-only`.
3. Create a focused branch: `git switch -c feature/short-description` (or `fix/short-description`).
4. Implement the change, update relevant documentation, and add an entry under `Unreleased` in `CHANGELOG.md`.
5. Run the geometry tests and the applicable manual checks in [TESTING.md](docs/TESTING.md).
6. Commit focused changes, push the branch, and open a pull request against `main`.
7. Review the diff and CI before merging. Preserve version tags; fix problems in a new commit/version.

Keep `main` buildable. Do not force-push shared history. Repository rules require pull requests, passing build checks, and resolved review threads for main, and protect branch history and version tags against rewriting or deletion.

## Conventions

- Use native SwiftUI/AppKit APIs, minimal dependencies, and focused diffs.
- Keep geometry logic in `HidebarCore` so it can be tested independently.
- All status-item and window work runs on the main actor.
- Do not change other applications' preferences or request broad permissions without a reviewed feature design.
- Never commit signing keys, tokens, personal paths, derived data, or generated app bundles.
- Update `VERSION` and the changelog together when cutting a release; see [RELEASING.md](docs/RELEASING.md).

Contributions are provided under the repository's [license](LICENSE).
