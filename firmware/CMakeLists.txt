# Bootloader firmware for SBOOT_MCU (Makefile `bootloader`, `program`, `program_stcube`)
set(ROOT "${PROJECT_SOURCE_DIR}")

include(${ROOT}/cmake/sboot_mcu.cmake)

set(SBOOT_FWNAME "firmware" CACHE STRING "Firmware output base name")

# ---------------------------------------------------------------------------
# CMSIS / stm32.h (Makefile `prerequisites`)
# ---------------------------------------------------------------------------
set(CMSIS "${ROOT}/CMSIS" CACHE PATH "CMSIS root folder")
set(CMSISDEV "${CMSIS}/Device")
if(NOT EXISTS "${CMSISDEV}/ST/stm32.h")
    message(FATAL_ERROR
        "stm32.h not found in ${CMSISDEV}/ST. Fetch prerequisites first:\n"
        "  git clone --depth 1 https://github.com/ARM-software/CMSIS_5.git CMSIS\n"
        "  git clone --recurse-submodules --depth 1 https://github.com/dmitrystu/stm32h.git CMSIS/Device/ST\n"
        "  git submodule update --init usb")
endif()
set(CMSIS_INCS "${CMSISDEV}/ST" "${CMSIS}/CMSIS/Include" "${CMSIS}/CMSIS/Core/Include")

# ---------------------------------------------------------------------------
# libusb module (usb/Makefile `module`): CFLAGS2 = -flto $(FWCPU) -mthumb -std=gnu99 -Os
# ---------------------------------------------------------------------------
file(GLOB USB_SOURCES CONFIGURE_DEPENDS ${ROOT}/usb/src/*.c ${ROOT}/usb/src/*.S)
add_library(usb STATIC ${USB_SOURCES})
target_compile_options(usb PRIVATE -flto ${FW_CPU} -mthumb -std=gnu99 -Os)
target_compile_definitions(usb PRIVATE ${FW_DEFS} USBD_SOF_DISABLED)
target_include_directories(usb PRIVATE ${CMSIS_INCS} ${ROOT}/usb/inc)

# ---------------------------------------------------------------------------
# Bootloader
# ---------------------------------------------------------------------------
set(FW_CFLAGS -mthumb -Os -Wall -std=gnu99 -fdata-sections -ffunction-sections)

add_executable(${SBOOT_FWNAME}
    ${SBOOT_CRYPT_SRC}
    ${FW_STARTUP}
    ${ROOT}/src/descriptors.c ${ROOT}/src/bootloader.c
    ${ROOT}/src/rc5a.S ${ROOT}/src/chacha_a.S ${ROOT}/src/rc6a.S)

# C gets CPU + FWCFLAGS + -flto; .S gets only defines/includes (same as Makefile)
target_compile_options(${SBOOT_FWNAME} PRIVATE
    $<$<COMPILE_LANGUAGE:C>:${FW_CPU} ${FW_CFLAGS} -flto>)
target_compile_definitions(${SBOOT_FWNAME} PRIVATE ${FW_DEFS} ${SBOOT_DEFS})
target_include_directories(${SBOOT_FWNAME} PRIVATE
    ${CMSIS_INCS} ${ROOT}/inc ${ROOT}/usb/inc ${ROOT})

set(FW_OUT "${CMAKE_BINARY_DIR}/${SBOOT_FWNAME}")
target_link_options(${SBOOT_FWNAME} PRIVATE
    ${FW_CPU} ${FW_CFLAGS}
    -specs=nano.specs -nostartfiles -Wl,--gc-sections
    -Wl,-Map=${FW_OUT}.map
    -Wl,--script=${FW_LDSCRIPT})
target_link_libraries(${SBOOT_FWNAME} PRIVATE usb)
set_target_properties(${SBOOT_FWNAME} PROPERTIES
    LINK_DEPENDS "${FW_LDSCRIPT}"
    ADDITIONAL_CLEAN_FILES "${FW_OUT}.map")

# hex / bin / size, same as generate_binary() in oniimai_STM32
add_custom_command(TARGET ${SBOOT_FWNAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${SBOOT_FWNAME}> ${FW_OUT}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${SBOOT_FWNAME}> ${FW_OUT}.bin
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${SBOOT_FWNAME}>
    BYPRODUCTS ${FW_OUT}.hex ${FW_OUT}.bin
    COMMENT "Creating ${SBOOT_FWNAME}.hex / ${SBOOT_FWNAME}.bin")

add_custom_target(bootloader DEPENDS ${SBOOT_FWNAME})

# ---------------------------------------------------------------------------
# Programming
# ---------------------------------------------------------------------------
set(STFLASH "st-flash" CACHE STRING "st-flash executable")
set(STPROG_CLI "STM32_Programmer_CLI" CACHE STRING "STM32CubeProgrammer CLI executable")
add_custom_target(program
    COMMAND ${STFLASH} --reset --format ihex write ${FW_OUT}.hex
    DEPENDS ${SBOOT_FWNAME} USES_TERMINAL VERBATIM)
add_custom_target(program_stcube
    COMMAND ${STPROG_CLI} -c port=SWD reset=HWrst -d ${FW_OUT}.hex -hardRst
    DEPENDS ${SBOOT_FWNAME} USES_TERMINAL VERBATIM)
