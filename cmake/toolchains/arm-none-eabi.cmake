# Cross toolchain for the bootloader firmware (arm-none-eabi-gcc).
# Selected by the firmware presets in CMakePresets.json.
# Toolchain location: -DARM_TOOLCHAIN_DIR=<dir> or env ARM_TOOLCHAIN_DIR (empty = use PATH)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

if(NOT ARM_TOOLCHAIN_DIR AND DEFINED ENV{ARM_TOOLCHAIN_DIR})
    set(ARM_TOOLCHAIN_DIR "$ENV{ARM_TOOLCHAIN_DIR}")
endif()
set(ARM_TOOLCHAIN_DIR "${ARM_TOOLCHAIN_DIR}" CACHE PATH "Directory containing arm-none-eabi-* tools (empty = use PATH)")
set(ARM_TOOLCHAIN_PREFIX "arm-none-eabi-")

if(CMAKE_HOST_WIN32)
    set(_exe ".exe")
else()
    set(_exe "")
endif()

if(ARM_TOOLCHAIN_DIR)
    file(TO_CMAKE_PATH "${ARM_TOOLCHAIN_DIR}" _dir)
    set(_tc "${_dir}/${ARM_TOOLCHAIN_PREFIX}")
else()
    set(_tc "${ARM_TOOLCHAIN_PREFIX}")
endif()

set(CMAKE_C_COMPILER   "${_tc}gcc${_exe}")
set(CMAKE_ASM_COMPILER "${_tc}gcc${_exe}")
# gcc-ar / gcc-ranlib are required because objects are built with -flto
set(CMAKE_AR           "${_tc}gcc-ar${_exe}" CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB       "${_tc}gcc-ranlib${_exe}" CACHE FILEPATH "" FORCE)
set(CMAKE_OBJCOPY      "${_tc}objcopy${_exe}" CACHE FILEPATH "" FORCE)
set(CMAKE_SIZE         "${_tc}size${_exe}" CACHE FILEPATH "" FORCE)

# Bare metal: no linkable test executable during compiler checks
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_EXECUTABLE_SUFFIX ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_C ".elf")
set(CMAKE_EXECUTABLE_SUFFIX_ASM ".elf")

# All flags are set explicitly in firmware/CMakeLists.txt (mirrors the Makefile)
foreach(_lang C ASM)
    set(CMAKE_${_lang}_FLAGS_DEBUG "")
    set(CMAKE_${_lang}_FLAGS_RELEASE "")
    set(CMAKE_${_lang}_FLAGS_MINSIZEREL "")
    set(CMAKE_${_lang}_FLAGS_RELWITHDEBINFO "")
endforeach()
