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

IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/AutoVala_gedit.plugin)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/AutoVala_gedit.plugin
	DESTINATION
		${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/AutoVala_gedit.plugin
	DESTINATION
		${FINAL_AUTOVALA_PATH}/usr/lib/gedit/plugins
	)
ENDIF()

