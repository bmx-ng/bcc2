#!/bin/sh
set -eu

bmk_path="${1:-../BlitzMax-bcc2/bin/bmk}"
output_root="${2:-/tmp/bcc2-eachin-deconstruction-runtime}"
fixture_dir="$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)"

mkdir -p "$output_root"

"$bmk_path" makeapp -a -bcc2 -single -o "$output_root/debug-single" "$fixture_dir/compiler_eachin_deconstruction_runtime.bmx"
"$output_root/debug-single" | grep -q "bcc2 EachIn deconstruction runtime ok"

"$bmk_path" makeapp -a -bcc2 -single -r -o "$output_root/release-single" "$fixture_dir/compiler_eachin_deconstruction_runtime.bmx"
"$output_root/release-single" | grep -q "bcc2 EachIn deconstruction runtime ok"

"$bmk_path" makeapp -a -bcc2 -r -o "$output_root/release-threaded" "$fixture_dir/compiler_eachin_deconstruction_runtime.bmx"
"$output_root/release-threaded" | grep -q "bcc2 EachIn deconstruction runtime ok"

echo "bcc2 EachIn deconstruction runtime regression passed"
