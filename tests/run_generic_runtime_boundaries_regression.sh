#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-runtime-boundaries"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_runtime_boundaries.bmx"
"$application"

test "$(nm "$application" | grep -Ec ' [BbDdSs] _?bmx_gen_.*TThreadedBoundary_int_.*_global_current$')" -eq 1
test "$(nm "$application" | grep -Ec ' [BbDdSs] _?bmx_gen_.*TThreadedBoundary_string_.*_global_current$')" -eq 1
test "$(nm "$application" | grep -Ec ' T _?bmx_gen_.*TAbstractBoundary_Pick_string_[0-9a-f]{32}$')" -eq 1
