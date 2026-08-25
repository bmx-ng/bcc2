#!/bin/sh
set -eu

compiler=$1
sdk_root=$2
output_dir=$3
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

mkdir -p "$output_dir"

"$compiler" \
    --dump-ir \
    -r -p macos -g arm64 -t console -h -f brl.standardio \
    --sdk "$sdk_root" \
    -o "$output_dir/traditional.ir" \
    "$fixture_dir/compiler_configuration_cli.bmx"

grep -q "target macos/arm64 release" "$output_dir/traditional.ir"
grep -q "literal 42 : Int" "$output_dir/traditional.ir"

"$compiler" \
    --dump-ir \
    --release --platform macos --arch arm64 --app-type console \
    --single-threaded --user-defs feature=1 --framework brl.standardio \
    --sdk "$sdk_root" \
    -o "$output_dir/long-options.ir" \
    "$fixture_dir/compiler_configuration_cli.bmx"

grep -q "target macos/arm64 release" "$output_dir/long-options.ir"
grep -q "literal 41 : Int" "$output_dir/long-options.ir"

"$compiler" \
    --dump-ir \
    -p macos -g arm64 -t console -h -f brl.standardio \
    --sdk "$sdk_root" \
    -o "$output_dir/default-debug.ir" \
    "$fixture_dir/compiler_configuration_cli.bmx"

grep -q "target macos/arm64 debug" "$output_dir/default-debug.ir"
grep -q "literal 42 : Int" "$output_dir/default-debug.ir"
