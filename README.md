# cmake

CMake toolchain files for building PS2 EE and IOP targets against a [ps2build](https://github.com/ps2build/ps2build) SDK install, so an upstream project's own CMake build runs without a `ps2.yaml`.

## Usage

`ps2build update` and [setup-sdk](https://github.com/ps2build/setup-sdk) install these files into `$PS2DEV/cmake/`. The toolchain files read `PS2DEV` from the environment.

```sh
export PS2DEV=/opt/ps2dev
cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=$PS2DEV/cmake/ps2dev.cmake
```

| File | Target | Toolchain |
|---|---|---|
| `ps2dev.cmake` | EE | GCC from `$PS2DEV/toolchain` |
| `ps2dev_llvm.cmake` | EE | clang and lld from `$PS2DEV/llvm-toolchain` |
| `ps2dev_iop_llvm.cmake` | IOP | clang and lld from `$PS2DEV/llvm-toolchain` |

The GCC file reads packages from `$PS2DEV/packages`. The LLVM files read `$PS2DEV/packages-llvm` when it exists and `$PS2DEV/packages` otherwise.

### IOP modules

Include `ps2dev_iop_llvm.cmake` and call `ps2_iop_irx(<target>)` on the executable target to produce the `.irx`. Pass `EXTRA_FLAGS --allow-zero-text` for a module without an export table.

### Variables

| Variable | Description |
|---|---|
| `PS2DEV` (environment) | SDK install root. Required |
| `PS2BUILD_TOOLCHAIN_ROOT` (environment) | Overrides `$PS2DEV/llvm-toolchain` in the LLVM files |
| `PS2_EE_LINKFILE`, `PS2_IOP_LINKFILE` | Linker script for EE executables and IOP modules |

## License

[CC0 1.0](LICENSE).
