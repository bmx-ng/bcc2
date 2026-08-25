#!/bin/sh
set -eu

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2sequenceboundarytest.mod"

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

if test -e "$module_root"
then
	echo "temporary Sequence-boundary test module already exists: $module_root" >&2
	exit 1
fi

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

mkdir -p "$output_root/file" "$output_root/module" "$module_root/functions.mod"

cp "$fixture_dir/sequence_boundary_file_functions.bmx" "$output_root/file/"
cp "$fixture_dir/sequence_boundary_file_app.bmx" "$output_root/file/app.bmx"
file_debug_application="$output_root/file/sequence-file-boundary-debug"
"$bmk" makeapp -a -bcc2 -single -o "$file_debug_application" "$output_root/file/app.bmx"
test "$(run_application "$file_debug_application")" = "sequence-file-boundary-ok"
file_application="$output_root/file/sequence-file-boundary"
"$bmk" makeapp -a -bcc2 -single -r -o "$file_application" "$output_root/file/app.bmx"
test "$(run_application "$file_application")" = "sequence-file-boundary-ok"
file_consumer_c=$(find "$output_root/file/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.c' -type f)
test -f "$file_consumer_c"
grep -Fq 'if (!application_app_FileSequenceEven__Bint(' "$file_consumer_c"
grep -Fq '= application_app_FileSequenceTriple__Bint(' "$file_consumer_c"
grep -Fq '= application_app_FileSequenceAdd__Blong__Bint(' "$file_consumer_c"
grep -Fq 'TFileGenericSequenceFunctions_int_' "$file_consumer_c"
grep -Fq '_Identity(bmx_fn2_value0_value)' "$file_consumer_c"
grep -Fq 'FileGenericIdentity' "$file_consumer_c"
grep -Fq 'FileSequenceVisit__Bint' "$file_consumer_c"
test "$(grep -Fc 'FileSequenceBelowFive__Bint' "$file_consumer_c")" -ge 2
grep -Fq 'bbArraySlice' "$file_consumer_c"
grep -Fq 'if (!((bmx_fn10_p1_operator1)(' "$file_consumer_c"
grep -Fq '= ((bmx_fn11_p1_operator1)(' "$file_consumer_c"
grep -Fq 'FileEvenSequence__A1_Bint' "$file_consumer_c"
grep -Fq -- '->clas->m_count_' "$file_consumer_c"
test "$(grep -Ec '^(BB(INT|LONG|ARRAY)|void|struct [A-Za-z0-9_]+) bmx_fn[0-9]+__sequence_fused_.*\) \{$' "$file_consumer_c")" -eq 14

cp "$fixture_dir/module_sequence_boundary_functions.bmx" "$module_root/functions.mod/functions.bmx"
"$bmk" makemods -a -bcc2 Bcc2SequenceBoundaryTest.Functions
"$bmk" makemods -a -bcc2 -r Bcc2SequenceBoundaryTest.Functions
module_interface=$(find "$module_root/functions.mod" -maxdepth 1 -name 'functions.release.*.i' -type f)
test -f "$module_interface"
grep -q 'ModuleSequenceEven' "$module_interface"
grep -q 'TModuleSequenceFunctions' "$module_interface"
grep -q 'ModuleSequenceIdentity<T>' "$module_interface"
grep -q 'ModuleGenericIdentity<T>' "$module_interface"
grep -q 'ModuleEvenSequence' "$module_interface"
grep -q 'ModuleExpandSequence' "$module_interface"
grep -q 'ModuleSequenceBelowFive' "$module_interface"
grep -q 'TModuleGenericSequenceFunctions<T>' "$module_interface"
grep -q 'ModuleSequenceVisit' "$module_interface"

cp "$fixture_dir/module_sequence_boundary_app.bmx" "$output_root/module/app.bmx"
module_debug_application="$output_root/module/sequence-module-boundary-debug"
"$bmk" makeapp -a -bcc2 -single -o "$module_debug_application" "$output_root/module/app.bmx"
test "$(run_application "$module_debug_application")" = "sequence-module-boundary-ok"
module_application="$output_root/module/sequence-module-boundary"
"$bmk" makeapp -a -bcc2 -single -r -o "$module_application" "$output_root/module/app.bmx"
test "$(run_application "$module_application")" = "sequence-module-boundary-ok"

consumer_c=$(find "$output_root/module/.bmx" -maxdepth 1 -name 'app.bmx.console.release.*.c' -type f)
test -f "$consumer_c"
grep -q 'bcc2sequenceboundarytest_functions_ModuleSequenceEven' "$consumer_c"
grep -q 'bcc2sequenceboundarytest_functions_ModuleSequenceTriple' "$consumer_c"
grep -q 'bcc2sequenceboundarytest_functions_ModuleSequenceAdd' "$consumer_c"
grep -Fq 'if (!bcc2sequenceboundarytest_functions_ModuleSequenceEven__Bint(' "$consumer_c"
grep -Fq '= bcc2sequenceboundarytest_functions_ModuleSequenceTriple__Bint(' "$consumer_c"
grep -Fq '= bcc2sequenceboundarytest_functions_ModuleSequenceAdd__Blong__Bint(' "$consumer_c"
grep -Fq 'TModuleGenericSequenceFunctions_int_' "$consumer_c"
grep -Fq '_Identity(bmx_fn2_value0_value)' "$consumer_c"
grep -Fq 'ModuleGenericIdentity' "$consumer_c"
grep -Fq 'ModuleSequenceVisit__Bint' "$consumer_c"
test "$(grep -Fc 'ModuleSequenceBelowFive__Bint' "$consumer_c")" -ge 2
grep -Fq 'bbArraySlice' "$consumer_c"
grep -Fq 'if (!((bmx_fn10_p1_operator1)(' "$consumer_c"
grep -Fq '= ((bmx_fn11_p1_operator1)(' "$consumer_c"
grep -Fq 'ModuleEvenSequence__A1_Bint' "$consumer_c"
grep -Fq -- '->clas->m_count_' "$consumer_c"
test "$(grep -Ec '^(BB(INT|LONG|ARRAY)|void|struct [A-Za-z0-9_]+) bmx_fn[0-9]+__sequence_fused_.*\) \{$' "$consumer_c")" -eq 14

cleanup_module
trap - 0 HUP INT TERM

echo "bcc2 Sequence file/module boundary regression passed"
