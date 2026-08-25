#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$output_root/gdb_source_mapping.bmx"
app_path="$output_root/gdb-source-mapping"

mkdir -p "$output_root"
cp "$fixture_dir/compiler_gdb_source_mapping.bmx" "$source_path"
"$bmk_path" makeapp -bcc2 -gdb -r -o "$app_path" "$source_path"

generated_c=$(find "$output_root/.bmx" -maxdepth 1 -name 'gdb_source_mapping.bmx*.c' -type f | head -n 1)
generated_object=$(find "$output_root/.bmx" -maxdepth 1 -name 'gdb_source_mapping.bmx*.o' -type f | head -n 1)
generic_c=$(find "$output_root/.bmx/.generics" -name '*.c' -type f -exec grep -l 'GenericMapped_int' {} \; | head -n 1)
generic_stem=$(basename "$generic_c" .c)
generic_object="$output_root/.bmx/.generics/objects/$generic_stem.o"
generic_closure_c=$(find "$output_root/.bmx/.generics" -name '*.c' -type f -exec grep -l 'GenericClosureMapped_string' {} \; | head -n 1)
generic_closure_stem=$(basename "$generic_closure_c" .c)
generic_closure_object="$output_root/.bmx/.generics/objects/$generic_closure_stem.o"
test -n "$generated_c"
test -n "$generated_object"
test -n "$generic_c"
test -n "$generic_object"
test -n "$generic_closure_c"
test -n "$generic_closure_object"
grep -q '#line 5 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 6 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 7 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 15 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 18 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 19 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 20 ".*/gdb_source_mapping.bmx"' "$generated_c"
grep -q '#line 1 "<bcc-generated>"' "$generated_c"
dwarfdump --debug-line "$generated_object" | awk '
	/^file_names\[/ {
		file_index = $0
		sub(/^file_names\[[[:space:]]*/, "", file_index)
		sub(/\].*/, "", file_index)
	}
	/name: "gdb_source_mapping.bmx"/ { source_index = file_index + 0 }
	$1 ~ /^0x/ && $4 == source_index {
		if ($2 == 6) line6 = 1
		if ($2 == 7) line7 = 1
		if ($2 == 15) line15 = 1
		if ($2 == 19) line19 = 1
		if ($2 == 20) line20 = 1
	}
	END { exit !(source_index && line6 && line7 && line15 && line19 && line20) }
'
mapped_symbol=$(nm "$generated_object" | awk '/ T .*MappedValue$/ { sub(/^_/, "", $3); print $3; exit }')
test -n "$mapped_symbol"
dwarfdump --name "$mapped_symbol" "$generated_object" | grep -q 'DW_AT_decl_file.*gdb_source_mapping.bmx'
dwarfdump --name "$mapped_symbol" "$generated_object" | grep -q 'DW_AT_decl_line.*(5)'
closure_symbol=$(nm "$generated_object" | awk '/ [Tt] .*_Function_$/ { sub(/^_/, "", $3); print $3; exit }')
test -n "$closure_symbol"
dwarfdump --name "$closure_symbol" "$generated_object" | grep -q 'DW_AT_decl_file.*gdb_source_mapping.bmx'
dwarfdump --name "$closure_symbol" "$generated_object" | grep -q 'DW_AT_decl_line.*(18)'
grep -q '#line 10 ".*/gdb_source_mapping.bmx"' "$generic_c"
grep -q '#line 11 ".*/gdb_source_mapping.bmx"' "$generic_c"
grep -q '#line 12 ".*/gdb_source_mapping.bmx"' "$generic_c"
grep -q '#line 1 "<bcc-generated>"' "$generic_c"
generic_symbol=$(nm "$generic_object" | awk '/ T .*GenericMapped/ { sub(/^_/, "", $3); print $3; exit }')
test -n "$generic_symbol"
dwarfdump --name "$generic_symbol" "$generic_object" | grep -q 'DW_AT_decl_file.*gdb_source_mapping.bmx'
dwarfdump --name "$generic_symbol" "$generic_object" | grep -q 'DW_AT_decl_line.*(10)'
dwarfdump --debug-line "$generic_object" | awk '
	/^file_names\[/ {
		file_index = $0
		sub(/^file_names\[[[:space:]]*/, "", file_index)
		sub(/\].*/, "", file_index)
	}
	/name: "gdb_source_mapping.bmx"/ { source_index = file_index + 0 }
	$1 ~ /^0x/ && $4 == source_index {
		if ($2 == 11) line11 = 1
		if ($2 == 12) line12 = 1
	}
	END { exit !(source_index && line11 && line12) }
'
grep -q '#line 25 ".*/gdb_source_mapping.bmx"' "$generic_closure_c"
grep -q '#line 26 ".*/gdb_source_mapping.bmx"' "$generic_closure_c"
grep -q '#line 27 ".*/gdb_source_mapping.bmx"' "$generic_closure_c"
generic_closure_symbol=$(nm "$generic_closure_object" | awk '/ [Tt] .*_closure_[0-9a-f]+$/ { sub(/^_/, "", $3); print $3; exit }')
test -n "$generic_closure_symbol"
dwarfdump --name "$generic_closure_symbol" "$generic_closure_object" | grep -q 'DW_AT_decl_file.*gdb_source_mapping.bmx'
dwarfdump --name "$generic_closure_symbol" "$generic_closure_object" | grep -q 'DW_AT_decl_line.*(25)'
dwarfdump --debug-line "$generic_closure_object" | awk '
	/^file_names\[/ {
		file_index = $0
		sub(/^file_names\[[[:space:]]*/, "", file_index)
		sub(/\].*/, "", file_index)
	}
	/name: "gdb_source_mapping.bmx"/ { source_index = file_index + 0 }
	$1 ~ /^0x/ && $4 == source_index {
		if ($2 == 26) line26 = 1
		if ($2 == 27) line27 = 1
	}
	END { exit !(source_index && line26 && line27) }
'
test "$("$app_path" | tr -d '\r\n')" = "42"

echo "bcc2 gdb source-mapping regression passed"
