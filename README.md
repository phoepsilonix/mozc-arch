# Build packages of Mozc for Arch
### Build
```sh
makepkg -sp PKGBUILD
```
or
```
makepkg -sp PKGBUILD.Dict
```

```sh
ls *.pkg.tar.zst
```

## Install
### Ibus-Mozc
```sh
sudo pacman -U ibus-*.pkg.tar.zst
```
### Fcitx5-Mozc
```sh
sudo pacman -U fcitx5-*.pkg.tar.zst
```
