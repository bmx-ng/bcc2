#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
mkdir -p "$output_root/debug" "$output_root/release"
cp "$fixture_dir/generic_routine_reference_runtime.bmx" "$output_root/debug/app.bmx"
cp "$fixture_dir/generic_routine_reference_runtime.bmx" "$output_root/release/app.bmx"

debug_application="$output_root/debug/generic-routine-reference"
"$bmk" makeapp -a -bcc2 -single -o "$debug_application" "$output_root/debug/app.bmx"
test "$("$debug_application" | tail -n 1 | tr -d '\r')" = "generic-routine-reference-ok"

release_application="$output_root/release/generic-routine-reference"
"$bmk" makeapp -a -bcc2 -single -r -o "$release_application" "$output_root/release/app.bmx"
test "$("$release_application" | tail -n 1 | tr -d '\r')" = "generic-routine-reference-ok"

consumer_c=$(find "$output_root/release/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.c' -type f)
test -f "$consumer_c"
grep -Fq 'Identity_int_' "$consumer_c"
grep -Fq 'TFunctions_Identity_string_' "$consumer_c"
grep -Eq 'memberIdentity.*TFunctions_Identity_string_' "$consumer_c"

echo "bcc2 generic routine-reference regression passed"
