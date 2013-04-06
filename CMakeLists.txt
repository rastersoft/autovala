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

pkg_check_modules(DEPS REQUIRED
	gee-1.0
	glib-2.0
	gtk+-3.0
)

add_subdirectory(doc)
add_subdirectory(po)
add_subdirectory(src/autovala_lib)
add_subdirectory(src)
