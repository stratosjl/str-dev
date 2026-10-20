# str-dev

Arch Linux packages for software that upstream ships only as prebuilt tarballs.

## Packages

| Package | Version | Upstream | Folder | Status |
|---|---|---|---|---|
| `artcraft-launcher-bin` | 0.5.1 | [storytold/craft-launcher](https://github.com/storytold/craft-launcher) | `cases/artcraft/` | Archived 2026-10-20: use the AUR's [`craft-launcher-bin`](https://aur.archlinux.org/packages/craft-launcher-bin) |

An archived package is kept as it was last built and is not updated. The instructions below describe how it was built and maintained.

## Build and install

```sh
cd cases/artcraft
makepkg -si
```

`makepkg` downloads the release tarball, checks it against the SHA-256 in the PKGBUILD (taken from upstream's `SHA256SUMS.txt`) and installs the package with pacman. A tarball already sitting beside the PKGBUILD is used instead of downloading.

## Updating to a new upstream release

1. Set `pkgver` in the PKGBUILD and reset `pkgrel=1`.
2. Copy the new tarball's SHA-256 from the release's `SHA256SUMS.txt` into `sha256sums`.
3. Compare the new tarball with the old one: file layout, and the libraries the binary loads (`strings bin/<name> | grep -oE 'lib[A-Za-z0-9_+-]+\.so'`). Add any new library's owning package (`pacman -Qo`) to `depends`.
4. Check the programs the binary runs, such as `flatpak` and `pkexec` (`strings bin/<name> | grep -wE 'flatpak|pkexec|zenity'`, and the launcher's log after installing an app). Add each one's owning package to `optdepends`.
5. `makepkg -f`, `namcap` on the PKGBUILD and the package, then `makepkg --printsrcinfo > .SRCINFO`.

Update through pacman, not through the launcher's own "Update and restart" button, so pacman's file records stay correct.

The package installs upstream's binary as `/usr/lib/artcraft-launcher/artcraft-launcher` and a small wrapper as `/usr/bin/artcraft-launcher`. The wrapper adds the package revision to `--version` (`artcraft-launcher 0.5.1 (package artcraft-launcher-bin 0.5.1-3)`) and passes every other call to the binary unchanged. List any file the package adds beyond the tarball's in `_added`, so the file count against the tarball still adds up.

## Licence and trademarks

The packaging files in this repository (PKGBUILDs, `.SRCINFO` files and the push guard) are under the 0BSD licence, in `LICENSE`.

The launcher is MIT OR Apache-2.0. The ArtCraft name, logo and icons are trademarks of the ArtCraft Team and are not covered by those licences; the package installs them unmodified, as upstream ships them.
