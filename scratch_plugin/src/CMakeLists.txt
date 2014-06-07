### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/scratch_plugin")
set (GETTEXT_PACKAGE "scratch_plugin")
set (RELEASE_NAME "scratch_plugin")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "1.0.0")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/autovalascratch.pc ${CMAKE_CURRENT_BINARY_DIR}/autovalascratch.pc)
set (VERSION "1.0.0")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.24" MINIMUM)
include (ValaPrecompile)

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
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)
set (VALA_PACKAGES ${VALA_PACKAGES} scratchcore)
set (VALA_PACKAGES ${VALA_PACKAGES} x11)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} scratch_plugin.vala)

set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=autovalascratch --gir autovalascratch-1.0.gir )

vala_precompile(VALA_C autovalascratch
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
OPTIONS
	${COMPILE_OPTIONS}
GENERATE_VAPI
	autovalascratch
GENERATE_HEADER
	autovalascratch
)

add_library(autovalascratch SHARED ${VALA_C})

set_target_properties( autovalascratch PROPERTIES
VERSION
	1.0.0
SOVERSION
	1 )

install(TARGETS
	autovalascratch
LIBRARY DESTINATION
	lib/scratch/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalascratch.h
DESTINATION
	lib/scratch/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalascratch.vapi
DESTINATION
	lib/scratch/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalascratch-1.0.gir
DESTINATION
	lib/scratch/plugins/autovala
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/autovalascratch.pc
DESTINATION
	lib/scratch/plugins/autovala
)
if(HAVE_VALADOC)
	valadoc(autovalascratch
		${CMAKE_BINARY_DIR}/valadoc/autovalascratch
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		${CMAKE_INSTALL_DATAROOTDIR}/doc/scratch_plugin
	)
endif()

install(CODE "MESSAGE (\"
************************************************
* Run 'sudo ldconfig' to complete installation *
************************************************

\") " )