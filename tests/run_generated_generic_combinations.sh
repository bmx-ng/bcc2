#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
	echo "usage: $0 <bmk> <output-root> [seed]" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
seed=${3:-1337}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
case_timeout=${BCC2_GENERATED_CASE_TIMEOUT:-30}

if command -v python3 >/dev/null 2>&1; then
	python=python3
elif command -v python >/dev/null 2>&1; then
	python=python
else
	echo "generated generic combinations require Python 3" >&2
	exit 1
fi
if ! "$python" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)'
then
	echo "generated generic combinations require Python 3.8 or newer" >&2
	exit 1
fi

test ! -e "$output_root"
mkdir -p "$output_root"
"$python" "$script_dir/generate_generic_combinations.py" --output "$output_root/corpus" --seed "$seed"
corpus_root=$(CDPATH= cd -P -- "$output_root/corpus" && pwd -P)

manifest="$corpus_root/manifest.tsv"
test -f "$manifest"
positive_count=0
negative_count=0
module_count=0
tab=$(printf '\t')

module_root=
cleanup_module()
{
	if test -n "$module_root" && test -d "$module_root"
	then
		rm -rf -- "$module_root"
	fi
}

module_setup="$output_root/corpus/module-setup.tsv"
if test -f "$module_setup"
then
	IFS="$tab" read -r module_name module_relative module_source < "$module_setup"
	case "$module_relative" in
		mod/bcc2generatedboundary*.mod/owner.mod/owner.bmx) ;;
		*)
			echo "unsafe generated module target: $module_relative" >&2
			exit 1
			;;
	esac
	test -f "$module_source"
	module_root="$sdk_root/${module_relative%/owner.mod/owner.bmx}"
	module_target="$sdk_root/$module_relative"
	module_dir=$(dirname -- "$module_target")
	if test -e "$module_root"
	then
		echo "generated generic module target already exists: $module_root" >&2
		exit 1
	fi
	trap cleanup_module 0 HUP INT TERM
	mkdir -p "$module_dir"
	cp "$module_source" "$module_target"
	module_log="$output_root/module-build.txt"
	if ! "$bmk" makemods -a -bcc2 -r "$module_name" >"$module_log" 2>&1
	then
		echo "generated generic module failed to compile; source: $module_source; log: $module_log" >&2
		exit 1
	fi
	module_interface=$(find "$module_dir" -maxdepth 1 -name 'owner.release.*.i' -type f)
	test -f "$module_interface"
	grep -q 'TBoundaryBox<T>' "$module_interface"
	grep -q 'BoundaryDeferred<T>:Closure<T()>' "$module_interface"
	template_count=$(find "$module_dir/.generics/templates" -name '*.bmxgt' -type f | wc -l | tr -d ' ')
	test "$template_count" -ge 4
fi

while IFS="$tab" read -r kind case_id expected source features
do
	test "$kind" = "kind" && continue
	case_root="$output_root/results/$case_id"
	mkdir -p "$case_root"
	application="$case_root/application"
	log="$case_root/build.txt"
	if test "$kind" = "positive" || test "$kind" = "module-positive"; then
		positive_count=$((positive_count + 1))
		if test "$kind" = "module-positive"
		then
			module_count=$((module_count + 1))
		fi
		echo "[$positive_count] $case_id $features"
		if ! "$bmk" makeapp -bcc2 -single -r -o "$application" "$source" >"$log" 2>&1; then
			echo "$case_id failed to compile; source: $source; log: $log" >&2
			exit 1
		fi
		executable=$application
		test ! -f "$application.exe" || executable="$application.exe"
		runtime_log="$case_root/runtime.txt"
		if ! "$python" "$script_dir/run_with_timeout.py" "$case_timeout" "$executable" >"$runtime_log" 2>&1; then
			echo "$case_id failed or timed out at runtime; source: $source; log: $runtime_log" >&2
			exit 1
		fi
		result=$(tail -n 1 "$runtime_log" | tr -d '\r')
		if test "$result" != "$expected"; then
			echo "$case_id produced '$result', expected '$expected'; retained under $case_root" >&2
			exit 1
		fi
	else
		negative_count=$((negative_count + 1))
		echo "[negative $negative_count] $case_id expects $expected"
		if "$bmk" makeapp -bcc2 -single -r -o "$application" "$source" >"$log" 2>&1; then
			echo "$case_id unexpectedly compiled; source: $source; log: $log" >&2
			exit 1
		fi
		if ! grep -q "$expected" "$log"; then
			echo "$case_id did not report $expected; retained under $case_root" >&2
			exit 1
		fi
		if grep -Eqi 'segmentation fault|internal compiler error|assertion failed' "$log"; then
			echo "$case_id failed through an internal compiler fault; retained under $case_root" >&2
			exit 1
		fi
	fi
done < "$manifest"

test "$positive_count" -gt 0
test "$negative_count" -gt 0

incremental_setup="$corpus_root/incremental-setup.tsv"
test -f "$incremental_setup"
IFS="$tab" read -r incremental_v1 incremental_v2 incremental_live incremental_source incremental_expected_v1 incremental_expected_v2 < "$incremental_setup"
case "$incremental_live" in
	"$corpus_root/incremental/provider.bmx") ;;
	*)
		echo "unsafe generated incremental provider target: $incremental_live" >&2
		exit 1
		;;
esac
test -f "$incremental_v1"
test -f "$incremental_v2"
test -f "$incremental_source"
incremental_root="$output_root/results/incremental"
mkdir -p "$incremental_root"
incremental_application="$incremental_root/application"

cp "$incremental_v1" "$incremental_live"
incremental_log_v1="$incremental_root/build-v1.txt"
if ! "$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_source" >"$incremental_log_v1" 2>&1
then
	echo "incremental generic v1 failed to compile; source: $incremental_source; log: $incremental_log_v1" >&2
	exit 1
fi
incremental_executable=$incremental_application
test ! -f "$incremental_application.exe" || incremental_executable="$incremental_application.exe"
incremental_result=$("$incremental_executable" | tail -n 1 | tr -d '\r')
test "$incremental_result" = "$incremental_expected_v1"

# bmk's portable source freshness contract has one-second timestamp
# granularity on supported filesystems.
sleep 1
cp "$incremental_v2" "$incremental_live"
incremental_log_v2="$incremental_root/build-v2.txt"
if ! "$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_source" >"$incremental_log_v2" 2>&1
then
	echo "incremental generic v2 failed to compile; source: $incremental_source; log: $incremental_log_v2" >&2
	exit 1
fi
incremental_result=$("$incremental_executable" | tail -n 1 | tr -d '\r')
if test "$incremental_result" != "$incremental_expected_v2"
then
	echo "incremental generic rebuild produced '$incremental_result', expected '$incremental_expected_v2'; retained under $incremental_root" >&2
	exit 1
fi

incremental_manifest=$(find "$corpus_root/incremental/.bmx" -maxdepth 1 -name 'incremental-app*.bmxbuild' -type f)
test -f "$incremental_manifest"
generic_identity=$(awk '$1 == "link" { print $2; exit }' "$incremental_manifest")
test -n "$generic_identity"
generic_object="$corpus_root/incremental/.bmx/.generics/objects/$generic_identity.o"
if test ! -f "$generic_object"
then
	echo "incremental generic build did not publish a specialization object; retained under $incremental_root" >&2
	exit 1
fi
rm -f -- "$generic_object"
incremental_retry_log="$incremental_root/build-missing-object-retry.txt"
if ! "$bmk" makeapp -bcc2 -single -r -o "$incremental_application" "$incremental_source" >"$incremental_retry_log" 2>&1
then
	echo "incremental generic missing-object retry failed; source: $incremental_source; log: $incremental_retry_log" >&2
	exit 1
fi
incremental_result=$("$incremental_executable" | tail -n 1 | tr -d '\r')
if test "$incremental_result" != "$incremental_expected_v2"
then
	echo "incremental generic missing-object retry produced '$incremental_result', expected '$incremental_expected_v2'; retained under $incremental_root" >&2
	exit 1
fi

cleanup_module
trap - 0 HUP INT TERM
echo "bcc2 generated generic combinations passed: $positive_count positive ($module_count module), $negative_count negative, incremental rebuild/retry, seed $seed"
