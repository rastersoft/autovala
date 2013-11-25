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
set (PKGDATADIR "${DATADIR}/cronopete")
set (GETTEXT_PACKAGE "cronopete")
set (RELEASE_NAME "cronopete")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "0.26")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
set (VERSION "0.26")
add_definitions(${DEPS_CFLAGS})
link_libraries( ${DEPS_LIBRARIES} )
link_directories( ${DEPS_LIBRARY_DIRS} )
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.18" MINIMUM)
include(ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementIgnore.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementBase.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementPixmap.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementDoc.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/globals.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/gen_pkgconfig.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/gen_vapis.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementDefine.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementBinary.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementIcon.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementPo.vala)
set (APP_SOURCES ${APP_SOURCES} autovala.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/configuration.vala)
set (APP_SOURCES ${APP_SOURCES} autovala_lib/elementData.vala)

vala_precompile(VALA_C cronopete
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
)

add_executable(cronopete ${VALA_C})

install(TARGETS
	cronopete
RUNTIME DESTINATION
	bin/
)

if(HAVE_VALADOC)
	valadoc(cronopete
		${CMAKE_BINARY_DIR}/valadoc/cronopete
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		share/doc/cronopete
	)
endif()
