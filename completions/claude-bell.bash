_claude_bell() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Top-level completions
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        local opts="config test-sound --help --version"
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        return
    fi

    # config subcommand
    if [[ "${COMP_WORDS[1]}" == "config" && ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "init set get list path edit --help" -- "${cur}"))
        return
    fi

    # config set KEY
    if [[ "${COMP_WORDS[1]}" == "config" && "${COMP_WORDS[2]}" == "set" && ${COMP_CWORD} -eq 3 ]]; then
        local keys="CLAUDE_BELL_SOUND CLAUDE_BELL_ERROR_SOUND CLAUDE_BELL_VOLUME CLAUDE_BELL_MUTE CLAUDE_BELL_BACKEND CLAUDE_BELL_NOTIFY CLAUDE_BELL_MIN_DURATION"
        COMPREPLY=($(compgen -W "${keys}" -- "${cur}"))
        return
    fi

    # config get KEY
    if [[ "${COMP_WORDS[1]}" == "config" && "${COMP_WORDS[2]}" == "get" && ${COMP_CWORD} -eq 3 ]]; then
        local keys="CLAUDE_BELL_SOUND CLAUDE_BELL_ERROR_SOUND CLAUDE_BELL_VOLUME CLAUDE_BELL_MUTE CLAUDE_BELL_BACKEND CLAUDE_BELL_NOTIFY CLAUDE_BELL_MIN_DURATION"
        COMPREPLY=($(compgen -W "${keys}" -- "${cur}"))
        return
    fi

    # test-sound: suggest common sound names
    if [[ "${COMP_WORDS[1]}" == "test-sound" && ${COMP_CWORD} -eq 2 ]]; then
        local sounds="default bell none done error"
        # Add macOS system sounds if available
        if [[ -d "/System/Library/Sounds" ]]; then
            local sys_sounds
            sys_sounds=$(ls /System/Library/Sounds/*.aiff 2>/dev/null | sed 's|.*/||;s|\.aiff$||')
            sounds="${sounds} ${sys_sounds}"
        fi
        COMPREPLY=($(compgen -W "${sounds}" -- "${cur}"))
        return
    fi
}

complete -F _claude_bell claude-bell
