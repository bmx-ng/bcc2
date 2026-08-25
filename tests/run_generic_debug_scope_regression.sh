#!/bin/sh
set -eu

compiler=$1
sdk_root=$2
output_root=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
build_root="$output_root/build"

mkdir -p "$build_root"
"$compiler" --emit-build --debug --platform macos --arch arm64 \
    --sdk "$sdk_root" -o "$build_root" \
    --build-c application.c --build-manifest application.bmxbuild \
    "$fixture_dir/compiler_generic_debug_scope.bmx"

unit=$(find "$build_root/.generics" -name '*.c' -type f | head -n 1)
cc -std=c99 -Wall -Wextra -Werror -I"$sdk_root/mod" -I"$build_root" \
    -c "$unit" -o "$output_root/generic-debug-scope.o"

grep -Fq 'BBDEBUGSCOPE_FUNCTION' "$unit"
grep -Fq 'BBDEBUGDECL_LOCAL, "value"' "$unit"
grep -Fq 'BBDEBUGDECL_LOCAL, "copy"' "$unit"
grep -Fq 'BBDEBUGDECL_LOCAL, "nested"' "$unit"
grep -Fq 'bbOnDebugEnterScope((BBDebugScope *)&bmx_generic_debug_scope);' "$unit"
grep -Fq 'bbOnDebugLeaveScope();' "$unit"
grep -Fq 'bbOnDebugPushExState();' "$unit"
grep -Fq 'bbOnDebugPopExState();' "$unit"

echo "bcc2 generic debugger scope regression passed"
