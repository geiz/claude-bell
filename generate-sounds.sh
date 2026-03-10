#!/usr/bin/env bash
set -euo pipefail

# Generate default sound files for claude-bell using sox
# sox is only needed for development — the generated WAVs are committed to the repo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUNDS_DIR="${SCRIPT_DIR}/share/claude-bell/sounds"

mkdir -p "${SOUNDS_DIR}"

if ! command -v sox &>/dev/null; then
    printf 'Error: sox is required to generate sounds.\n' >&2
    printf 'Install it with: brew install sox  (macOS) or apt install sox  (Linux)\n' >&2
    exit 1
fi

printf 'Generating done.wav (ascending chime C5→E5)...\n'
# Two-tone ascending chime: C5 (523Hz) then E5 (659Hz)
sox -n -r 44100 -c 1 -b 16 "${SOUNDS_DIR}/done.wav" \
    synth 0.15 sine 523 fade 0 0.15 0.05 : \
    synth 0.2  sine 659 fade 0 0.2  0.08 \
    vol 0.6

printf 'Generating error.wav (descending tone E4→C4)...\n'
# Two-tone descending: E4 (330Hz) then C4 (262Hz)
sox -n -r 44100 -c 1 -b 16 "${SOUNDS_DIR}/error.wav" \
    synth 0.15 sine 330 fade 0 0.15 0.05 : \
    synth 0.25 sine 262 fade 0 0.25 0.1 \
    vol 0.6

printf 'Done. Files:\n'
ls -lh "${SOUNDS_DIR}"/*.wav
