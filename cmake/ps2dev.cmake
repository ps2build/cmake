# CMake toolchain file for PS2 EE targets built with the GCC toolchain from a ps2build SDK install ($PS2DEV).
# For the LLVM toolchain use ps2dev_llvm.cmake.

if(NOT DEFINED ENV{PS2DEV})
    message(FATAL_ERROR "The PS2DEV environment variable must point at a ps2build SDK install.")
endif()
set(PS2DEV_ROOT "$ENV{PS2DEV}")

# Tool suffix follows the host OS, not the target.
if(CMAKE_HOST_WIN32)
    set(PS2DEV_EXE_SUFFIX ".exe")
else()
    set(PS2DEV_EXE_SUFFIX "")
endif()

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR mips)

# Upstream CMakeLists.txt files branch on a plain PS2 variable.
set(PS2 TRUE)

set(CMAKE_C_COMPILER   "${PS2DEV_ROOT}/toolchain/ee/bin/mips64r5900el-ps2-elf-gcc${PS2DEV_EXE_SUFFIX}")
set(CMAKE_CXX_COMPILER "${PS2DEV_ROOT}/toolchain/ee/bin/mips64r5900el-ps2-elf-g++${PS2DEV_EXE_SUFFIX}")
set(CMAKE_AR           "${PS2DEV_ROOT}/toolchain/ee/bin/mips64r5900el-ps2-elf-ar${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
set(CMAKE_RANLIB       "${PS2DEV_ROOT}/toolchain/ee/bin/mips64r5900el-ps2-elf-ranlib${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")

# Covers long object and library lists. Include and library flags go through the @files below.
set(CMAKE_NINJA_FORCE_RESPONSE_FILE 1 CACHE INTERNAL "")

# No default crt0 to link the compiler check against.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Shared headers such as tamtypes.h are always on the include path.
set(CMAKE_COMMON_INCLUDE "${PS2DEV_ROOT}/packages/core/common/include")

# Packages go on -idirafter so the compiler's own libc headers win a name collision. core is listed first.
set(_PS2_PACKAGES "${PS2DEV_ROOT}/packages")
set(_PS2_CORE_INC "")
set(_PS2_PKG_INC "")
set(_PS2_PKG_LIB "")
# Also globs one level under include/ for packages that declare several include_dirs (ps2ip).
file(GLOB _PS2_CORE_INC_DIRS "${_PS2_PACKAGES}/core/*/include")
file(GLOB _PS2_CORE_INC_SUBDIRS LIST_DIRECTORIES true "${_PS2_PACKAGES}/core/*/include/*")
foreach(_dir ${_PS2_CORE_INC_DIRS})
  if(NOT _dir STREQUAL "${CMAKE_COMMON_INCLUDE}")
    list(APPEND _PS2_CORE_INC "-idirafter" "${_dir}")
  endif()
endforeach()
foreach(_dir ${_PS2_CORE_INC_SUBDIRS})
  if(IS_DIRECTORY "${_dir}")
    list(APPEND _PS2_CORE_INC "-idirafter" "${_dir}")
  endif()
endforeach()
file(GLOB _PS2_PKG_INC_DIRS "${_PS2_PACKAGES}/world/*/include")
file(GLOB _PS2_PKG_INC_SUBDIRS LIST_DIRECTORIES true "${_PS2_PACKAGES}/world/*/include/*")
foreach(_dir ${_PS2_PKG_INC_DIRS})
  list(APPEND _PS2_PKG_INC "-idirafter" "${_dir}")
endforeach()
foreach(_dir ${_PS2_PKG_INC_SUBDIRS})
  if(IS_DIRECTORY "${_dir}")
    list(APPEND _PS2_PKG_INC "-idirafter" "${_dir}")
  endif()
endforeach()
file(GLOB _PS2_PKG_LIB_DIRS "${_PS2_PACKAGES}/core/*/lib" "${_PS2_PACKAGES}/world/*/lib")
foreach(_dir ${_PS2_PKG_LIB_DIRS})
  list(APPEND _PS2_PKG_LIB "-L${_dir}")
endforeach()
# Flags go in GCC @files to stay under the Windows command-line length limit.
set(_PS2_INC_RSP "${CMAKE_BINARY_DIR}/ps2dev_includes.rsp")
set(_PS2_LIB_RSP "${CMAKE_BINARY_DIR}/ps2dev_libdirs.rsp")
set(_PS2_INC_RSP_CONTENT "")
foreach(_flag ${_PS2_CORE_INC} ${_PS2_PKG_INC})
  string(APPEND _PS2_INC_RSP_CONTENT "\"${_flag}\"\n")
endforeach()
file(WRITE "${_PS2_INC_RSP}" "${_PS2_INC_RSP_CONTENT}")
set(_PS2_LIB_RSP_CONTENT "")
foreach(_flag ${_PS2_PKG_LIB})
  string(APPEND _PS2_LIB_RSP_CONTENT "\"${_flag}\"\n")
endforeach()
file(WRITE "${_PS2_LIB_RSP}" "${_PS2_LIB_RSP_CONTENT}")
set(_PS2_ALL_INC_STR "@${_PS2_INC_RSP}")
set(_PS2_PKG_LIB_STR "@${_PS2_LIB_RSP}")

# Upstream code checks _EE, __PS2__ or PS2 depending on the file.
set(CMAKE_C_FLAGS_INIT   "-D_EE -D__PS2__ -DPS2 -G0 -I${CMAKE_COMMON_INCLUDE} ${_PS2_ALL_INC_STR}")
set(CMAKE_CXX_FLAGS_INIT "-D_EE -D__PS2__ -DPS2 -G0 -I${CMAKE_COMMON_INCLUDE} ${_PS2_ALL_INC_STR}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_PS2_PKG_LIB_STR}")

# Search only this SDK, never the host's /usr.
set(CMAKE_FIND_ROOT_PATH "${PS2DEV_ROOT}/toolchain/ee" "${PS2DEV_ROOT}/packages")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# ps2pkgconf resolves pkg-config queries from package.yaml manifests.
set(PKG_CONFIG_EXECUTABLE "${PS2DEV_ROOT}/tools/ps2pkgconf${PS2DEV_EXE_SUFFIX}" CACHE FILEPATH "")
