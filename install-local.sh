#!/bin/sh
# Build the standalone fig from this source tree and install it under a
# user-writable prefix (default: ~/.local). No root, no autotools, no configure.
#
#   ./install-local.sh            # install to ~/.local/bin/fig
#   ./install-local.sh ~/opt      # install to ~/opt/bin/fig
#   PREFIX=~/.local ./install-local.sh --uninstall
#
set -eu

# Resolve $0 through any symlinks so this works when run by absolute path or
# via a symlink placed on $PATH.
self=$0
while [ -h "$self" ]; do
	link=$(readlink "$self")
	case $link in
		/*) self=$link ;;
		*) self=$(dirname -- "$self")/$link ;;
	esac
done
src_dir=$(CDPATH= cd -- "$(dirname -- "$self")" && pwd)
prefix=${PREFIX:-$HOME/.local}
case ${1:-} in
	--uninstall|-u) uninstall=1 ;;
	'') uninstall=0 ;;
	-*) echo "unknown option: $1" >&2; exit 2 ;;
	*) prefix=$1; uninstall=0 ;;
esac
bindir=$prefix/bin
target=$bindir/fig

if [ "$uninstall" = 1 ]; then
	rm -f "$target"
	echo "removed: $target"
	echo "(your repos and config in ~/.config/fig/ are untouched)"
	command -v fig >/dev/null 2>&1 && echo "fig now resolves to: $(command -v fig)"
	exit 0
fi

cd "$src_dir"
[ -f fig.in ] || { echo "error: fig.in not found in $src_dir" >&2; exit 1; }

ver=$(./build-aux/git-version-gen .tarball-version 2>/dev/null || echo unknown)

mkdir -p "$bindir"
sed -e 's|@SHELL@|/bin/sh|g' \
    -e 's|@GIT@|git|g' \
    -e 's|@GREP@|grep|g' \
    -e 's|@SED@|sed|g' \
    -e 's|@WC@|wc|g' \
    -e 's|@COMM@|comm|g' \
    -e 's|@TRANSFORMED_PACKAGE_NAME@|fig|g' \
    -e "s|@VERSION@|$ver|g" \
    -e 's|@DEPLOYMENT@|-standalone|g' \
    fig.in > "$target"
chmod +x "$target"

printf 'installed: %s\n' "$target"
"$target" version 2>/dev/null | sed 's/^/  /' || true
if grep -q 'ls-files -z' "$target"; then
	echo "  delete fix: present"
else
	echo "  delete fix: MISSING" >&2
fi

case :${PATH:-}: in
	*:"$bindir":*) ;;
	*) echo "note: $bindir is not on your PATH" >&2 ;;
esac
if command -v fig >/dev/null 2>&1 && [ "$(command -v fig)" != "$target" ]; then
	echo "note: 'fig' still resolves to $(command -v fig)"
	echo "      run 'hash -r' or open a new shell to pick up $target"
fi
