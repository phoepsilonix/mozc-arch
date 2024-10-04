# Build packages of Mozc with SudachiDict for Arch
### Build
#### Normal
```sh
makepkg -sp PKGBUILD
```
#### with SudachiDict
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
