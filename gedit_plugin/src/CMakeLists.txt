### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/valaplugin")
set (GETTEXT_PACKAGE "valaplugin")
set (RELEASE_NAME "valaplugin")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "1.0.0")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutovalaGeditPlugin.pc ${CMAKE_CURRENT_BINARY_DIR}/AutovalaGeditPlugin.pc)
set (VERSION "1.0.0")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} AutoVala)
set (VALA_PACKAGES ${VALA_PACKAGES} AutovalaPlugin)
set (VALA_PACKAGES ${VALA_PACKAGES} atk)
set (VALA_PACKAGES ${VALA_PACKAGES} cairo)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-pixbuf-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gedit)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-introspection-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtksourceview-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libpeas-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)
set (VALA_PACKAGES ${VALA_PACKAGES} x11)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} valaplugin.vala)

if (OLD_GEDIT)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D OLD_GEDIT)
endif ()
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=AutovalaGeditPlugin --gir AutovalaGeditPlugin-1.0.gir )

vala_precompile(VALA_C AutovalaGeditPlugin
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
OPTIONS
	${COMPILE_OPTIONS}
GENERATE_VAPI
	AutovalaGeditPlugin
GENERATE_HEADER
	AutovalaGeditPlugin
)

add_library(AutovalaGeditPlugin SHARED ${VALA_C})

set_target_properties( AutovalaGeditPlugin PROPERTIES
VERSION
	1.0.0
SOVERSION
	1 )

install(TARGETS
	AutovalaGeditPlugin
LIBRARY DESTINATION
	share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaGeditPlugin.h
DESTINATION
	share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaGeditPlugin.vapi
DESTINATION
	share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaGeditPlugin-1.0.gir
DESTINATION
	share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaGeditPlugin.pc
DESTINATION
	share/gedit/plugins/autovala
)
if(HAVE_VALADOC)
	valadoc(AutovalaGeditPlugin
		${CMAKE_BINARY_DIR}/valadoc/AutovalaGeditPlugin
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		share/doc/valaplugin
	)
endif()

install(CODE "MESSAGE (\"
************************************************
* Run 'sudo ldconfig' to complete installation *
************************************************

\") " )