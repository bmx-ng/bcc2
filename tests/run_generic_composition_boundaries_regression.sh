#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-composition-boundaries"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_composition_boundaries.bmx"
result=$("$application" | tr -d '\r')
test "$result" = "generic-composition-ok"

echo "generic composition-boundary regression passed"
