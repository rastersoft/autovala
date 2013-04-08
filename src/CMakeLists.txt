### CMakeLists automatically created with AutoVala
### Do not edit

if(${CMAKE_INSTALL_PREFIX} MATCHES usr/local/? )
	set( INSTALL_PREFIX "/usr/local")
else()
	set( INSTALL_PREFIX "/usr")
endif()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/autovala")
set (GETTEXT_PACKAGE "autovala")
set (RELEASE_NAME "autovala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "0.11.0")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (VERSION "0.11.0")
add_definitions(${DEPS_CFLAGS})
include_directories( ${CMAKE_BINARY_DIR}/src/autovala_lib )
link_libraries( ${DEPS_LIBRARIES} -lAutoVala )
link_directories( ${DEPS_LIBRARY_DIRS} ${CMAKE_BINARY_DIR}/src/autovala_lib )
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)
include(ValaPrecompile)

set(VALA_PACKAGES
	posix
	gee-1.0
	glib-2.0
)

set(APP_SOURCES
	${CMAKE_CURRENT_BINARY_DIR}/Config.vala
	autovala.vala
)

set(CUSTOM_VAPIS_LIST
	${CMAKE_BINARY_DIR}/src/autovala_lib/AutoVala.vapi
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
