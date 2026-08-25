#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
application="$output_root/coverage-runtime"
coverage_file="$output_root/lcov.info"

assert_single_source_record()
{
	# MSYS presents drive paths as /c/... while bcc records its normalized
	# native C:/... spelling. The source basename is unique in each fixture and
	# still proves that same-file registrations were aggregated into one record.
	source_name=$1
	source_count=$(awk -v source_name="$source_name" '
		index($0, "SF:") == 1 && substr($0, length($0) - length(source_name) + 1) == source_name { count++ }
		END { print count + 0 }
	' "$coverage_file")
	test "$source_count" -eq 1
}

mkdir -p "$output_root"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -o "$application" "$fixture_dir/compiler_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "coverage-ok"
test -f "$coverage_file"

assert_single_source_record compiler_coverage_runtime.bmx
grep -F "FN:5,Covered" "$coverage_file" >/dev/null
grep -F "FNDA:1,Covered" "$coverage_file" >/dev/null
grep -F "DA:7,1" "$coverage_file" >/dev/null
grep -F "DA:9,0" "$coverage_file" >/dev/null
grep -F "DA:12,1" "$coverage_file" >/dev/null

echo "bcc2 ordinary coverage runtime regression passed"

# Qualify the configuration edges independently of the deeper release
# scenarios below. Debug instrumentation and C source-line directives must
# coexist with coverage, while an otherwise identical non-coverage build must
# neither register probes nor write an LCOV file.
application="$output_root/coverage-debug-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -d -cov -o "$application" "$fixture_dir/compiler_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "coverage-ok"
test -f "$coverage_file"
assert_single_source_record compiler_coverage_runtime.bmx
grep -F "FNDA:1,Covered" "$coverage_file" >/dev/null

application="$output_root/coverage-gdb-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -gdb -o "$application" "$fixture_dir/compiler_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "coverage-ok"
test -f "$coverage_file"
assert_single_source_record compiler_coverage_runtime.bmx
grep -F "FNDA:1,Covered" "$coverage_file" >/dev/null

application="$output_root/no-coverage-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -o "$application" "$fixture_dir/compiler_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "coverage-ok"
test ! -f "$coverage_file"

echo "bcc2 coverage configuration matrix passed"

application="$output_root/callable-coverage-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -o "$application" "$fixture_dir/compiler_callable_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "callable-coverage-ok"
test -f "$coverage_file"

assert_single_source_record compiler_callable_coverage_runtime.bmx
grep -F "FNDA:1,Function in module initialization at line 5 column 28" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in module initialization at line 10 column 40" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in MakeNested at line 15 column 8" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in MakeNested at line 16 column 9" "$coverage_file" >/dev/null
grep -F "FNDA:3,Closure in InvokeLoop at line 25 column 32" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in module initialization at line 33 column 25" "$coverage_file" >/dev/null
grep -F "DA:34,1" "$coverage_file" >/dev/null

echo "bcc2 callable coverage runtime regression passed"

application="$output_root/generic-coverage-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -o "$application" "$fixture_dir/compiler_generic_coverage_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "generic-coverage-ok"
test -f "$coverage_file"
cp "$coverage_file" "$output_root/generic-coverage-first.info"

# Exercise the manifest/object reuse path with the identical coverage
# configuration; the second build must remain runnable and preserve the same
# specialization-owned registration/catalog behavior.
"$bmk_path" makeapp -bcc2 -single -r -cov -o "$application" "$fixture_dir/compiler_generic_coverage_runtime.bmx"
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "generic-coverage-ok"
cmp "$output_root/generic-coverage-first.info" "$coverage_file"

assert_single_source_record compiler_generic_coverage_runtime.bmx
grep -F "FNDA:1,Identity<int>" "$coverage_file" >/dev/null
grep -F "FNDA:1,Identity<string>" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in Identity<int> at line 6 column 8" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in Identity<string> at line 6 column 8" "$coverage_file" >/dev/null
grep -F "FNDA:1,TGenericCoverageFactory<string>.Make" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in TGenericCoverageFactory<string>.Make at line 19 column 9" "$coverage_file" >/dev/null
grep -F "FNDA:1,Throwing<int>" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in Throwing<int> at line 12 column 8" "$coverage_file" >/dev/null
grep -F "FNDA:1,LocalIdentity<int>" "$coverage_file" >/dev/null
grep -F "FNDA:1,Local Function Inner in LocalIdentity<int> at line 26 column 1" "$coverage_file" >/dev/null
grep -F "DA:7,2" "$coverage_file" >/dev/null
grep -F "DA:13,1" "$coverage_file" >/dev/null

echo "bcc2 source-free generic coverage runtime regression passed"

application="$output_root/threaded-coverage-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -h -r -cov -o "$application" "$fixture_dir/compiler_coverage_threaded_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "threaded-coverage-ok"
test -f "$coverage_file"

assert_single_source_record compiler_coverage_threaded_runtime.bmx
grep -F "FNDA:4,Worker" "$coverage_file" >/dev/null
grep -F "FNDA:1000,GenericIdentity<int>" "$coverage_file" >/dev/null
grep -F "FNDA:1000,Closure in Worker at line 14 column 40" "$coverage_file" >/dev/null
grep -F "DA:33,1" "$coverage_file" >/dev/null
cp "$coverage_file" "$output_root/threaded-coverage-first.info"

result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "threaded-coverage-ok"
cmp "$output_root/threaded-coverage-first.info" "$coverage_file"

echo "bcc2 threaded deterministic coverage runtime regression passed"

application="$output_root/end-coverage-runtime"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -o "$application" "$fixture_dir/compiler_coverage_end_runtime.bmx"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
"$executable"
test -f "$coverage_file"

assert_single_source_record compiler_coverage_end_runtime.bmx
grep -F "FNDA:1,BeforeEnd" "$coverage_file" >/dev/null
grep -F "DA:10,1" "$coverage_file" >/dev/null
grep -F "DA:12,0" "$coverage_file" >/dev/null

echo "bcc2 explicit End coverage runtime regression passed"

# Keep the repair case entirely beneath the caller-owned output root. Removing
# one generated object and its freshness key models an interrupted build after
# specialization planning without touching a source-tree cache.
repair_source="$output_root/compiler_generic_coverage_repair.bmx"
application="$output_root/generic-coverage-repair"
cp "$fixture_dir/compiler_generic_coverage_runtime.bmx" "$repair_source"
rm -f "$coverage_file"
"$bmk_path" makeapp -a -bcc2 -single -r -cov -o "$application" "$repair_source"
executable=$application
if test -x "$application.exe"; then executable="$application.exe"; fi
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "generic-coverage-ok"

repair_object=$(find "$output_root/.bmx/.generics/objects" -name '*.o' -type f | head -n 1)
test -n "$repair_object"
test -f "$repair_object.bcc2key"
rm "$repair_object" "$repair_object.bcc2key"

repair_output=$("$bmk_path" makeapp -bcc2 -single -r -cov -o "$application" "$repair_source")
printf '%s\n' "$repair_output"
test "$(printf '%s' "$repair_output" | grep -c 'Compiling generic specialization')" -eq 1
result=$("$executable" | tail -n 1 | tr -d '\r')
test "$result" = "generic-coverage-ok"
test -f "$coverage_file"

assert_single_source_record compiler_generic_coverage_repair.bmx
grep -F "FNDA:1,Identity<int>" "$coverage_file" >/dev/null
grep -F "FNDA:1,Closure in Identity<int> at line 6 column 8" "$coverage_file" >/dev/null

echo "bcc2 coverage specialization repair regression passed"
