# Multilingual terminal welcome animation for zsh and Bash.

: "${TERMINAL_WELCOME_HOME:=$HOME/.welcome}"

_terminal_welcome_state_file() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/terminal-welcome/state"
}

_terminal_welcome_is_enabled() {
  local state_file
  state_file="$(_terminal_welcome_state_file)"

  [ ! -r "$state_file" ] || [ "$(sed -n '1p' "$state_file")" != "off" ]
}

_terminal_welcome_save_state() {
  local state state_file state_dir
  state="$1"
  state_file="$(_terminal_welcome_state_file)"
  state_dir="${state_file%/*}"

  if ! mkdir -p "$state_dir"; then
    printf 'welcome: unable to create config directory: %s\n' "$state_dir" >&2
    return 1
  fi

  if ! printf '%s\n' "$state" > "$state_file"; then
    printf 'welcome: unable to save state: %s\n' "$state_file" >&2
    return 1
  fi
}

welcome() {
  case "${1-}" in
    on)
      _terminal_welcome_save_state on || return 1
      printf 'Welcome animation enabled. It will appear in new terminal sessions.\n'
      ;;
    off)
      _terminal_welcome_save_state off || return 1
      printf 'Welcome animation disabled. It will not appear in new terminal sessions.\n'
      ;;
    status)
      if _terminal_welcome_is_enabled; then
        printf 'Welcome animation is on.\n'
      else
        printf 'Welcome animation is off.\n'
      fi
      ;;
    *)
      printf 'Usage: welcome {on|off|status}\n' >&2
      return 2
      ;;
  esac
}

_terminal_welcome_columns() {
  local columns
  columns="${COLUMNS:-0}"

  case "$columns" in
    ''|*[!0-9]*) columns=0 ;;
  esac

  if [ "$columns" -le 0 ] && command -v tput >/dev/null 2>&1; then
    columns="$(tput cols 2>/dev/null)"
    case "$columns" in
      ''|*[!0-9]*) columns=0 ;;
    esac
  fi

  [ "$columns" -gt 0 ] || columns=80
  printf '%s\n' "$columns"
}

_terminal_welcome_draw_art() {
  local art_file art_width canvas_width padding line
  art_file="$1"
  art_width="$2"
  canvas_width="$3"
  padding=$(( (canvas_width - art_width) / 2 ))

  while IFS= read -r line || [ -n "$line" ]; do
    printf '\r\033[2K%*s%s\n' "$padding" '' "$line"
  done < "$art_file"
}

_terminal_welcome_draw_frame() {
  local greeting_file greeting_width canvas_width
  greeting_file="$1"
  greeting_width="$2"
  canvas_width="$3"

  _terminal_welcome_draw_art "$greeting_file" "$greeting_width" "$canvas_width"
  printf '\r\033[2K\n'
  _terminal_welcome_draw_art "$TERMINAL_WELCOME_HOME/txt/yafi.txt" 25 "$canvas_width"
}

_terminal_welcome_shuffle() {
  local record index
  index=0
  for record do
    index=$((index + 1))
    printf '%s %s %s\n' "${RANDOM:-0}" "$index" "$record"
  done | sort -n -k1,1 -k2,2 | sed 's/^[^ ]* [^ ]* //'
}

_terminal_welcome_restore_cursor() {
  printf '\033[?25h'
}

_terminal_welcome_animate() (
  local columns canvas_width record width filename shuffled first
  columns="$(_terminal_welcome_columns)"

  if [ "$columns" -lt 63 ]; then
    printf 'Welcome Yafi\n'
    return
  fi

  canvas_width="$columns"
  [ "$canvas_width" -le 81 ] || canvas_width=81

  set --
  for record in \
    '31:welcomeArabic.txt' \
    '31:welcomeChinese.txt' \
    '58:welcomeFrench.txt' \
    '81:welcomeGerman.txt' \
    '47:welcomeHindi.txt' \
    '77:welcomeSpanish.txt'
  do
    width="${record%%:*}"
    if [ "$width" -le "$canvas_width" ]; then
      set -- "$@" "$record"
    fi
  done

  trap '_terminal_welcome_restore_cursor' EXIT
  trap 'exit 130' HUP INT TERM
  printf '\033[?25l'

  shuffled="$(_terminal_welcome_shuffle "$@")"
  first=1
  while IFS=: read -r width filename; do
    [ -n "$filename" ] || continue
    if [ "$first" -eq 0 ]; then
      printf '\033[15A\r'
    fi
    _terminal_welcome_draw_frame \
      "$TERMINAL_WELCOME_HOME/txt/$filename" "$width" "$canvas_width"
    sleep 0.25
    first=0
  done <<EOF
$shuffled
EOF

  if [ "$first" -eq 0 ]; then
    printf '\033[15A\r'
  fi
  _terminal_welcome_draw_frame \
    "$TERMINAL_WELCOME_HOME/txt/welcomeEnglish.txt" 63 "$canvas_width"
)

_terminal_welcome_assets_are_readable() {
  local asset
  for asset in \
    welcomeArabic.txt welcomeChinese.txt welcomeEnglish.txt \
    welcomeFrench.txt welcomeGerman.txt welcomeHindi.txt \
    welcomeSpanish.txt yafi.txt
  do
    [ -r "$TERMINAL_WELCOME_HOME/txt/$asset" ] || return 1
  done
}

case $- in
  *i*)
    if [ -t 1 ] && _terminal_welcome_is_enabled; then
      if [ "${TERM:-dumb}" = dumb ]; then
        printf 'Welcome Yafi\n'
      elif _terminal_welcome_assets_are_readable; then
        _terminal_welcome_animate
      fi
    fi
    ;;
esac
