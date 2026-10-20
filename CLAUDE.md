---
tier: T4
---

# str-dev: project snapshot

Arch Linux packages for software shipped upstream as prebuilt tarballs. See `README.md` for the package list and the update procedure.

## Two repositories, one folder

- **This repo is PUBLIC** (`github.com/stratosjl/str-dev`). It holds packaging only: `README.md`, `CLAUDE.md`, `LICENSE` (0BSD), `.gitignore`, `bin/public-push-guard.sh`, and per package `cases/<name>/PKGBUILD` and `.SRCINFO`.
- **Session records live in `private/`**, a separate PRIVATE repo cloned into this folder and ignored here. Read `private/README.md` at session open: it holds the decision log, open issues, change log, handovers and the memory store.
- **`bin/public-push-guard.sh` runs as the pre-push hook** and refuses a push that carries any path outside the allowlist, any term from `private/deny-patterns.txt`, or an author or committer address other than the GitHub no-reply one. It fails closed when the pattern file is missing. Install it in a fresh clone with `ln -s ../../bin/public-push-guard.sh .git/hooks/pre-push`.
- Commits here use the GitHub no-reply address, set in the local git config. Never commit here with a personal or work address.

## Irreversible or outward actions (confirmation gate)

Ask the operator before any of these, even when a tool would succeed silently:

1. Any push to this public repo, and any change to either repo's visibility.
2. Force-push, history rewrite, or branch deletion in either repo.
3. Creating, renaming, transferring or deleting a GitHub repo.
4. Installing, upgrading or removing a system package (`pacman -U`, `-R`).
5. Changing machine-wide configuration outside this folder.
6. Deleting a downloaded tarball or a built package (they are kept by policy).

## Conventions

- Markdown is one line per block.
- A new upstream release is packaged through the PKGBUILD and installed with pacman, never through the program's own updater.
- The checksum in a PKGBUILD is copied from upstream's published checksum list, never computed from a download alone.
