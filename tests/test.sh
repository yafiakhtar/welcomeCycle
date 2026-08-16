#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

bash -n "$project_dir/welcome.sh"
zsh -n "$project_dir/welcome.sh"
sh -n "$project_dir/install.sh"

python3 - "$project_dir" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
expected = {
    "welcomeArabic.txt": 31,
    "welcomeChinese.txt": 31,
    "welcomeEnglish.txt": 63,
    "welcomeFrench.txt": 58,
    "welcomeGerman.txt": 81,
    "welcomeHindi.txt": 47,
    "welcomeSpanish.txt": 77,
    "yafi.txt": 25,
}

for name, width in expected.items():
    lines = (root / "txt" / name).read_text(encoding="utf-8").splitlines()
    assert len(lines) == 7, f"{name}: expected 7 rows, got {len(lines)}"
    actual = {len(line) for line in lines}
    assert actual == {width}, f"{name}: expected width {width}, got {sorted(actual)}"
PY

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

HOME="$tmp_dir/home"
XDG_CONFIG_HOME="$tmp_dir/config"
export HOME XDG_CONFIG_HOME
mkdir -p "$HOME"

# Non-interactive sourcing defines controls without printing the animation.
output=$(bash -c '. "$1/welcome.sh"; welcome status' bash "$project_dir")
[ "$output" = 'Welcome animation is on.' ]

bash -c '. "$1/welcome.sh"; welcome off >/dev/null; welcome status' bash "$project_dir" \
  | grep -Fqx 'Welcome animation is off.'
bash -c '. "$1/welcome.sh"; welcome on >/dev/null; welcome status' bash "$project_dir" \
  | grep -Fqx 'Welcome animation is on.'

HOME="$HOME" sh "$project_dir/install.sh" >/dev/null
HOME="$HOME" sh "$project_dir/install.sh" >/dev/null
[ -r "$HOME/.welcome/welcome.sh" ]
[ "$(grep -Fxc '[ -r "$HOME/.welcome/welcome.sh" ] && . "$HOME/.welcome/welcome.sh"' "$HOME/.zshrc")" -eq 1 ]

printf 'All tests passed.\n'
