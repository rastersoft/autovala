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

execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/autovala-fileformat.5.md -o ${CMAKE_CURRENT_BINARY_DIR}/autovala-fileformat.5 -f markdown_github -t man -s )
execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/autovala-fileformat.5 )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/autovala-fileformat.5.gz DESTINATION share/man/man5/ )

execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/autovala-keep-changes.7.md -o ${CMAKE_CURRENT_BINARY_DIR}/autovala-keep-changes.7 -f markdown_github -t man -s )
execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/autovala-keep-changes.7 )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/autovala-keep-changes.7.gz DESTINATION share/man/man7/ )

execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/autovala-rules.7.md -o ${CMAKE_CURRENT_BINARY_DIR}/autovala-rules.7 -f markdown_github -t man -s )
execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/autovala-rules.7 )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/autovala-rules.7.gz DESTINATION share/man/man7/ )

execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/autovala-tricks.7.md -o ${CMAKE_CURRENT_BINARY_DIR}/autovala-tricks.7 -f markdown_github -t man -s )
execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/autovala-tricks.7 )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/autovala-tricks.7.gz DESTINATION share/man/man7/ )

execute_process ( COMMAND pandoc ${CMAKE_CURRENT_SOURCE_DIR}/autovala.1.md -o ${CMAKE_CURRENT_BINARY_DIR}/autovala.1 -f markdown_github -t man -s )
execute_process ( COMMAND gzip -f ${CMAKE_CURRENT_BINARY_DIR}/autovala.1 )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/autovala.1.gz DESTINATION share/man/man1/ )

