# Build packages of Mozc with SudachiDict for Arch
### Build
#### Normal
```sh
sudo pacman -Rs fcitx fcitx-qt6
makepkg -osC -p PKGBUILD
makepkg -e -p PKGBUILD
```
#### with SudachiDict
```
sudo pacman -Rs fcitx fcitx-qt6
makepkg -osC -p PKGBUILD.Dict
makepkg -e -p PKGBUILD.Dict
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
