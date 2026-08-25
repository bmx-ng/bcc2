#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-composition-matrix-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_composition_matrix_runtime.bmx"
result=$("$application" | tr -d '\r')
test "$result" = "generic-composition-matrix-runtime-ok"

echo "bcc2 generic composition native matrix passed: 16 cases"
