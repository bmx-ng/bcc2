#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/callable-reflection-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -r -o "$application" "$fixture_dir/compiler_callable_reflection_runtime.bmx"
output=$($application | tr -d '\r')
test "$output" = "bcc2 callable reflection runtime ok"

echo "bcc2 callable reflection runtime regression passed"
