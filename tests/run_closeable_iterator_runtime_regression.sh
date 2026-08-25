#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
fixture="$fixture_dir/compiler_closeable_iterator_runtime.bmx"

mkdir -p "$output_root"

run_application()
{
	application=$1
	executable=$application
	if test -x "$application.exe"
	then
		executable="$application.exe"
	fi
	"$executable" | tail -n 1 | tr -d '\r'
}

debug_application="$output_root/closeable-iterator-debug"
"$bmk" makeapp -a -bcc2 -o "$debug_application" "$fixture"
test "$(run_application "$debug_application")" = "closeable-iterator-ok"

release_application="$output_root/closeable-iterator-release"
"$bmk" makeapp -a -bcc2 -r -o "$release_application" "$fixture"
test "$(run_application "$release_application")" = "closeable-iterator-ok"

echo "bcc2 closeable iterator runtime regression passed"
