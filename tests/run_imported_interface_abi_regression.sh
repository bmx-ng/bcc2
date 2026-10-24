#!/bin/sh
set -eu

if test "$#" -ne 2
then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_dir=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)
bmk="$bmk_dir/$(basename -- "$1")"
sdk_root=$(CDPATH= cd -- "$bmk_dir/.." && pwd)
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
module_root="$sdk_root/mod/bcc2interfaceabi.mod"
box_dir="$module_root/box.mod"
owner_dir="$module_root/owner.mod"

test ! -e "$module_root"
mkdir -p "$box_dir" "$owner_dir" "$output_root"

cleanup_module()
{
	rm -rf "$module_root"
}
trap cleanup_module 0 HUP INT TERM

cp "$fixture_dir/module_interface_abi_box.bmx" "$box_dir/box.bmx"
cp "$fixture_dir/module_interface_abi_owner.bmx" "$owner_dir/owner.bmx"

for mode in debug release
do
	if test "$mode" = release
	then
		set -- -r
	else
		set --
	fi
	"$bmk" makemods -a -bcc2 "$@" Bcc2InterfaceAbi.Box
	"$bmk" makemods -a -bcc2 "$@" Bcc2InterfaceAbi.Owner
	application="$output_root/imported-interface-abi-$mode"
	"$bmk" makeapp -a -bcc2 -single "$@" -o "$application" "$fixture_dir/compiler_imported_interface_abi_app.bmx"
	executable=$application
	if test -f "$application.exe"
	then
		executable="$application.exe"
	fi
	result=$("$executable" | tail -n 1 | tr -d '\r')
	test "$result" = "imported-interface-abi-ok"
done

echo "bcc2 imported interface ABI regression passed"
