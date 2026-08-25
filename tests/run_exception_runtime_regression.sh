#!/bin/sh
set -eu

compiler=$1
sdk_root=$2
output_dir=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

mkdir -p "$output_dir"

"$compiler" \
    --emit-runtime-c \
    -o "$output_dir/compiler_exception_runtime.c" \
    --sdk "$sdk_root" \
    "$fixture_dir/compiler_exception_runtime.bmx"

cc -std=c99 -Wall -Wextra -Werror \
    -I"$sdk_root/mod" \
    -c "$output_dir/compiler_exception_runtime.c" \
    -o "$output_dir/compiler_exception_runtime.o"

cc "$output_dir/compiler_exception_runtime.o" \
    "$sdk_root/mod/brl.mod/appstub.mod/appstub.release.macos.arm64.a" \
    "$sdk_root/mod/pub.mod/macos.mod/macos.release.macos.arm64.a" \
    "$sdk_root/mod/brl.mod/blitz.mod/blitz.release.macos.arm64.a" \
    -framework AppKit \
    -framework Foundation \
    -framework CoreServices \
    -o "$output_dir/compiler-exception-runtime"

"$output_dir/compiler-exception-runtime"
