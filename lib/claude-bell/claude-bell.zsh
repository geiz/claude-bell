#!/usr/bin/env zsh
# claude-bell: zsh integration
# Source this file in .zshrc to wrap `claude` with sound notifications.
# The claude() function runs in-process, so it survives Claude Code's exit.

# Resolve the lib directory relative to this file
CLAUDE_BELL_HOME="${0:A:h:h:h}"

# Source library files (bash-compatible)
source "${CLAUDE_BELL_HOME}/lib/claude-bell/config.sh"
source "${CLAUDE_BELL_HOME}/lib/claude-bell/audio.sh"
source "${CLAUDE_BELL_HOME}/lib/claude-bell/help.sh"

# Override `claude` with a function that plays a sound on exit
claude() {
    # Handle claude-bell subcommands
    case "${1:-}" in
        --cb-test-sound)
            shift
            cb_load_config
            local sound_name="${1:-default}"
            local resolved="$(cb_resolve_sound "${sound_name}" "done")"
            local backend="$(cb_detect_backend)"
            printf 'Backend: %s\n' "${backend}"
            printf 'Sound:   %s → %s\n' "${sound_name}" "${resolved}"
            printf 'Pitch:   %s\n' "${CLAUDE_BELL_PITCH}"
            printf 'Playing...\n'
            cb_play "${resolved}"
            return 0
            ;;
        --cb-config)
            shift
            cb_load_config
            cb_config_cmd "$@"
            return $?
            ;;
        --cb-version)
            cb_version
            return 0
            ;;
        --cb-help)
            cb_help
            printf '\nclaude-bell flags (prefix with --cb-):\n'
            printf '  claude --cb-test-sound [name]   Test sound playback\n'
            printf '  claude --cb-config <action>     Manage config\n'
            printf '  claude --cb-version             Show claude-bell version\n'
            printf '  claude --cb-help                Show this help\n'
            return 0
            ;;
    esac

    # Load config fresh each invocation (picks up env var changes)
    cb_load_config

    local _cb_start=$(date +%s)

    # Run the real claude binary
    command claude "$@"
    local _cb_exit=$?

    # Calculate duration
    local _cb_duration=$(( $(date +%s) - _cb_start ))

    # Check mute
    [[ "${CLAUDE_BELL_MUTE}" == "true" ]] && return $_cb_exit

    # Check minimum duration
    [[ "$_cb_duration" -lt "${CLAUDE_BELL_MIN_DURATION}" ]] && return $_cb_exit

    # Play appropriate sound
    if [[ $_cb_exit -eq 0 ]]; then
        cb_play "$(cb_resolve_sound "${CLAUDE_BELL_SOUND}" "done")"
        cb_notify "Claude finished" "Command completed successfully"
    else
        cb_play "$(cb_resolve_sound "${CLAUDE_BELL_ERROR_SOUND}" "error")"
        cb_notify "Claude failed" "Command exited with code ${_cb_exit}"
    fi

    return $_cb_exit
}
