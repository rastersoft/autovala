### CMakeLists automatically created with AutoVala
### Do not edit

IF( NOT ( ${CMAKE_INSTALL_PREFIX} MATCHES "^/home/" ) )
	EXEC_PROGRAM (
		pkg-config
	ARGS
		--variable=completionsdir bash-completion
	OUTPUT_VARIABLE INSTALL_BASH_COMPLETION
	)

	IF( NOT ( INSTALL_BASH_COMPLETION STREQUAL "" ))
		install(FILES
			${CMAKE_CURRENT_SOURCE_DIR}/autovala
		DESTINATION
			${INSTALL_BASH_COMPLETION}
		)
	ENDIF()

ENDIF()

