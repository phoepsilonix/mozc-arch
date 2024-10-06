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
SUDACHI_DATE=$(grep "^_sudachidict_date" $1/PKGBUILD|cut -f2 -d"=")
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
    sudo -u nonroot git clone --filter=tree:0 -b fcitx --mirror https://github.com/fcitx/mozc.git mozc
    cd mozc
    sudo -u nonroot git worktree add tmp
    sudo -u nonroot git worktree remove tmp
    sudo -u nonroot git branch -d tmp
    popd
    grep "^pkgrel" $1/PKGBUILD|cut -f2 -d"="
    PKG_REL=$(($(grep "^pkgrel" $1/PKGBUILD|cut -f2 -d"=")+1))
    echo $PKG_REL
    sudo -u nonroot sed -i 's|^pkgrel=.*$|pkgrel='"${PKG_REL}"'|' $1/PKGBUILD*
else
    echo "No change Detected."
fi
if [[ "$COMMIT" != "$FCITX5_MOZC_COMMIT" ]]; then
    sudo -u nonroot sed -i 's|^_mozc_commit=.*$|_mozc_commit='"${FCITX5_MOZC_COMMIT}"'|' $1/PKGBUILD*
    sudo -u nonroot sed -i 's|^_bcr_commit=.*$|_bcr_commit='"${BCR_COMMIT}"'|' $1/PKGBUILD*
    cd $1
    source PKGBUILD
    OLD_SHAS=(${sha512sums[@]})
    sudo -u nonroot updpkgsums
    source PKGBUILD
    NEW_SHAS=(${sha512sums[@]})
    i=0
    for SHA in ${OLD_SHAS[@]};
    do
      echo "Before: ${SHA}"
      echo "After: ${NEW_SHAS[$i]}"
      echo sudo -u nonroot sed -i "s|'${SHA}'|'${NEW_SHAS[$i]}'|" PKGBUILD*
      sudo -u nonroot sed -i "s|'${SHA}'|'${NEW_SHAS[$i]}'|" PKGBUILD*
      i=$(($i+1))
    done
    cd ..
    git commit -a -m "Fcitx5-Mozc Update($1): _mozc_commit=$FCITX5_MOZC_COMMIT"
    git diff HEAD~
    git log -2
fi
if [[ "$SudachiDict_DATE" != "$SUDACHI_DATE" ]];then
    sudo -u nonroot sed -i 's|^_sudachidict_date=.*$|_sudachidict_date='"${SudachiDict_DATE}"'|' $1/PKGBUILD*
    cd $1
    cp -a PKGBUILD{,.bak}
    cp -a PKGBUILD{.Dict,}
    source PKGBUILD
    OLD_SHAS=(${sha512sums[@]})
    sudo -u nonroot updpkgsums
    source PKGBUILD
    cp -a PKGBUILD{,.Dict}
    cp -a PKGBUILD{.bak,}
    NEW_SHAS=(${sha512sums[@]})
    i=0
    for SHA in ${OLD_SHAS[@]};
    do
      echo "Before: ${SHA}"
      echo "After: ${NEW_SHAS[$i]}"
      echo sudo -u nonroot sed -i "s|'${SHA}'|'${NEW_SHAS[$i]}'|" PKGBUILD*
      sudo -u nonroot sed -i "s|'${SHA}'|'${NEW_SHAS[$i]}'|" PKGBUILD*
      i=$(($i+1))
    done
    cd ..
    git commit -a -m "SudachiDict Update($1) _sudachidict_date=$SudachiDict_DATE"
    git diff HEAD~
    git log -2
fi