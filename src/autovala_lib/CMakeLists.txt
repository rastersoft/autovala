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

set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/autovala_lib/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/autovala_lib/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutoVala.pc ${CMAKE_CURRENT_BINARY_DIR}/AutoVala.pc)
set (VERSION "0.10")
add_definitions(${DEPS_CFLAGS})
link_libraries( ${DEPS_LIBRARIES} )
link_directories( ${DEPS_LIBRARY_DIRS} )
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
	generate.vala
)

set(CUSTOM_VAPIS_LIST
)

vala_precompile(VALA_C AutoVala
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
OPTIONS
	--library=AutoVala --gir AutoVala-0.0.gir 
GENERATE_VAPI
	AutoVala
GENERATE_HEADER
	AutoVala
)

add_library(AutoVala SHARED ${VALA_C})

set_target_properties( AutoVala PROPERTIES
VERSION
	0.10
SOVERSION
	0 )

install(TARGETS
	AutoVala
LIBRARY DESTINATION
	lib/autovala/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.h
DESTINATION
	include/autovala/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.vapi
DESTINATION
	share/vala/vapi/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala-0.0.gir
DESTINATION
	share/gir-1.0/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.pc
DESTINATION
	lib/pkgconfig/
)
if(HAVE_VALADOC)
	valadoc(autovala
		${CMAKE_BINARY_DIR}/valadoc/AutoVala
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
