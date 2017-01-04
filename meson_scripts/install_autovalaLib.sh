#!/bin/sh

mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
mkdir -p "${DESTDIR}${MESON_INSTALL_PREFIX}/include"

install -m 644 "${MESON_BUILD_ROOT}/AutoVala.vapi" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/vala/vapi"
install -m 644 "${MESON_BUILD_ROOT}/AutoVala.h" "${DESTDIR}${MESON_INSTALL_PREFIX}/include"
install -m 644 "${MESON_BUILD_ROOT}/AutoVala@sha/AutoVala-1.0.gir" "${DESTDIR}${MESON_INSTALL_PREFIX}/share/gir-1.0"
