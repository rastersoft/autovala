### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/autovala_gedit")
set (GETTEXT_PACKAGE "autovala_gedit")
set (RELEASE_NAME "autovala_gedit")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "1.0.0")
set (TESTSRCDIR "${CMAKE_SOURCE_DIR}")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/autovalagedit.pc ${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.pc)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/autovalagedit.deps ${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.deps)
set (VERSION "1.0.0")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.24" MINIMUM)
include (ValaPrecompile)

if (OLD_GEDIT)
	set (VALA_PACKAGES ${VALA_PACKAGES} gedit)
endif ()
set (VALA_PACKAGES ${VALA_PACKAGES} AutoVala)
set (VALA_PACKAGES ${VALA_PACKAGES} AutovalaPlugin)
set (VALA_PACKAGES ${VALA_PACKAGES} atk)
set (VALA_PACKAGES ${VALA_PACKAGES} cairo)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-pixbuf-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-introspection-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtksourceview-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libpeas-1.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libxml-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)
set (VALA_PACKAGES ${VALA_PACKAGES} x11)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} gedit_plugin.vala)

if (NOT(OLD_GEDIT))
	set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_SOURCE_DIR}/src/vapis/gedit.vapi)
endif ()


if (LOCAL)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D LOCAL)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLOCAL " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DLOCAL " )
endif ()
if (OLD_GEDIT)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D OLD_GEDIT)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DOLD_GEDIT " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DOLD_GEDIT " )
endif ()
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=autovalagedit --gir autovalagedit-1.0.gir )

vala_precompile(VALA_C autovalagedit
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
OPTIONS
	${COMPILE_OPTIONS}
GENERATE_VAPI
	autovalagedit
GENERATE_HEADER
	autovalagedit
)

add_library(autovalagedit SHARED ${VALA_C})

set_target_properties( autovalagedit PROPERTIES
VERSION
	1.0.0
SOVERSION
	1 )

install(TARGETS
	autovalagedit
LIBRARY DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.h
DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.vapi
DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.deps
DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalagedit-1.0.gir
DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalagedit.pc
DESTINATION
	$HOME/.local/share/gedit/plugins/autovala
)
if(HAVE_VALADOC)
	valadoc(autovalagedit
		${CMAKE_BINARY_DIR}/valadoc/autovalagedit
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		${CMAKE_INSTALL_DATAROOTDIR}/doc/autovala_gedit
	)
endif()

install(CODE "MESSAGE (\"
************************************************
* Run 'sudo ldconfig' to complete installation *
************************************************

\") " )