cmake_minimum_required(VERSION 3.21)

# Build flavour, normally chosen by a preset (see CMakePresets.json):
#   firmware - bootloader for SBOOT_MCU with arm-none-eabi-gcc
#   host     - fwcrypt / cipher_test with the native compiler
set(SBOOT_TARGET "firmware" CACHE STRING "What to build: firmware or host")
set_property(CACHE SBOOT_TARGET PROPERTY STRINGS firmware host)

if(SBOOT_TARGET STREQUAL "firmware" AND NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/toolchains/arm-none-eabi.cmake")
endif()

project(sboot_stm32 C)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
include(cmake/sboot_common.cmake)

if(SBOOT_TARGET STREQUAL "firmware")
    enable_language(ASM)
    add_subdirectory(firmware)
elseif(SBOOT_TARGET STREQUAL "host")
    enable_testing()
    add_subdirectory(host)
else()
    message(FATAL_ERROR "SBOOT_TARGET must be 'firmware' or 'host', got '${SBOOT_TARGET}'")
endif()
