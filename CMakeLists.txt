### CMakeLists automatically created with AutoVala
### Do not edit

project (autovala)
cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.8)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
enable_testing ()

option(BUILD_VALADOC "Build API documentation if Valadoc is available" OFF)

set(HAVE_VALADOC OFF)
if(BUILD_VALADOC)
	find_package(Valadoc)
	if(VALADOC_FOUND)
		set(HAVE_VALADOC ON)
		include(Valadoc)
	else()
		message("Valadoc not found, will not build documentation")
	endif()
endif()

find_package(PkgConfig)

set(MODULES_TO_CHECK ${MODULES_TO_CHECK} gee-1.0)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} glib-2.0)
set(MODULES_TO_CHECK ${MODULES_TO_CHECK} gtk+-3.0)

pkg_check_modules(DEPS REQUIRED ${MODULES_TO_CHECK})

add_subdirectory(doc)
add_subdirectory(src)
add_subdirectory(po)
add_subdirectory(data)
add_subdirectory(data/bash_completion)
add_subdirectory(src/autovala_lib)
