#!/bin/sh

mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/include"

install -m 644 "${MESON_BUILD_ROOT}/$1.vapi" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
install -m 644 "${MESON_BUILD_ROOT}/$1.h" "${DESTDIR}${MESON_INSTALL_PREFIX}/include"
install -m 644 "${MESON_BUILD_ROOT}/$1@sha/$2" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
