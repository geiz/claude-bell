#!/usr/bin/env bash
# claude-bell: configuration loading and config subcommand

CLAUDE_BELL_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude-bell"
CLAUDE_BELL_CONFIG_FILE="${CLAUDE_BELL_CONFIG_DIR}/config"

# Default values
_CB_DEFAULTS=(
    CLAUDE_BELL_SOUND=default
    CLAUDE_BELL_ERROR_SOUND=error
    CLAUDE_BELL_VOLUME=80
    CLAUDE_BELL_MUTE=false
    CLAUDE_BELL_BACKEND=auto
    CLAUDE_BELL_NOTIFY=false
    CLAUDE_BELL_MIN_DURATION=0
    CLAUDE_BELL_PITCH=1.0
)

# Portable indirect variable check (works in both bash and zsh)
_cb_is_set() { eval "[ -n \"\${${1}+x}\" ]"; }
_cb_get_var() { eval "printf '%s' \"\${${1}:-}\""; }

# Load config: defaults < config file < env vars
cb_load_config() {
    # Track which keys were already set in the environment (before we touch anything)
    local pair key val
    local _cb_env_keys=""
    for pair in "${_CB_DEFAULTS[@]}"; do
        key="${pair%%=*}"
        if _cb_is_set "${key}"; then
            _cb_env_keys="${_cb_env_keys} ${key}"
        fi
    done

    # Apply defaults for any unset variable
    for pair in "${_CB_DEFAULTS[@]}"; do
        key="${pair%%=*}"
        val="${pair#*=}"
        if ! _cb_is_set "${key}"; then
            export "${key}=${val}"
        fi
    done

    # Source config file — overrides defaults but not env vars
    if [[ -f "${CLAUDE_BELL_CONFIG_FILE}" ]]; then
        local config_vars
        config_vars="$(grep -E '^[A-Z_]+=.*' "${CLAUDE_BELL_CONFIG_FILE}" 2>/dev/null || true)"
        while IFS='=' read -r key val; do
            [[ -z "${key}" ]] && continue
            # Remove surrounding quotes from val
            val="${val#\"}"
            val="${val%\"}"
            val="${val#\'}"
            val="${val%\'}"
            # Only set if not already in environment before we started
            case "${_cb_env_keys}" in
                *" ${key}"*) ;;  # already set via env, skip
                *) export "${key}=${val}" ;;
            esac
        done <<< "${config_vars}"
    fi
}

# Config subcommand handler
cb_config_cmd() {
    local action="${1:-}"
    shift 2>/dev/null || true

    case "${action}" in
        init)
            _cb_config_init "$@"
            ;;
        set)
            _cb_config_set "$@"
            ;;
        get)
            _cb_config_get "$@"
            ;;
        list)
            _cb_config_list
            ;;
        path)
            printf '%s\n' "${CLAUDE_BELL_CONFIG_FILE}"
            ;;
        edit)
            "${EDITOR:-vi}" "${CLAUDE_BELL_CONFIG_FILE}"
            ;;
        ""|help|--help)
            _cb_config_help
            ;;
        *)
            printf 'Unknown config action: %s\n' "${action}" >&2
            _cb_config_help >&2
            return 1
            ;;
    esac
}

_cb_config_init() {
    if [[ -f "${CLAUDE_BELL_CONFIG_FILE}" ]]; then
        printf 'Config already exists at %s\n' "${CLAUDE_BELL_CONFIG_FILE}"
        printf 'Use "claude-bell config edit" to modify it.\n'
        return
    fi

    mkdir -p "${CLAUDE_BELL_CONFIG_DIR}"
    cat > "${CLAUDE_BELL_CONFIG_FILE}" << 'CONF'
# claude-bell configuration
# Docs: claude-bell config --help

# Sound to play on success: "default", "bell", "none", file path, or macOS sound name
CLAUDE_BELL_SOUND=default

# Sound to play on error
CLAUDE_BELL_ERROR_SOUND=error

# Volume: 0-100
CLAUDE_BELL_VOLUME=80

# Mute all sounds
CLAUDE_BELL_MUTE=false

# Audio backend: auto, afplay, paplay, aplay, speaker-test, bell
CLAUDE_BELL_BACKEND=auto

# Show desktop notification alongside sound
CLAUDE_BELL_NOTIFY=false

# Only bell if claude ran for at least N seconds
CLAUDE_BELL_MIN_DURATION=0

# Pitch multiplier: 0.5 = low, 1.0 = normal, 2.0 = high
# Useful for distinguishing multiple terminals
CLAUDE_BELL_PITCH=1.0
CONF

    printf 'Created config at %s\n' "${CLAUDE_BELL_CONFIG_FILE}"
}

_cb_config_set() {
    local key="${1:-}"
    local val="${2:-}"

    if [[ -z "${key}" || -z "${val}" ]]; then
        printf 'Usage: claude-bell config set KEY VALUE\n' >&2
        return 1
    fi

    # Validate key
    case "${key}" in
        CLAUDE_BELL_SOUND|CLAUDE_BELL_ERROR_SOUND|CLAUDE_BELL_VOLUME|\
        CLAUDE_BELL_MUTE|CLAUDE_BELL_BACKEND|CLAUDE_BELL_NOTIFY|\
        CLAUDE_BELL_MIN_DURATION|CLAUDE_BELL_PITCH) ;;
        *)
            printf 'Unknown config key: %s\n' "${key}" >&2
            return 1
            ;;
    esac

    mkdir -p "${CLAUDE_BELL_CONFIG_DIR}"

    if [[ -f "${CLAUDE_BELL_CONFIG_FILE}" ]] && grep -q "^${key}=" "${CLAUDE_BELL_CONFIG_FILE}" 2>/dev/null; then
        # Update existing key
        local tmp
        tmp="$(mktemp)"
        sed "s|^${key}=.*|${key}=${val}|" "${CLAUDE_BELL_CONFIG_FILE}" > "${tmp}"
        mv "${tmp}" "${CLAUDE_BELL_CONFIG_FILE}"
    else
        # Append new key
        printf '%s=%s\n' "${key}" "${val}" >> "${CLAUDE_BELL_CONFIG_FILE}"
    fi

    printf 'Set %s=%s\n' "${key}" "${val}"
}

_cb_config_get() {
    local key="${1:-}"
    if [[ -z "${key}" ]]; then
        printf 'Usage: claude-bell config get KEY\n' >&2
        return 1
    fi
    printf '%s\n' "$(_cb_get_var "${key}")"
}

_cb_config_list() {
    printf 'Current configuration:\n\n'
    local pair key
    for pair in "${_CB_DEFAULTS[@]}"; do
        key="${pair%%=*}"
        printf '  %s=%s\n' "${key}" "$(_cb_get_var "${key}")"
    done
    printf '\nConfig file: %s\n' "${CLAUDE_BELL_CONFIG_FILE}"
    if [[ -f "${CLAUDE_BELL_CONFIG_FILE}" ]]; then
        printf '(file exists)\n'
    else
        printf '(not created yet — run "claude-bell config init")\n'
    fi
}

_cb_config_help() {
    cat << 'EOF'
Usage: claude-bell config <action> [args]

Actions:
  init              Create config file with defaults
  set KEY VALUE     Set a config value
  get KEY           Get a config value
  list              Show all current values
  path              Print config file path
  edit              Open config in $EDITOR

Config keys:
  CLAUDE_BELL_SOUND          Sound on success (default, bell, none, path, or name)
  CLAUDE_BELL_ERROR_SOUND    Sound on error
  CLAUDE_BELL_VOLUME         Volume 0-100
  CLAUDE_BELL_MUTE           Mute all sounds (true/false)
  CLAUDE_BELL_BACKEND        Audio backend (auto, afplay, paplay, aplay, speaker-test, bell)
  CLAUDE_BELL_NOTIFY         Desktop notification (true/false)
  CLAUDE_BELL_MIN_DURATION   Min claude runtime in seconds before playing sound
  CLAUDE_BELL_PITCH          Pitch multiplier (0.5=low, 1.0=normal, 2.0=high)

Precedence: environment variables > config file > defaults
EOF
}
