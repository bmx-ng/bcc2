#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-closure-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_closure_runtime.bmx"
result=$("$application" | tail -n 1 | tr -d '\r')
test "$result" = "generic-closure-ok"

echo "bcc2 generic Closure runtime regression passed"
