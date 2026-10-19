# str-dev

Arch Linux packages for software that upstream ships only as prebuilt tarballs.

## Packages

| Package | Version | Upstream | Folder |
|---|---|---|---|
| `artcraft-launcher-bin` | 0.5.1 | [storytold/craft-launcher](https://github.com/storytold/craft-launcher) | `cases/artcraft/` |

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
4. `makepkg -f`, `namcap` on the PKGBUILD and the package, then `makepkg --printsrcinfo > .SRCINFO`.

Update through pacman, not through the launcher's own "Update and restart" button, so pacman's file records stay correct.

## Licence and trademarks

The launcher is MIT OR Apache-2.0. The ArtCraft name, logo and icons are trademarks of the ArtCraft Team and are not covered by those licences; the package installs them unmodified, as upstream ships them.
