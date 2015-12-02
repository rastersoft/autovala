### CMakeLists automatically created with AutoVala
### Do not edit

if (LOCAL)
	IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin
	DESTINATION
		$HOME/.local/share/gedit/plugins/autovala
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/autovala.plugin
	DESTINATION
		$HOME/.local/share/gedit/plugins/autovala
	)
ENDIF()

endif ()

