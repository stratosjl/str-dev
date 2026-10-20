# artcraft-launcher-bin (archived)

Archived on 2026-10-20 at 0.5.1-4. It will not be updated for later upstream releases.

Use the AUR's [`craft-launcher-bin`](https://aur.archlinux.org/packages/craft-launcher-bin) instead. It packages the same prebuilt release for x86_64 and aarch64, installs the binary as `artcraft-launcher` with a `craft-launcher` link, and declares the libraries the binary loads at run time.

The two packages conflict, so pacman offers to replace one with the other. This package's `--version` wrapper and the `polkit`, `noto-fonts-cjk` and `xdg-desktop-portal` optional dependencies are not in `craft-launcher-bin`; install those three yourself if you want them.

The PKGBUILD stays here as a record and still builds 0.5.1.
