#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/string-escape-runtime"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_string_escape_runtime.bmx"

executable=$application
if test -f "$application.exe"
then
	executable="$application.exe"
fi

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "string-escape-ok"

echo "bcc2 String escape runtime regression passed"
