#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)

run_application()
{
	application=$1
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

mkdir -p "$output_root"

debug_application="$output_root/inferred-local-debug"
"$bmk" makeapp -a -bcc2 -single -o "$debug_application" "$fixture_dir/compiler_inferred_local_runtime.bmx"
test "$(run_application "$debug_application")" = "inferred-local-runtime-ok"

release_application="$output_root/inferred-local-release"
"$bmk" makeapp -a -bcc2 -single -r -o "$release_application" "$fixture_dir/compiler_inferred_local_runtime.bmx"
test "$(run_application "$release_application")" = "inferred-local-runtime-ok"

echo "bcc2 inferred Local runtime regression passed"
