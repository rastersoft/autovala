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
set (VERSION "0.28")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/autovalaLib/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/autovalaLib/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutoVala.pc ${CMAKE_CURRENT_BINARY_DIR}/AutoVala.pc)
set (VERSION "0.28")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.20" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} autovalaLib.vala)
set (APP_SOURCES ${APP_SOURCES} conditionalText.vala)
set (APP_SOURCES ${APP_SOURCES} configuration.vala)
set (APP_SOURCES ${APP_SOURCES} elementBase.vala)
set (APP_SOURCES ${APP_SOURCES} elementBinary.vala)
set (APP_SOURCES ${APP_SOURCES} elementCustom.vala)
set (APP_SOURCES ${APP_SOURCES} elementDBus.vala)
set (APP_SOURCES ${APP_SOURCES} elementData.vala)
set (APP_SOURCES ${APP_SOURCES} elementDefine.vala)
set (APP_SOURCES ${APP_SOURCES} elementDesktop.vala)
set (APP_SOURCES ${APP_SOURCES} elementDoc.vala)
set (APP_SOURCES ${APP_SOURCES} elementEosPlug.vala)
set (APP_SOURCES ${APP_SOURCES} elementGlade.vala)
set (APP_SOURCES ${APP_SOURCES} elementGlobal.vala)
set (APP_SOURCES ${APP_SOURCES} elementIcon.vala)
set (APP_SOURCES ${APP_SOURCES} elementIgnore.vala)
set (APP_SOURCES ${APP_SOURCES} elementInclude.vala)
set (APP_SOURCES ${APP_SOURCES} elementManpage.vala)
set (APP_SOURCES ${APP_SOURCES} elementPixmap.vala)
set (APP_SOURCES ${APP_SOURCES} elementPo.vala)
set (APP_SOURCES ${APP_SOURCES} elementScheme.vala)
set (APP_SOURCES ${APP_SOURCES} elementValaBinary.vala)
set (APP_SOURCES ${APP_SOURCES} genVapis.vala)
set (APP_SOURCES ${APP_SOURCES} globals.vala)
set (APP_SOURCES ${APP_SOURCES} readPkgconfig.vala)

if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DEBUG)
endif ()
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=AutoVala --gir AutoVala-0.0.gir )
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -X -O2 )
if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -g )
endif ()


vala_precompile(VALA_C AutoVala
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
OPTIONS
	${COMPILE_OPTIONS}
GENERATE_VAPI
	AutoVala
GENERATE_HEADER
	AutoVala
)

add_library(AutoVala SHARED ${VALA_C})

set_target_properties( AutoVala PROPERTIES
VERSION
	0.28
SOVERSION
	0 )

install(TARGETS
	AutoVala
LIBRARY DESTINATION
	lib/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.h
DESTINATION
	include/
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
	valadoc(AutoVala
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
