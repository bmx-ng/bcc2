#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/closure-literal-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -bcc2 -single -r -o "$application" "$fixture_dir/compiler_closure_literal_runtime.bmx"
result=$("$application" | tail -n 1 | tr -d '\r')
test "$result" = "closure-ok"

echo "bcc2 managed Closure literal runtime regression passed"
