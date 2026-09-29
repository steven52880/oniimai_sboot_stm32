# Settings shared by the firmware and the host tools.

# Cipher sources (Makefile CRYPT_SRC)
set(SBOOT_CRYPT_SRC
    arc4.c chacha.c gost.c raiden.c rc5.c speck.c
    xtea.c xtea1.c blowfish.c rtea.c rc6.c rijndael.c
    magma.c
    checksum.c crypto.c)
list(TRANSFORM SBOOT_CRYPT_SRC PREPEND "${PROJECT_SOURCE_DIR}/src/")

# User defines (Makefile USERDEFS): every DFU_xxx cache variable
# (e.g. "DFU_USER_CONFIG": "oniimaiv3_config.h" in a preset) + SBOOT_USER_DEFS.
# Firmware and fwcrypt must use the same set, otherwise keys/cipher differ.
set(SBOOT_USER_DEFS "" CACHE STRING "Extra defines (list), e.g. DFU_CIPHER=DFU_CIPHER_RC5")
set(SBOOT_DEFS ${SBOOT_USER_DEFS})
get_cmake_property(_cache_vars CACHE_VARIABLES)
foreach(_v IN LISTS _cache_vars)
    if(_v MATCHES "^DFU_")
        list(APPEND SBOOT_DEFS "${_v}=${${_v}}")
    endif()
endforeach()
message(STATUS "sboot user defs: ${SBOOT_DEFS}")
