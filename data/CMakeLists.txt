### CMakeLists automatically created with AutoVala
### Do not edit

EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml)
EXECUTE_PROCESS( COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml)
ADD_CUSTOM_COMMAND (
	OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml ${CMAKE_CURRENT_SOURCE_DIR}/application.svg ${CMAKE_CURRENT_SOURCE_DIR}/c.svg ${CMAKE_CURRENT_SOURCE_DIR}/h.svg ${CMAKE_CURRENT_SOURCE_DIR}/library.svg ${CMAKE_CURRENT_SOURCE_DIR}/project.svg ${CMAKE_CURRENT_SOURCE_DIR}/test_vala.svg ${CMAKE_CURRENT_SOURCE_DIR}/vala.svg ${CMAKE_CURRENT_SOURCE_DIR}/vapi.svg ${CMAKE_CURRENT_SOURCE_DIR}/binary_properties.ui ${CMAKE_CURRENT_SOURCE_DIR}/new_project.ui
	COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-source --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml

	COMMAND glib-compile-resources --sourcedir=${CMAKE_CURRENT_SOURCE_DIR} --generate-header --target=${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h ${CMAKE_CURRENT_SOURCE_DIR}/extras.gresource.xml
)

add_custom_target(extras_gresource_xml DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c)
SET (extras_gresource_xml_C_FILE ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.c PARENT_SCOPE)
SET (extras_gresource_xml_H_FILE ${CMAKE_CURRENT_BINARY_DIR}/extras.gresource.xml.h PARENT_SCOPE)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.rastersoft.autovala.metainfo.xml DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/appdata/ )
