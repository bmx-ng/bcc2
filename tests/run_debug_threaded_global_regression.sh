#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/debug-threaded-global"

mkdir -p "$output_root"
"$bmk" makeapp -bcc2 -a -h -o "$application" "$fixture_dir/compiler_debug_threaded_global_runtime.bmx"
output=$($application | tr -d '\r')
test "$output" = "bcc2 debug ThreadedGlobal runtime ok"

echo "bcc2 debug ThreadedGlobal regression passed"
