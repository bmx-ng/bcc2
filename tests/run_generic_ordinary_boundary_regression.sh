#!/bin/sh
set -eu

bmk=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/generic-ordinary-boundary"

mkdir -p "$output_root"
"$bmk" makeapp -bcc2 -single -r -o "$application" "$fixture_dir/compiler_generic_ordinary_boundary.bmx"
"$application"

test "$(nm "$application" | grep -Ec ' T _?bmx_generic_dependency_hiddenoffset_')" -eq 1
test "$(nm "$application" | grep -Ec ' T _?bmx_generic_dependency_tordinaryhelpers_offset_')" -eq 1
test "$(nm "$application" | grep -Ec ' T _?bmx_generic_dependency_toptionalplain_new_.*_ObjectNew$')" -eq 1
test "$(nm "$application" | grep -Ec ' T _?bmx_generic_dependency_tvarplain_new_.*_ObjectNew$')" -eq 1
test "$(nm "$application" | grep -Ec ' T _?bmx_generic_dependency_sordinaryamount__add_')" -eq 1
