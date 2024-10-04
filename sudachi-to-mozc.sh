#!/bin/bash

git clone --filter=tree:0 --single-branch https://github.com/phoepsilonix/mozcdict-ext.git
cd mozcdict-ext/sudachi
_sudachidict_date=$(curl -s 'http://sudachi.s3-website-ap-northeast-1.amazonaws.com/sudachidict-raw/' | grep -o '<td>[0-9]*</td>' | grep -o '[0-9]*' | sort -n | tail -n 1)
curl -LO "http://sudachi.s3-website-ap-northeast-1.amazonaws.com/sudachidict-raw/${_sudachidict_date}/small_lex.zip"
curl -LO "http://sudachi.s3-website-ap-northeast-1.amazonaws.com/sudachidict-raw/${_sudachidict_date}/core_lex.zip"
curl -LO "http://sudachi.s3-website-ap-northeast-1.amazonaws.com/sudachidict-raw/${_sudachidict_date}/notcore_lex.zip"
unzip small_lex.zip
unzip core_lex.zip
unzip notcore_lex.zip

cat small_lex.csv core_lex.csv notcore_lex.csv > sudachi.csv
rm *lex.csv
rustup target list --installed | grep $(rustc -vV | sed -e 's|host: ||' -e 's|-gnu||p' -n) | grep musl && TARGET=$(rustup target list --installed | grep $(rustc -vV | sed -e 's|host: ||' -e 's|-gnu||p' -n)|grep musl|head -n1) || TARGET=$(rustup target list --installed | grep $(rustc -vV | sed -e 's|host: ||' -e 's|-gnu||p' -n)|grep -v musl|head -n1)
echo "TARGET=$TARGET"
cargo build --release --target $TARGET
./target/$TARGET/release/dict-to-mozc -s -i ../../source/src/data/dictionary_oss/id.def -f sudachi.csv > ./all-dict.txt
awk -f dup.awk all-dict.txt > finish-dict.txt
