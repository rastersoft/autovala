### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/autovala")
set (GETTEXT_PACKAGE "autovala")
set (RELEASE_NAME "autovala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "0.99")
set (TESTSRCDIR "${CMAKE_SOURCE_DIR}")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/autovalaPlugin/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/autovalaPlugin/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutovalaPlugin.pc ${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.pc)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutovalaPlugin.deps ${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.deps)
set (VERSION "0.99")
add_definitions (${DEPS_CFLAGS})
include_directories ( ${CMAKE_BINARY_DIR}/src/autovalaLib )
link_libraries ( ${DEPS_LIBRARIES} -lAutoVala )
link_directories ( ${DEPS_LIBRARY_DIRS} ${CMAKE_BINARY_DIR}/src/autovalaLib )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.20" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} atk)
set (VALA_PACKAGES ${VALA_PACKAGES} cairo)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-pixbuf-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gtk+-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)
set (VALA_PACKAGES ${VALA_PACKAGES} x11)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} PanedPercentage.vala)
set (APP_SOURCES ${APP_SOURCES} actionbuttons.vala)
set (APP_SOURCES ${APP_SOURCES} fileview.vala)
set (APP_SOURCES ${APP_SOURCES} outputview.vala)
set (APP_SOURCES ${APP_SOURCES} projectview.vala)
set (APP_SOURCES ${APP_SOURCES} searchview.vala)

set (CUSTOM_VAPIS_LIST ${CUSTOM_VAPIS_LIST} ${CMAKE_BINARY_DIR}/src/autovalaLib/AutoVala.vapi)

if (GTK_OLD)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D GTK_OLD)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DGTK_OLD " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DGTK_OLD " )
endif ()
if (DEBUG)
	set (COMPILE_OPTIONS ${COMPILE_OPTIONS} -D DEBUG)
	set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDEBUG " )
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DDEBUG " )
endif ()
set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=AutovalaPlugin --gir AutovalaPlugin-0.0.gir )

vala_precompile(VALA_C AutovalaPlugin
	${APP_SOURCES}
PACKAGES
	${VALA_PACKAGES}
CUSTOM_VAPIS
	${CUSTOM_VAPIS_LIST}
OPTIONS
	${COMPILE_OPTIONS}
GENERATE_VAPI
	AutovalaPlugin
GENERATE_HEADER
	AutovalaPlugin
)

add_library(AutovalaPlugin SHARED ${VALA_C})

set_target_properties( AutovalaPlugin PROPERTIES
VERSION
	0.99
SOVERSION
	0 )

set (INSTALL_LIBRARY_AutovalaPlugin ${CMAKE_INSTALL_LIBDIR} )
set (INSTALL_INCLUDE_AutovalaPlugin ${CMAKE_INSTALL_INCLUDEDIR} )
set (INSTALL_VAPI_AutovalaPlugin ${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/ )
set (INSTALL_GIR_AutovalaPlugin ${CMAKE_INSTALL_DATAROOTDIR}/gir-1.0/ )
set (INSTALL_PKGCONFIG_AutovalaPlugin ${CMAKE_INSTALL_LIBDIR/pkgconfig} )

install(TARGETS
	AutovalaPlugin
LIBRARY DESTINATION
	${INSTALL_LIBRARY_AutovalaPlugin}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.h
DESTINATION
	${INSTALL_INCLUDE_AutovalaPlugin}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.vapi
DESTINATION
	${INSTALL_VAPI_AutovalaPlugin}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.deps
DESTINATION
	${INSTALL_VAPI_AutovalaPlugin}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin-0.0.gir
DESTINATION
	${INSTALL_GIR_AutovalaPlugin}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutovalaPlugin.pc
DESTINATION
	${INSTALL_PKGCONFIG_AutovalaPlugin}/
)
if(HAVE_VALADOC)
	valadoc(AutovalaPlugin
		${CMAKE_BINARY_DIR}/valadoc/AutovalaPlugin
		${APP_SOURCES}
	PACKAGES
		${VALA_PACKAGES}
	CUSTOM_VAPIS
		${CUSTOM_VAPIS_LIST}
	)
	install(DIRECTORY
		${CMAKE_BINARY_DIR}/valadoc
	DESTINATION
		${CMAKE_INSTALL_DATAROOTDIR}/doc/autovala
	)
endif()
