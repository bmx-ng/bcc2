#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/loop-closure-capture-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_loop_closure_capture_runtime.bmx"
result=$("$application" | tail -n 1 | tr -d '\r')
test "$result" = "loop-closure-capture-ok"

echo "bcc2 loop-scoped Closure capture runtime regression passed"
