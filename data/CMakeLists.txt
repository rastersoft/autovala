### CMakeLists automatically created with AutoVala
### Do not edit

EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml)
EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml)
ADD_CUSTOM_COMMAND (
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/application.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/c.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/h.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/library.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/project.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/test_vala.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/vala.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/vapi.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/build.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/full_build.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/refresh.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/refresh_langs.svg ${CMAKE_CURRENT_SOURCE_DIR}/pixmaps/update.svg ${CMAKE_CURRENT_SOURCE_DIR}/interface/binary_properties.ui ${CMAKE_CURRENT_SOURCE_DIR}/interface/new_project.ui
	COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml

	COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml
)

add_custom_target(extras_gresource_xml DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c)
SET (extras_gresource_xml_C_FILE ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c PARENT_SCOPE)
SET (extras_gresource_xml_H_FILE ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h PARENT_SCOPE)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.rastersoft.autovala.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/appdata/ )
