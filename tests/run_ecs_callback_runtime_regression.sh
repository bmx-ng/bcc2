#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/ecs-callback-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -bcc2 -single -r -o "$application" "$fixture_dir/compiler_ecs_callback_runtime.bmx"
result=$("$application" | tail -n 1 | tr -d '\r')
test "$result" = "frame=2 progressed=1 calls=3 rows=3 value=42"

echo "bcc2 ECS callback/reflected Struct runtime regression passed"
