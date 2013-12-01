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
set (VERSION "0.26.0")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (VERSION "0.26.0")
add_definitions (${DEPS_CFLAGS})
include_directories ( ${CMAKE_BINARY_DIR}/src/autovalaLib )
link_libraries ( ${DEPS_LIBRARIES} -lAutoVala )
link_directories ( ${DEPS_LIBRARY_DIRS} ${CMAKE_BINARY_DIR}/src/autovalaLib )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.20" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} autovala.vala)

set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_BINARY_DIR}/src/autovalaLib/AutoVala.vapi)

if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DEBUG)
endif ()
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -X -O2 )
if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -g )
endif ()


vala_precompile(VALA_C autovala
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
OPTIONS
	${COMPILE_OPTIONS}
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
