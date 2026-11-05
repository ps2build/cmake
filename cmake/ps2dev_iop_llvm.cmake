# CMake toolchain file for PS2 IOP modules built with the llvm toolchain
# (clang and lld from $PS2DEV/llvm-toolchain). ps2_iop_irx() turns a built
# module into an .irx.

if(NOT DEFINED ENV{PS2DEV})
    message(FATAL_ERROR "The PS2DEV environment variable must point at a ps2build SDK install.")
endif()
set(PS2DEV_ROOT "$ENV{PS2DEV}")

if(DEFINED ENV{PS2BUILD_TOOLCHAIN_ROOT})
    set(PS2_LLVM_ROOT "$ENV{PS2BUILD_TOOLCHAIN_ROOT}")
else()
    set(PS2_LLVM_ROOT "${PS2DEV_ROOT}/llvm-toolchain")
endif()

if(CMAKE_HOST_WIN32)
    set(PS2DEV_EXE_SUFFIX ".exe")
else()
    set(PS2DEV_EXE_SUFFIX "")
endif()

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR mips)
set(PS2 TRUE)
set(IOP TRUE)

set(_PS2_LLVM_BIN "${PS2_LLVM_ROOT}/llvm/bin")
set(_PS2_IOP_CFG "${PS2_LLVM_ROOT}/iop/bin/mipsel-none-elf-clang.cfg")

set(CMAKE_C_COMPILER   "${_PS2_LLVM_BIN}/clang${PS2DEV_EXE_SUFFIX}")
set(CMAKE_ASM_COMPILER "${_PS2_LLVM_BIN}/clang${PS2DEV_EXE_SUFFIX}")
set(CMAKE_AR     "${_PS2_LLVM_BIN}/llvm-ar${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(CMAKE_RANLIB "${_PS2_LLVM_BIN}/llvm-ranlib${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(CMAKE_LINKER "${_PS2_LLVM_BIN}/ld.lld${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(PS2_STRIP    "${_PS2_LLVM_BIN}/llvm-strip${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(PS2_IOPFIXUP "${PS2DEV_ROOT}/tools/iopfixup${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(IS_DIRECTORY "${PS2DEV_ROOT}/packages-llvm")
    set(_PS2_PACKAGES "${PS2DEV_ROOT}/packages-llvm")
else()
    set(_PS2_PACKAGES "${PS2DEV_ROOT}/packages")
endif()
set(CMAKE_COMMON_INCLUDE "${_PS2_PACKAGES}/core/common/include")

file(GLOB _PS2_INC_DIRS "${_PS2_PACKAGES}/core/*/include" "${_PS2_PACKAGES}/world/*/include")
set(_PS2_INC_FLAGS "")
foreach(_dir ${_PS2_INC_DIRS})
    if(NOT _dir STREQUAL CMAKE_COMMON_INCLUDE)
        string(APPEND _PS2_INC_FLAGS " -isystem \"${_dir}\"")
    endif()
endforeach()

set(_PS2_FLAGS "--config=${_PS2_IOP_CFG} -D_IOP -D__PS2__ -DPS2 -fno-builtin -Os -I${CMAKE_COMMON_INCLUDE}${_PS2_INC_FLAGS}")
set(CMAKE_C_FLAGS_INIT   "${_PS2_FLAGS}")
set(CMAKE_ASM_FLAGS_INIT "${_PS2_FLAGS}")

set(PS2_IOP_LINKFILE "${_PS2_PACKAGES}/core/startup/share/iop/linkfile" CACHE FILEPATH "Linker script for IOP modules")
set(CMAKE_C_LINK_EXECUTABLE
    "<CMAKE_LINKER> -r -T${PS2_IOP_LINKFILE} -o <TARGET> <OBJECTS> <LINK_FLAGS> -L${_PS2_PACKAGES}/core/startup/iop/lib -L${PS2_LLVM_ROOT}/iop/mipsel-none-elf/lib -liopmini -lstartup <LINK_LIBRARIES>")
set(CMAKE_EXECUTABLE_SUFFIX ".elf")

set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)

set(CMAKE_FIND_ROOT_PATH "${PS2_LLVM_ROOT}/iop" "${_PS2_PACKAGES}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

function(BUILD_IOP_IMPORTS out_f in_f)
    add_custom_command(OUTPUT ${out_f}
        COMMAND ${CMAKE_COMMAND} -E echo \#include \"irx_imports.h\" > ${out_f}
        COMMAND ${CMAKE_COMMAND} -E cat ${in_f} >> ${out_f}
        DEPENDS ${in_f}
        COMMENT "Creating ${out_f}" VERBATIM
    )
endfunction()

function(BUILD_IOP_EXPORTS out_f in_f)
    add_custom_command(OUTPUT ${out_f}
        COMMAND ${CMAKE_COMMAND} -E echo \#include \"irx.h\" > ${out_f}
        COMMAND ${CMAKE_COMMAND} -E cat ${in_f} >> ${out_f}
        DEPENDS ${in_f}
        COMMENT "Creating ${out_f}" VERBATIM
    )
endfunction()

# Strips the linked module and writes <target>.irx next to it. Pass --allow-zero-text
# in EXTRA_FLAGS for a module with no export table.
function(ps2_iop_irx target)
    cmake_parse_arguments(IRX "" "OUTPUT" "EXTRA_FLAGS" ${ARGN})
    if(NOT IRX_OUTPUT)
        set(IRX_OUTPUT "$<TARGET_FILE_DIR:${target}>/${target}.irx")
    endif()
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${PS2_STRIP} --strip-unneeded --remove-section=.pdr --remove-section=.comment
                --remove-section=.mdebug.abi32 --remove-section=.gnu.attributes
                -o "$<TARGET_FILE:${target}>.stripped" "$<TARGET_FILE:${target}>"
        COMMAND ${PS2_IOPFIXUP} --rb --irx1 ${IRX_EXTRA_FLAGS}
                -o "${IRX_OUTPUT}" "$<TARGET_FILE:${target}>.stripped"
        COMMENT "IOPFIXUP ${target}.irx" VERBATIM
    )
endfunction()
