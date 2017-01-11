#!/bin/sh

mkdir -p $DESTDIR/$MESON_INSTALL_PREFIX/$2
if [ $1 -eq '2' ]; then
pandoc ${MESON_SOURCE_ROOT}/$3 -o - -f $4 -t man -s | gzip - > $MESON_INSTALL_DESTDIR_PREFIX/$2/$5.gz
else
cat ${MESON_SOURCE_ROOT}/$3 | gzip - > $MESON_INSTALL_DESTDIR_PREFIX/$2/$5.gz
fi
