### CMakeLists automatically created with AutoVala
### Do not edit

IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autovalascratch.plugin)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/autovalascratch.plugin
	DESTINATION
		lib/scratch/plugins/autovala
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/autovalascratch.plugin
	DESTINATION
		lib/scratch/plugins/autovala
	)
ENDIF()

