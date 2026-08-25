#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-boundary-stress"

mkdir -p "$output_root"
"$bmk" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_boundary_stress_runtime.bmx"

executable=$application
if test -f "$application.exe"
then
	executable="$application.exe"
fi

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "generic-boundary-stress-ok"

echo "bcc2 generic overload/constraint/recursive stress regression passed"
