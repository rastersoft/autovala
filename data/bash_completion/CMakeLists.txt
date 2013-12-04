### CMakeLists automatically created with AutoVala
### Do not edit

IF(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/autovala)
	install(DIRECTORY
		${CMAKE_CURRENT_SOURCE_DIR}/autovala
	DESTINATION
		/etc/bash_completion.d
	)
ELSE()
	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/autovala
	DESTINATION
		/etc/bash_completion.d
	)
ENDIF()

