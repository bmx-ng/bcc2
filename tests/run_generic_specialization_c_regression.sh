#!/bin/sh
set -eu

sdk_root=$1
output_dir=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures/generic_specialization" && pwd)

mkdir -p "$output_dir"

for source_name in canonical_list_specialization file1 file2 file3
do
    cc -std=c99 -Wall -Wextra -Werror \
        -I"$sdk_root/mod" \
        -I"$fixture_dir" \
        -c "$fixture_dir/$source_name.c" \
        -o "$output_dir/$source_name.o"
done

cc "$output_dir/canonical_list_specialization.o" \
    "$output_dir/file1.o" \
    "$output_dir/file2.o" \
    "$output_dir/file3.o" \
    -o "$output_dir/generic-specialization-regression"

"$output_dir/generic-specialization-regression"

implementation_count=$(nm "$output_dir"/*.o | grep -Ec ' T _?bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_First$')
test "$implementation_count" -eq 1
