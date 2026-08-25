#!/bin/sh
set -eu

compiler=$1
sdk_root=$2
output_root=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
build_root="$output_root/build"

mkdir -p "$build_root"
"$compiler" --emit-build --release --platform macos --arch arm64 \
    --sdk "$sdk_root" -o "$build_root" \
    --build-c application.c --build-manifest application.bmxbuild \
    "$fixture_dir/compiler_generic_dynamic_dispatch.bmx"

dispatcher_count=0
implementation_count=0
specialization_units=$(find "$build_root/.generics" -name '*.c' -type f | sort)
for unit in $specialization_units
do
    cc -std=c99 -Wall -Wextra -Werror -I"$sdk_root/mod" -I"$build_root" \
        -c "$unit" -o "$output_root/$(basename "$unit" .c).o"
    if grep -q 'dynamic_entry->owner == clas' "$unit"
    then
        dispatcher_count=$((dispatcher_count + 1))
        grep -q 'entry->implementation = implementation' "$unit"
    fi
    if grep -q '_register_implementation(void)' "$unit"
    then
        implementation_count=$((implementation_count + 1))
        grep -q '_dynamic_adapter_' "$unit"
        grep -Fq '_register_dynamic((BBClass *)&' "$unit"
    fi
done

test "$dispatcher_count" -eq 1
test "$implementation_count" -eq 1
grep -Eq 'extern void .*_register_implementation\(void\);' "$build_root/application.c"
grep -Fq '_register_implementation();' "$build_root/application.c"
echo "bcc2 generic dynamic dispatcher regression passed"
