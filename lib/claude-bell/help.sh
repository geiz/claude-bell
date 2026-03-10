#!/usr/bin/env bash
# claude-bell: help text and version

CLAUDE_BELL_VERSION="0.1.0"

cb_version() {
    printf 'claude-bell %s\n' "${CLAUDE_BELL_VERSION}"
}

cb_help() {
    cat << EOF
claude-bell ${CLAUDE_BELL_VERSION} — Sound notifications for Claude Code

Usage:
  claude-bell [claude args...]     Run claude and play sound on completion
  claude-bell config <action>      Manage configuration
  claude-bell test-sound [name]    Test sound playback
  claude-bell --help               Show this help
  claude-bell --version            Show version

Examples:
  claude-bell                      Start claude interactively, bell when done
  claude-bell -p "hello"           Run claude in print mode, bell when done
  claude-bell test-sound           Play the default completion sound
  claude-bell test-sound Glass     Play a macOS system sound
  claude-bell config init          Create config file with defaults
  claude-bell config set CLAUDE_BELL_SOUND Glass
  CLAUDE_BELL_PITCH=1.5 claude-bell -p "hi"   # Higher pitch for this terminal

Config:
  File: ~/.config/claude-bell/config
  Override any setting with environment variables.
  Run "claude-bell config --help" for details.

Audio backends (auto-detected):
  macOS:  afplay (built-in)
  Linux:  paplay > aplay > speaker-test
  Any:    terminal bell (fallback)

Sound names:
  "default"   Bundled chime
  "bell"      Terminal bell character
  "none"      Silence
  <path>      Absolute path to audio file
  <name>      macOS system sound or freedesktop sound name
EOF
}
