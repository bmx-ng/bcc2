#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
	echo "usage: $0 <bmk> <output-root>" >&2
	exit 1
fi

bmk_path=$1
output_root=$2
fixture_dir=$(CDPATH= cd -- "$(dirname -- "$0")/fixtures" && pwd)
source_path="$output_root/compiler_desktop_matrix.bmx"

case "$(uname -s):$(uname -m)" in
	Darwin:arm64) target=104 ;;
	Darwin:x86_64) target=102 ;;
	Linux:i?86) target=301 ;;
	Linux:x86_64) target=302 ;;
	Linux:arm*) target=303 ;;
	Linux:aarch64) target=304 ;;
	Linux:riscv32) target=305 ;;
	Linux:riscv64) target=306 ;;
	*)
		echo "unsupported native desktop validation host: $(uname -s) $(uname -m)" >&2
		exit 1
		;;
esac

mkdir -p "$output_root"
cp "$fixture_dir/compiler_desktop_matrix.bmx" "$source_path"

debug_console="$output_root/matrix-debug-console"
"$bmk_path" makeapp -t console -o "$debug_console" "$source_path"
test "$("$debug_console" | tr -d '\r\n')" = "$target:1:1:1:0:0"

release_console="$output_root/matrix-release-console"
"$bmk_path" makeapp -r -t console -o "$release_console" "$source_path"
test "$("$release_console" | tr -d '\r\n')" = "$target:2:1:1:0:0"

# Reuse the release output deliberately: this proves that changing only the
# compiler configuration invalidates generated code and that removing the
# option invalidates it again.
"$bmk_path" makeapp -r -gdb -t console -o "$release_console" "$source_path"
test "$("$release_console" | tr -d '\r\n')" = "$target:2:1:1:1:0"
"$bmk_path" makeapp -r -t console -o "$release_console" "$source_path"
test "$("$release_console" | tr -d '\r\n')" = "$target:2:1:1:0:0"

debug_gui="$output_root/matrix-debug-gui"
release_gui="$output_root/matrix-release-gui"
"$bmk_path" makeapp -t gui -o "$debug_gui" "$source_path"
"$bmk_path" makeapp -r -t gui -o "$release_gui" "$source_path"

case "$(uname -s)" in
	Darwin)
		debug_gui_executable="$debug_gui.app/Contents/MacOS/$(basename "$debug_gui")"
		release_gui_executable="$release_gui.app/Contents/MacOS/$(basename "$release_gui")"
		;;
	*)
		debug_gui_executable=$debug_gui
		release_gui_executable=$release_gui
		;;
esac
test -x "$debug_gui_executable"
test -x "$release_gui_executable"

# GUI startup requires a real desktop session on several supported hosts. The
# generated selections and linked executable are deterministic evidence here;
# interactive launch belongs in the platform runtime pass.
debug_gui_c=$(find "$output_root/.bmx" -maxdepth 1 -name 'compiler_desktop_matrix.bmx.gui.debug.*.c' -type f)
release_gui_c=$(find "$output_root/.bmx" -maxdepth 1 -name 'compiler_desktop_matrix.bmx.gui.release.*.c' -type f)
test -n "$debug_gui_c"
test -n "$release_gui_c"
grep -q "MatrixTarget = $target;" "$debug_gui_c"
grep -q 'MatrixMode = 1;' "$debug_gui_c"
grep -q 'MatrixApplication = 2;' "$debug_gui_c"
grep -q "MatrixTarget = $target;" "$release_gui_c"
grep -q 'MatrixMode = 2;' "$release_gui_c"
grep -q 'MatrixApplication = 2;' "$release_gui_c"

echo "native desktop validation matrix passed: $(uname -s) $(uname -m)"
