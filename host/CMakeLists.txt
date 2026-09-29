# Host tools (native compiler):
#   fwcrypt     - firmware encrypter/decrypter (Makefile `crypter`)
#   cipher_test - cipher test vectors         (Makefile `testsuite`)
set(ROOT "${PROJECT_SOURCE_DIR}")

set(TS_SRC ${SBOOT_CRYPT_SRC})
list(REMOVE_ITEM TS_SRC "${ROOT}/src/crypto.c")

add_executable(fwcrypt ${SBOOT_CRYPT_SRC} ${ROOT}/src/encrypter.c)
add_executable(cipher_test ${TS_SRC} ${ROOT}/src/ctest.c)

foreach(_t fwcrypt cipher_test)
    target_include_directories(${_t} PRIVATE ${ROOT}/inc ${ROOT})
    target_compile_definitions(${_t} PRIVATE ${SBOOT_DEFS})
endforeach()

add_custom_target(crypter DEPENDS fwcrypt)
add_custom_target(testsuite DEPENDS cipher_test)

# ctest: cipher vectors + fwcrypt encrypt/decrypt round trip
add_test(NAME cipher_test COMMAND cipher_test)
add_test(NAME fwcrypt_roundtrip
    COMMAND ${CMAKE_COMMAND}
        -DFWCRYPT=$<TARGET_FILE:fwcrypt>
        -DINPUT=$<TARGET_FILE:cipher_test>
        -DWORKDIR=${CMAKE_CURRENT_BINARY_DIR}
        -P ${ROOT}/cmake/fwcrypt_roundtrip.cmake)
