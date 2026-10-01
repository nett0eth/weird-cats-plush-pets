#!/usr/bin/env sh
# Weird Cats Plush Pets installer for macOS / Linux (Codex / ChatGPT desktop).
#
# One command (downloads the pack, installs all 25 cats, cleans up):
#   curl -fsSL https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.sh | sh
#
# Only some cats from the one-liner:
#   curl -fsSL https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.sh | sh -s -- lucky prism
#   (or set PLUSH on the shell side of the pipe:  ... | PLUSH=lucky,prism sh)
#
# From a clone:
#   ./install/install.sh                 # install every cat
#   ./install/install.sh lucky prism     # install only some
#   ./install/install.sh --uninstall     # remove them again (all, or only the ones you name)
#
# Environment: CODEX_HOME (default ~/.codex), PLUSH (cats to install), PLUSH_UNINSTALL=1,
#              PLUSH_ARCHIVE_URL (override the download: https URL or a local .tar.gz / .zip path)
set -eu

target="${CODEX_HOME:-$HOME/.codex}/pets"
uninstall=0
[ "${PLUSH_UNINSTALL:-0}" = "0" ] || [ "${PLUSH_UNINSTALL:-0}" = "false" ] || uninstall=1
if [ "${1:-}" = "--uninstall" ]; then uninstall=1; shift; fi

# selected cats: arguments first, then $PLUSH (comma or space separated)
if [ "$#" -eq 0 ] && [ -n "${PLUSH:-}" ]; then
  # shellcheck disable=SC2046
  set -- $(printf '%s' "$PLUSH" | tr ',' ' ')
fi
wanted=" "
for w in ${1+"$@"}; do w=$(printf '%s' "${w#weird-cats-plush-}" | tr 'A-Z' 'a-z'); wanted="$wanted$w "; done

want() { [ "$wanted" = " " ] || case "$wanted" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ---- uninstall: works from what is installed, no download needed ----
if [ "$uninstall" -eq 1 ]; then
  n=0
  for dir in "$target"/weird-cats-plush-* "$target"/weird-cats-dots-*; do
    [ -d "$dir" ] || continue
    id=$(basename "$dir"); short=${id#weird-cats-plush-}; short=${short#weird-cats-dots-}
    want "$short" || continue
    rm -rf "${dir:?}" && echo "removed   $id" && n=$((n + 1))
  done
  [ "$n" -gt 0 ] || echo "Nothing to remove in $target"
  exit 0
fi

# ---- find the pets: next to this script (a clone), or download the repo (piped one-liner) ----
tmp=""
cleanup() { [ -z "$tmp" ] || rm -rf "$tmp"; }
trap cleanup EXIT INT TERM

source_dir=""
case "$0" in *install.sh) [ ! -f "$0" ] || run_local=1 ;; esac
if [ "${run_local:-0}" = 1 ]; then
  d=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd) || d=""
  [ -n "$d" ] && [ -d "$d/pets" ] && source_dir="$d/pets"
fi

if [ -z "$source_dir" ]; then
  url="${PLUSH_ARCHIVE_URL:-https://github.com/nett0eth/weird-cats-plush-pets/archive/refs/heads/main.tar.gz}"
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/weird-cats-plush.XXXXXX")
  if [ -f "$url" ]; then
    cp "$url" "$tmp/pack"
  else
    echo "Downloading Weird Cats Plush Pets..."
    if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$tmp/pack"
    elif command -v wget >/dev/null 2>&1; then wget -q "$url" -O "$tmp/pack"
    else echo "Need curl or wget to download the pack." >&2; exit 1; fi || {
      echo "Could not download $url" >&2
      echo "If the repository is still private, clone it and run ./install/install.sh instead." >&2
      exit 1
    }
  fi
  mkdir -p "$tmp/x"
  case "$url" in
    *.zip)
      if command -v unzip >/dev/null 2>&1; then unzip -q "$tmp/pack" -d "$tmp/x"
      else tar -xf "$tmp/pack" -C "$tmp/x"; fi ;;
    *) tar -xzf "$tmp/pack" -C "$tmp/x" ;;
  esac
  for d in "$tmp"/x/*/pets "$tmp"/x/pets; do [ -d "$d" ] && { source_dir="$d"; break; }; done
  [ -n "$source_dir" ] || { echo "The downloaded archive has no pets folder." >&2; exit 1; }
fi

available=""
for pet in "$source_dir"/weird-cats-plush-*; do [ -d "$pet" ] && available="$available $(basename "$pet" | sed 's/^weird-cats-plush-//')"; done
for w in $wanted; do
  case " $available " in *" $w "*) ;; *) echo "Warning: unknown cat '$w'. Available:$available" >&2 ;; esac
done

mkdir -p "$target"
n=0
for pet in "$source_dir"/weird-cats-plush-*; do
  [ -d "$pet" ] || continue
  id=$(basename "$pet"); short=${id#weird-cats-plush-}
  want "$short" || continue
  rm -rf "${target:?}/weird-cats-dots-$short"          # early test builds were called weird-cats-dots-*
  rm -rf "${target:?}/$id" && mkdir -p "$target/$id" && cp -f "$pet"/* "$target/$id/"
  echo "installed $id"
  n=$((n + 1))
done

[ "$n" -gt 0 ] || { echo "No matching pets. Available:$available" >&2; exit 1; }
printf "\nDone: %s cat(s) in %s\nRestart Codex or ChatGPT, open Settings > Pets and pick a cat ending in 'Weird Cats Plush Pets'.\n" "$n" "$target"
