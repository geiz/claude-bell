#!/usr/bin/env bash
# claude-bell: audio backend detection, sound resolution, and playback

# Detect the best available audio backend
# Returns: afplay, paplay, aplay, speaker-test, or bell
cb_detect_backend() {
    if [[ "${CLAUDE_BELL_BACKEND}" != "auto" && -n "${CLAUDE_BELL_BACKEND}" ]]; then
        printf '%s' "${CLAUDE_BELL_BACKEND}"
        return
    fi

    if command -v afplay &>/dev/null; then
        printf 'afplay'
    elif command -v paplay &>/dev/null; then
        printf 'paplay'
    elif command -v aplay &>/dev/null; then
        printf 'aplay'
    elif command -v speaker-test &>/dev/null; then
        printf 'speaker-test'
    else
        printf 'bell'
    fi
}

# Resolve a sound name/path to an actual file path
# Arguments: $1 = sound name or path, $2 = type (done|error)
# Returns: file path, "bell", or "none"
cb_resolve_sound() {
    local sound="${1}"
    local type="${2:-done}"

    # Explicit none
    if [[ "${sound}" == "none" ]]; then
        printf 'none'
        return
    fi

    # Terminal bell
    if [[ "${sound}" == "bell" ]]; then
        printf 'bell'
        return
    fi

    # Default → bundled sound
    if [[ "${sound}" == "default" ]]; then
        local bundled
        bundled="$(_cb_find_bundled "${type}.wav")"
        if [[ -n "${bundled}" ]]; then
            printf '%s' "${bundled}"
            return
        fi
        printf 'bell'
        return
    fi

    # Absolute file path
    if [[ "${sound}" == /* && -f "${sound}" ]]; then
        printf '%s' "${sound}"
        return
    fi

    # User custom sounds
    local user_sound="${XDG_CONFIG_HOME:-$HOME/.config}/claude-bell/sounds/${sound}"
    if [[ -f "${user_sound}" ]]; then
        printf '%s' "${user_sound}"
        return
    fi
    # Try with .wav extension
    if [[ -f "${user_sound}.wav" ]]; then
        printf '%s' "${user_sound}.wav"
        return
    fi

    # Bundled sounds by name
    local bundled
    bundled="$(_cb_find_bundled "${sound}")"
    if [[ -n "${bundled}" ]]; then
        printf '%s' "${bundled}"
        return
    fi
    bundled="$(_cb_find_bundled "${sound}.wav")"
    if [[ -n "${bundled}" ]]; then
        printf '%s' "${bundled}"
        return
    fi

    # macOS system sounds
    if [[ "$(uname -s)" == "Darwin" ]]; then
        local sys_sound="/System/Library/Sounds/${sound}.aiff"
        if [[ -f "${sys_sound}" ]]; then
            printf '%s' "${sys_sound}"
            return
        fi
    fi

    # Linux freedesktop sounds
    if [[ "$(uname -s)" == "Linux" ]]; then
        local fd_dirs=(
            "/usr/share/sounds/freedesktop/stereo"
            "/usr/share/sounds/gnome/default/alerts"
        )
        for dir in "${fd_dirs[@]}"; do
            for ext in oga ogg wav; do
                if [[ -f "${dir}/${sound}.${ext}" ]]; then
                    printf '%s' "${dir}/${sound}.${ext}"
                    return
                fi
            done
        done
    fi

    # Fallback to terminal bell
    printf 'bell'
}

# Find a bundled sound file
_cb_find_bundled() {
    local name="${1}"
    local share_dir

    # Check CLAUDE_BELL_HOME if set (from zsh integration or install)
    if [[ -n "${CLAUDE_BELL_HOME:-}" ]]; then
        share_dir="${CLAUDE_BELL_HOME}/share/claude-bell/sounds"
        if [[ -f "${share_dir}/${name}" ]]; then
            printf '%s' "${share_dir}/${name}"
            return
        fi
    fi

    # Check relative to the script location (bash only)
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        share_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/share/claude-bell/sounds"
        if [[ -f "${share_dir}/${name}" ]]; then
            printf '%s' "${share_dir}/${name}"
            return
        fi
    fi

    # Check common install locations
    local dirs=(
        "/usr/local/share/claude-bell/sounds"
        "/usr/share/claude-bell/sounds"
        "${HOMEBREW_PREFIX:-/opt/homebrew}/share/claude-bell/sounds"
    )
    for dir in "${dirs[@]}"; do
        if [[ -f "${dir}/${name}" ]]; then
            printf '%s' "${dir}/${name}"
            return
        fi
    done
}

# Convert volume (0-100) to backend-specific value
_cb_volume_arg() {
    local backend="${1}"
    local volume="${2:-80}"

    case "${backend}" in
        afplay)
            # afplay uses 0.0-1.0 (but really 0-255 internally)
            printf -- '-v %.2f' "$(echo "scale=2; ${volume} / 100" | bc 2>/dev/null || echo "0.80")"
            ;;
        paplay)
            # paplay uses --volume with 0-65536 (100% = 65536)
            local pv
            pv=$(( volume * 655 ))
            printf -- '--volume %d' "${pv}"
            ;;
        *)
            # aplay, speaker-test: no volume control
            printf ''
            ;;
    esac
}

# Play a sound file or bell
# Arguments: $1 = resolved sound (path, "bell", or "none")
cb_play() {
    local sound="${1}"
    local volume="${CLAUDE_BELL_VOLUME:-80}"

    if [[ "${sound}" == "none" ]]; then
        return 0
    fi

    if [[ "${sound}" == "bell" ]]; then
        printf '\a'
        return 0
    fi

    if [[ ! -f "${sound}" ]]; then
        printf '\a'
        return 1
    fi

    local backend
    backend="$(cb_detect_backend)"

    local pitch="${CLAUDE_BELL_PITCH:-1.0}"

    # Play in background subshell so prompt returns immediately
    (
        case "${backend}" in
            afplay)
                local vol
                vol="$(echo "scale=2; ${volume} / 100" | bc 2>/dev/null || echo "0.80")"
                afplay -v "${vol}" -r "${pitch}" "${sound}" &>/dev/null
                ;;
            paplay)
                local pv=$(( volume * 655 ))
                if command -v sox &>/dev/null && [[ "${pitch}" != "1.0" && "${pitch}" != "1" ]]; then
                    # Use sox to pitch-shift, then pipe to paplay
                    local semitones
                    semitones="$(echo "scale=4; l(${pitch})/l(2)*12" | bc -l 2>/dev/null || echo "0")"
                    sox "${sound}" -t wav - pitch "${semitones}" 2>/dev/null | paplay --volume "${pv}" &>/dev/null
                else
                    paplay --volume "${pv}" "${sound}" &>/dev/null
                fi
                ;;
            aplay)
                if command -v sox &>/dev/null && [[ "${pitch}" != "1.0" && "${pitch}" != "1" ]]; then
                    local semitones
                    semitones="$(echo "scale=4; l(${pitch})/l(2)*12" | bc -l 2>/dev/null || echo "0")"
                    sox "${sound}" -t wav - pitch "${semitones}" 2>/dev/null | aplay -q &>/dev/null
                else
                    aplay -q "${sound}" &>/dev/null
                fi
                ;;
            speaker-test)
                speaker-test -t wav -w "${sound}" -l 1 &>/dev/null
                ;;
            bell|*)
                printf '\a'
                ;;
        esac
    ) &
    disown 2>/dev/null
}

# Send a desktop notification if enabled
cb_notify() {
    local title="${1}"
    local message="${2}"

    if [[ "${CLAUDE_BELL_NOTIFY}" != "true" ]]; then
        return
    fi

    if [[ "$(uname -s)" == "Darwin" ]]; then
        osascript -e "display notification \"${message}\" with title \"${title}\"" &>/dev/null &
        disown 2>/dev/null
    elif command -v notify-send &>/dev/null; then
        notify-send "${title}" "${message}" &>/dev/null &
        disown 2>/dev/null
    fi
}
