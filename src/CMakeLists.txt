### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/autovala")
set (GETTEXT_PACKAGE "autovala")
set (RELEASE_NAME "autovala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
find_package(PkgConfig)

set (VERSION "1.0.0")
pkg_check_modules(DEPS REQUIRED
	gio-2.0
	gee-1.0
	gtk+-3.0
)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)

vala_precompile(VALA_C
	cmake.vala
	autovala.vala
	generate.vala
	configuration.vala
PACKAGES
	gio-2.0
	gee-1.0
	gtk+-3.0
	posix
OPTIONS
	-X -O2
)

add_executable(autovala ${VALA_C})

install(TARGETS
	autovala
RUNTIME DESTINATION
	bin/
)

