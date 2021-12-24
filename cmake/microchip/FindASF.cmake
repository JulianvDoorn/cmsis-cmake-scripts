set(ASF "asf")

# CMake chokes on evaluating the paramtheses. Which is why a temporary variable
# is added
set(PFx86 "ProgramFiles(x86)")

if (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    set (SCAN_PATHS 
        "C:/"
        "$ENV{ProgramFiles}/"
        "$ENV{${PFx86}}/"
    )
elseif (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    set (SCAN_PATHS)

    message(STATUS "${CMAKE_CURRENT_LIST_FILE}(${CMAKE_CURRENT_LIST_LINE}): "
    "Linux asf scan paths are not defined. Please define them in this file "
    "andissue a pull request")
elseif (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    set (SCAN_PATHS 
        ""
    )

    message(STATUS "${CMAKE_CURRENT_LIST_FILE}(${CMAKE_CURRENT_LIST_LINE}): "
    "Darwin asf scan paths are not defined. Please define them in this file "
    "andissue a pull request")
else()
    message(STATUS "${CMAKE_CURRENT_LIST_FILE}(${CMAKE_CURRENT_LIST_LINE}): "
    "Platform unknown/unsupported.")
endif()

find_path(
    ASF_DIR
    NAMES "avr32" "common" "common2" "mega" "sam" "sam0" "thirdparty" "xmega"
    PATH_SUFFIXES ${ASF}
    PATHS
    ${SCAN_PATHS}
)

if (${ASF_DIR} STREQUAL "ASF_DIR-NOTFOUND")
    message(STATUS "Could not find asf. Check the scan paths of your platform "
    "in ${CMAKE_CURRENT_LIST_FILE}")
    return()
endif()

message(STATUS "Found ${ASF} at: ${ASF_DIR}")

set(module_list
    # None
)

set(link_files
    # None
)

set(ignore_files
    # None
)

set(ignore_rules
    "example"
    "doxygen"
    "unit_tests"
    "quick_start"
)

## Adds the given directory to the current list
macro(add_module module_name)
    if(${module_name} MATCHES "\\.c$")
        set(link_files ${link_files} "${ASF_DIR}/${module_name}")
        list(REMOVE_DUPLICATES link_files)
    else()
        set(module_list ${module_list} "${ASF_DIR}/${module_name}")
        list(REMOVE_DUPLICATES module_list)
    endif()
endmacro()

## Adds the given directory and all its children to the current list (note that
#  they should contain header files in order to be found)
macro(add_module_recursive module_name)
    file(GLOB_RECURSE headers_subtree_list "${ASF_DIR}/${module_name}/*.h")
    file(GLOB_RECURSE sources_subtree_list "${ASF_DIR}/${module_name}/*.c")
    
    set(module_list ${module_list} "${ASF_DIR}/${module_name}")

    foreach(filename ${headers_subtree_list} ${sources_subtree_list})
        get_filename_component(dir ${filename} DIRECTORY)
        set(module_list ${module_list} ${dir})
    endforeach()

    if (DEFINED module_list)
        list(REMOVE_DUPLICATES module_list)
    endif()
    unset(found_dirs)
endmacro()

## Removes the provided directory and all its children from the current list
# 
# Note that all modules that are defined after the -I flag, are added regardless
# if they are previously specified as ignored
macro(add_module_ignore module_name)
    if(${module_name} MATCHES ".c$")
        set(ignore_files ${ignore_files} "${ASF_DIR}/${module_name}")
    else()
        file(GLOB_RECURSE headers_subtree_list "${ASF_DIR}/${module_name}/*.h")
        file(GLOB_RECURSE sources_subtree_list "${ASF_DIR}/${module_name}/*.c")

        set(found_dirs "${ASF_DIR}/${module_name}")

        foreach(filename ${headers_subtree_list} ${sources_subtree_list})
            get_filename_component(dir ${filename} DIRECTORY)
            set(found_dirs ${found_dirs} ${dir})
        endforeach()

        list(REMOVE_DUPLICATES module_list)
        list(REMOVE_ITEM module_list ${found_dirs})
        unset(found_dirs)
    endif()
endmacro()

message(STATUS "Scanning ASF modules...")
if(DEFINED ASF_MODULES)
    foreach(module ${ASF_MODULES})
        if(${module} MATCHES "^-R")
            string(REGEX REPLACE "^-R" "" module ${module})
            add_module_recursive(${module})
        elseif(${module} MATCHES "^-I")
            string(REGEX REPLACE "^-I" "" module ${module})
            add_module_ignore(${module})
        else()
            add_module(${module})
        endif()
    endforeach()
else()
    message(STATUS "No ASF_MODULES specified")
endif()

foreach(module ${module_list})
    set(accepted TRUE)

    foreach(rule ${ignore_rules})
        if(${module} MATCHES ${rule})
            set(accepted FALSE)
            break()
        endif()
    endforeach()

    if(NOT accepted)
        list(REMOVE_ITEM module_list ${module})
    endif()
endforeach()
message(STATUS "Done scanning ASF modules")

set(sources
    ${link_files}
)

foreach(module ${module_list})
    file(GLOB filenames "${module}/*.c")
    set(sources ${sources} ${filenames})
    file(GLOB filenames "${module}/*.h")
    set(sources ${sources} ${filenames})
endforeach()

if(sources)
    list(REMOVE_DUPLICATES sources)
endif()

if(ignore_files)
    list(REMOVE_ITEM sources ${ignore_files})
endif()

if(sources)
  set(ASF_SOURCES ${sources})
  set(ASF_LIBRARIES ASF)
  set(ASF_INCLUDE_DIRS ${module_list})
  set(ASF_FOUND yes)
else()
  set(ASF_LIBRARIES)
  set(ASF_INCLUDE_DIRS)
  set(ASF_FOUND no)
endif()