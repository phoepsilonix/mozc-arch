#!/bin/bash

set -x
#SudahiDict
SudachiDict_DATE=$(curl -s 'http://sudachi.s3-website-ap-northeast-1.amazonaws.com/sudachidict-raw/' | grep -o '<td>[0-9]*</td>' | grep -o '[0-9]*' | sort -n | tail -n 1)

#ORIGINAL_REPO=fcitx/mozc
#https://github.com/bazelbuild/bazel-central-registry.git#commit=$
BCR_REPO=bazelbuild/bazel-central-registry
ORIGINAL_REPO=$(grep "^url" $1/PKGBUILD | tr -d '"' | sed -e 's|.*com/\(.*\)$|\1|' -e 's|.git$||')
FCITX5_MOZC_COMMIT=$(curl -s https://api.github.com/repos/$ORIGINAL_REPO/commits/fcitx|jq -r ".sha")
BCR_COMMIT=$(curl -s https://api.github.com/repos/$BCR_REPO/commits/main|jq -r ".sha")
echo $FCITX5_MOZC_COMMIT
echo $SudachiDict_DATE
echo $BCR_COMMIT

# PKGBUILD
COMMIT=$(grep "^_mozc_commit" $1/PKGBUILD|cut -f2 -d"=")
SUDACHI_DATE=$(grep "^_sudachidict_date" $1/PKGBUILD.Dict|cut -f2 -d"=")
echo $COMMIT
echo $SUDACHI_DATE

UPDATED_FLAG=0
if [[ "$COMMIT" != "$FCITX5_MOZC_COMMIT" ]]; then
    echo "Mozc Updated."
    echo "$COMMIT"
    echo "$FCITX5_MOZC_COMMIT"
    UPDATED_FLAG=1
fi
if [[ "$SudachiDict_DATE" != "$SUDACHI_DATE" ]];then
    echo "SudachiDict Updated."
    echo "${SUDACHI_DATE}"
    echo "${SudachiDict_DATE}"
    UPDATED_FLAG=1
fi
if [[ "$UPDATED_FLAG" == "1" ]]; then
    echo "Change Detected."
    pushd .
    cd $1
    sudo -u nonroot git clone --filter=tree:0 --mirror https://github.com/fcitx/mozc.git mozc
    cd mozc
    sudo -u nonroot git worktree add tmp
    sudo -u nonroot git worktree remove tmp
    sudo -u nonroot git branch -d tmp
	cd ..
	sudo -u nonroot git clone mozc src/mozc
	cd src/mozc
	sudo -u nonroot git checkout fcitx
	source <(grep = src/data/version/mozc_version_template.bzl| tr -d ' ')
	PKG_VER=$(printf "%s.%s.%s.%s" "$MAJOR" "$MINOR" "$BUILD_OSS" "$((REVISION+2))")
    popd
    PKG_REL=$(($(grep "^pkgrel" $1/PKGBUILD|cut -f2 -d"=")+1))
    echo $PKG_REL
    sudo -u nonroot sed -i 's|^pkgrel=.*$|pkgrel='"${PKG_REL}"'|' $1/PKGBUILD*
    PKG_VER_=$(grep "^pkgver=" $1/PKGBUILD|cut -f2 -d"=")
	echo $PKG_VER
	echo $PKG_VER_
	if [[ "$PKG_VER" != "$PKG_VER_" ]];then
    	sudo -u nonroot sed -i 's|^pkgver=.*$|pkgver='"${PKG_VER}"'|' $1/PKGBUILD*
    	sudo -u nonroot sed -i 's|^pkgrel=.*$|pkgrel='"1"'|' $1/PKGBUILD*
	fi
else
    echo "No change Detected."
fi
if [[ "$SudachiDict_DATE" != "$SUDACHI_DATE" ]];then
    sudo -u nonroot sed -i 's|^_sudachidict_date=.*$|_sudachidict_date='"${SudachiDict_DATE}"'|' $1/PKGBUILD*
    cd $1
    eval $(sudo -u nonroot makepkg -g -p PKGBUILD.Dict)
    #mapfile -t sha512sums < <(sudo -u nonroot makepkg -g -p PKGBUILD.Dict | sed "s/sha512sums=(//" | sed "s/)$//" | tr -d "'")
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD.Dict ${sha512sums[@]}
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD.fcitx.Dict ${sha512sums[@]}
    cd ..
    git commit -a -m "SudachiDict Update($1) _sudachidict_date=$SudachiDict_DATE"
    git diff HEAD~
    git log -2
fi
if [[ "$COMMIT" != "$FCITX5_MOZC_COMMIT" ]]; then
    cd $1
    sudo -u nonroot sed -i 's|^_mozc_commit=.*$|_mozc_commit='"${FCITX5_MOZC_COMMIT}"'|' PKGBUILD*
    sudo -u nonroot sed -i 's|^_bcr_commit=.*$|_bcr_commit='"${BCR_COMMIT}"'|' PKGBUILD*
    eval $(sudo -u nonroot makepkg -gde --noprepare -p PKGBUILD)
    #mapfile -t sha512sums < <(sudo -u nonroot makepkg -g -p PKGBUILD | sed "s/sha512sums=(//" | sed "s/)$//" | tr -d "'")
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD ${sha512sums[@]}
    eval $(sudo -u nonroot makepkg -gdoe --noprepare -p PKGBUILD.fcitx)
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD.fcitx ${sha512sums[@]}
    eval $(sudo -u nonroot makepkg -gdoe --noprepare -p PKGBUILD.Dict)
    #mapfile -t sha512sums < <(sudo -u nonroot makepkg -g -p PKGBUILD.Dict | sed "s/sha512sums=(//" | sed "s/)$//" | tr -d "'")
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD.Dict ${sha512sums[@]}
    eval $(sudo -u nonroot makepkg -gdoe --noprepare -p PKGBUILD.fcitx.Dict)
    sudo -u nonroot ../update_sha512sums.sh PKGBUILD.fcitx.Dict ${sha512sums[@]}
    cd ..
    git commit -a -m "Fcitx5-Mozc Update($1): _mozc_commit=$FCITX5_MOZC_COMMIT"
    git diff HEAD~
    git log -2
fi
