### CMakeLists automatically created with AutoVala
### Do not edit

IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin
	DESTINATION
		lib/gedit/plugins/autovala
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin
	DESTINATION
		lib/gedit/plugins/autovala
	)
ENDIF()

