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

set (VERSION "0.7.0")
pkg_check_modules(DEPS REQUIRED
	gee-1.0
	glib-2.0
	gtk+-3.0
)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)

set(VALA_PACKAGES
	posix
	gee-1.0
	glib-2.0
	gtk+-3.0
)

set(APP_SOURCES
	configuration.vala
	cmake.vala
	autovala.vala
	generate.vala
)

set(CUSTOM_VAPIS_LIST
)

vala_precompile(VALA_C autovala
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
)

add_executable(autovala ${VALA_C})

install(TARGETS
	autovala
RUNTIME DESTINATION
	bin/
)

if(HAVE_VALADOC)
	valadoc(autovala
		${CMAKE_BINARY_DIR}/valadoc/autovala
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		share/doc/autovala
	)
endif()
