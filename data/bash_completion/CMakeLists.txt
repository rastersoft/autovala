### CMakeLists automatically created with AutoVala
### Do not edit

STRING( SUBSTRING ${CMAKE_INSTALL_PREFIX} 0 6 BASE_PREFIX)
IF( NOT ${BASE_PREFIX} STREQUAL "/home/" )
	EXEC_PROGRAM (
		pkg-config
	ARGS
		--variable=completionsdir bash-completion
	OUTPUT_VARIABLE INSTALL_BASH_COMPLETION
	)

	install(FILES
		${CMAKE_CURRENT_SOURCE_DIR}/autovala
	DESTINATION
		${INSTALL_BASH_COMPLETION}
	)
ENDIF()

