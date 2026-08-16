#!/bin/sh

set -eu

if [ -z "${HOME:-}" ]; then
  printf 'install: HOME is not set\n' >&2
  exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
install_dir="$HOME/.welcome"
zshrc="$HOME/.zshrc"
hook='[ -r "$HOME/.welcome/welcome.sh" ] && . "$HOME/.welcome/welcome.sh"'

mkdir -p "$install_dir/txt"
cp "$source_dir/welcome.sh" "$install_dir/welcome.sh"
cp "$source_dir"/txt/*.txt "$install_dir/txt/"
chmod 0644 "$install_dir/welcome.sh" "$install_dir"/txt/*.txt

if [ ! -e "$zshrc" ]; then
  : > "$zshrc"
fi

if ! grep -Fqx "$hook" "$zshrc"; then
  printf '\n%s\n' "$hook" >> "$zshrc"
fi

printf 'Installed terminal welcome in %s\n' "$install_dir"
printf 'Activated it in %s\n' "$zshrc"
printf 'Open a new terminal to see the animation.\n'
