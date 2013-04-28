### CMakeLists automatically created with AutoVala
### Do not edit

if(${CMAKE_INSTALL_PREFIX} MATCHES usr/local/? )
	set( AUTOVALA_INSTALL_PREFIX "/usr/local")
else()
	set( AUTOVALA_INSTALL_PREFIX "/usr")
endif()

STRING (REPLACE "/" ";" AUTOVALA_PATH_LIST ${CMAKE_INSTALL_PREFIX})
SET (FINAL_AUTOVALA_PATH "")

FOREACH(element ${AUTOVALA_PATH_LIST})
	IF (${FOUND_USR})
		SET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}/.. )
	ELSE()
		IF(${element} STREQUAL "usr")
			SET(FOUND_USR 1)
			SET(FINAL_AUTOVALA_PATH ${FINAL_AUTOVALA_PATH}.. )
		ENDIF()
	ENDIF()
ENDFOREACH()

set (DATADIR "${AUTOVALA_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/autovala")
set (GETTEXT_PACKAGE "autovala")
set (RELEASE_NAME "autovala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "0.17")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/gedit_plugin/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/gedit_plugin/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutoVala_gedit.pc ${CMAKE_CURRENT_BINARY_DIR}/AutoVala_gedit.pc)
set (VERSION "0.17")
add_definitions(${DEPS_CFLAGS})
include_directories( ${CMAKE_BINARY_DIR}/src/autovala_lib )
link_libraries( ${DEPS_LIBRARIES} -lAutoVala )
link_directories( ${DEPS_LIBRARY_DIRS} ${CMAKE_BINARY_DIR}/src/autovala_lib )
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.20" MINIMUM)
include(ValaPrecompile)

set(VALA_PACKAGES
	PeasGtk-1.0
	libpeas-1.0
	gee-1.0
	glib-2.0
	gedit
	gtk+-3.0
)

set(APP_SOURCES
	${CMAKE_CURRENT_BINARY_DIR}/Config.vala
	plugin.vala
)

set(CUSTOM_VAPIS_LIST
	${CMAKE_BINARY_DIR}/src/autovala_lib/AutoVala.vapi
)

vala_precompile(VALA_C AutoVala_gedit
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
OPTIONS
	--library=AutoVala_gedit --gir AutoVala_gedit-0.0.gir 
GENERATE_VAPI
	AutoVala_gedit
GENERATE_HEADER
	AutoVala_gedit
)

add_library(AutoVala_gedit SHARED ${VALA_C})

set_target_properties( AutoVala_gedit PROPERTIES
VERSION
	0.17
SOVERSION
	0 )

install(TARGETS
	AutoVala_gedit
LIBRARY DESTINATION
	${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala_gedit.h
DESTINATION
	${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala_gedit.vapi
DESTINATION
	${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala_gedit-0.0.gir
DESTINATION
	${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala_gedit.pc
DESTINATION
	${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins/
)
if(HAVE_VALADOC)
	valadoc(AutoVala_gedit
		${CMAKE_BINARY_DIR}/valadoc/AutoVala_gedit
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
