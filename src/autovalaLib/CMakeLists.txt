### CMakeLists automatically created with AutoVala
### Do not edit

set (DATADIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")
set (PKGDATADIR "${DATADIR}/autovala")
set (GETTEXT_PACKAGE "autovala")
set (RELEASE_NAME "autovala")
set (CMAKE_C_FLAGS "")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (VERSION "1.0")
set (TESTSRCDIR "${CMAKE_SOURCE_DIR}")
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/src/autovalaLib/Config.vala.cmake ${CMAKE_BINARY_DIR}/src/autovalaLib/Config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutoVala.pc ${CMAKE_CURRENT_BINARY_DIR}/AutoVala.pc)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/AutoVala.deps ${CMAKE_CURRENT_BINARY_DIR}/AutoVala.deps)
set (VERSION "1.0")
add_definitions (${DEPS_CFLAGS})
link_libraries ( ${DEPS_LIBRARIES} )
link_directories ( ${DEPS_LIBRARY_DIRS} )
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.30" MINIMUM)
include (ValaPrecompile)

set (VALA_PACKAGES ${VALA_PACKAGES} posix)
set (VALA_PACKAGES ${VALA_PACKAGES} readline)
set (VALA_PACKAGES ${VALA_PACKAGES} cairo)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-3.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gdk-pixbuf-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gee-0.8)
set (VALA_PACKAGES ${VALA_PACKAGES} gio-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} glib-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} gobject-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} libxml-2.0)
set (VALA_PACKAGES ${VALA_PACKAGES} pango)
set (VALA_PACKAGES ${VALA_PACKAGES} pangocairo)

set (APP_SOURCES ${APP_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
set (APP_SOURCES ${APP_SOURCES} autovalaLib.vala)
set (APP_SOURCES ${APP_SOURCES} conditionalText.vala)
set (APP_SOURCES ${APP_SOURCES} configuration.vala)
set (APP_SOURCES ${APP_SOURCES} elementAppData.vala)
set (APP_SOURCES ${APP_SOURCES} elementBDepend.vala)
set (APP_SOURCES ${APP_SOURCES} elementBase.vala)
set (APP_SOURCES ${APP_SOURCES} elementBashCompletion.vala)
set (APP_SOURCES ${APP_SOURCES} elementBinary.vala)
set (APP_SOURCES ${APP_SOURCES} elementCustom.vala)
set (APP_SOURCES ${APP_SOURCES} elementDBus.vala)
set (APP_SOURCES ${APP_SOURCES} elementData.vala)
set (APP_SOURCES ${APP_SOURCES} elementDefine.vala)
set (APP_SOURCES ${APP_SOURCES} elementDesktop.vala)
set (APP_SOURCES ${APP_SOURCES} elementDoc.vala)
set (APP_SOURCES ${APP_SOURCES} elementEosPlug.vala)
set (APP_SOURCES ${APP_SOURCES} elementExternal.vala)
set (APP_SOURCES ${APP_SOURCES} elementGResource.vala)
set (APP_SOURCES ${APP_SOURCES} elementGlade.vala)
set (APP_SOURCES ${APP_SOURCES} elementGlobal.vala)
set (APP_SOURCES ${APP_SOURCES} elementIcon.vala)
set (APP_SOURCES ${APP_SOURCES} elementIgnore.vala)
set (APP_SOURCES ${APP_SOURCES} elementInclude.vala)
set (APP_SOURCES ${APP_SOURCES} elementManpage.vala)
set (APP_SOURCES ${APP_SOURCES} elementPixmap.vala)
set (APP_SOURCES ${APP_SOURCES} elementPo.vala)
set (APP_SOURCES ${APP_SOURCES} elementSDepend.vala)
set (APP_SOURCES ${APP_SOURCES} elementScheme.vala)
set (APP_SOURCES ${APP_SOURCES} elementTranslation.vala)
set (APP_SOURCES ${APP_SOURCES} elementValaBinary.vala)
set (APP_SOURCES ${APP_SOURCES} elementVapidir.vala)
set (APP_SOURCES ${APP_SOURCES} findVala.vala)
set (APP_SOURCES ${APP_SOURCES} genVapis.vala)
set (APP_SOURCES ${APP_SOURCES} globals.vala)
set (APP_SOURCES ${APP_SOURCES} gresource_xml.vala)
set (APP_SOURCES ${APP_SOURCES} packages.vala)
set (APP_SOURCES ${APP_SOURCES} packages_deb.vala)
set (APP_SOURCES ${APP_SOURCES} packages_pacman.vala)
set (APP_SOURCES ${APP_SOURCES} packages_rpm.vala)
set (APP_SOURCES ${APP_SOURCES} readPkgconfig.vala)


if ((${CMAKE_BUILD_TYPE} STREQUAL "Debug") OR (${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo"))
	set(COMPILE_OPTIONS ${COMPILE_OPTIONS} "-g")
endif()

set (COMPILE_OPTIONS ${COMPILE_OPTIONS} --library=AutoVala --gir AutoVala-1.0.gir )

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

target_link_libraries( AutoVala readline )
set_target_properties( AutoVala PROPERTIES
VERSION
	1.0
SOVERSION
	1 )


install(TARGETS
	AutoVala
LIBRARY DESTINATION
	${CMAKE_INSTALL_LIBDIR}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.h
DESTINATION
	${CMAKE_INSTALL_INCLUDEDIR}/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.vapi
DESTINATION
	${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.deps
DESTINATION
	${CMAKE_INSTALL_DATAROOTDIR}/vala/vapi/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala-1.0.gir
DESTINATION
	${CMAKE_INSTALL_DATAROOTDIR}/gir-1.0/
)
install(FILES
	${CMAKE_CURRENT_BINARY_DIR}/AutoVala.pc
DESTINATION
	${CMAKE_INSTALL_LIBDIR}/pkgconfig/
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
		${CMAKE_INSTALL_DATAROOTDIR}/doc/autovala
	)
endif()
