# CMake toolchain file for PS2 EE targets built with the llvm toolchain
# (clang and lld from $PS2DEV/llvm-toolchain). Use it like ps2dev.cmake.

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

set(_PS2_LLVM_BIN "${PS2_LLVM_ROOT}/llvm/bin")
set(_PS2_EE_CFG "${PS2_LLVM_ROOT}/ee/bin/mips64r5900el-ps2-elf-clang.cfg")

set(CMAKE_C_COMPILER   "${_PS2_LLVM_BIN}/clang${PS2DEV_EXE_SUFFIX}")
set(CMAKE_CXX_COMPILER "${_PS2_LLVM_BIN}/clang++${PS2DEV_EXE_SUFFIX}")
set(CMAKE_ASM_COMPILER "${_PS2_LLVM_BIN}/clang${PS2DEV_EXE_SUFFIX}")
set(CMAKE_AR     "${_PS2_LLVM_BIN}/llvm-ar${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(CMAKE_RANLIB "${_PS2_LLVM_BIN}/llvm-ranlib${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(CMAKE_LINKER "${_PS2_LLVM_BIN}/ld.lld${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")

set(CMAKE_NINJA_FORCE_RESPONSE_FILE 1 CACHE INTERNAL "")
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

if(IS_DIRECTORY "${PS2DEV_ROOT}/packages-llvm")
    set(_PS2_PACKAGES "${PS2DEV_ROOT}/packages-llvm")
else()
    set(_PS2_PACKAGES "${PS2DEV_ROOT}/packages")
endif()
set(CMAKE_COMMON_INCLUDE "${_PS2_PACKAGES}/core/common/include")

file(GLOB _PS2_INC_DIRS "${_PS2_PACKAGES}/core/*/include" "${_PS2_PACKAGES}/world/*/include")
file(GLOB _PS2_INC_SUBDIRS LIST_DIRECTORIES true "${_PS2_PACKAGES}/core/*/include/*" "${_PS2_PACKAGES}/world/*/include/*")
file(GLOB _PS2_LIB_DIRS "${_PS2_PACKAGES}/core/*/lib" "${_PS2_PACKAGES}/world/*/lib")

set(_PS2_INC_RSP "${CMAKE_BINARY_DIR}/ps2dev_includes.rsp")
set(_PS2_LIB_RSP "${CMAKE_BINARY_DIR}/ps2dev_libdirs.rsp")
set(_PS2_INC_CONTENT "")
foreach(_dir ${_PS2_INC_DIRS} ${_PS2_INC_SUBDIRS})
    if(IS_DIRECTORY "${_dir}" AND NOT _dir STREQUAL CMAKE_COMMON_INCLUDE)
        string(APPEND _PS2_INC_CONTENT "-idirafter\n\"${_dir}\"\n")
    endif()
endforeach()
file(WRITE "${_PS2_INC_RSP}" "${_PS2_INC_CONTENT}")
set(_PS2_LIB_CONTENT "-L${_PS2_PACKAGES}/core/startup/ee/lib\n-L${PS2_LLVM_ROOT}/ee/mips64r5900el-ps2-elf/lib\n")
foreach(_dir ${_PS2_LIB_DIRS})
    string(APPEND _PS2_LIB_CONTENT "-L${_dir}\n")
endforeach()
file(WRITE "${_PS2_LIB_RSP}" "${_PS2_LIB_CONTENT}")

set(_PS2_FLAGS "--config=${_PS2_EE_CFG} -D__PS2__ -DPS2 -I${CMAKE_COMMON_INCLUDE} @${_PS2_INC_RSP}")
set(CMAKE_C_FLAGS_INIT   "${_PS2_FLAGS}")
set(CMAKE_CXX_FLAGS_INIT "${_PS2_FLAGS}")
set(CMAKE_ASM_FLAGS_INIT "${_PS2_FLAGS}")

set(PS2_EE_LINKFILE "${_PS2_PACKAGES}/core/startup/share/ee/linkfile" CACHE FILEPATH "Linker script for EE executables")
set(_PS2_DEFAULT_LIBS "--start-group -lc -lm -lcdvd -lpthread -lpthreadglue -lcglue -lkernel -latomic -lclang_rt.builtins-mips64el --end-group")
set(_PS2_CXX_LIBS "-lc++ -lc++abi -lunwind")
set(_PS2_LINK "<CMAKE_LINKER> -T${PS2_EE_LINKFILE} -o <TARGET> <OBJECTS> <LINK_FLAGS> @${_PS2_LIB_RSP} -lstartup <LINK_LIBRARIES>")
set(CMAKE_C_LINK_EXECUTABLE   "${_PS2_LINK} ${_PS2_DEFAULT_LIBS}")
set(CMAKE_CXX_LINK_EXECUTABLE "${_PS2_LINK} ${_PS2_CXX_LIBS} ${_PS2_DEFAULT_LIBS}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "--gc-sections")

set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)

set(CMAKE_FIND_ROOT_PATH "${PS2_LLVM_ROOT}/ee" "${_PS2_PACKAGES}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(PKG_CONFIG_EXECUTABLE "${PS2DEV_ROOT}/tools/ps2pkgconf${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
