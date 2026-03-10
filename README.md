# claude-bell

Sound notifications for Claude Code — know when Claude is done without watching your terminal.

Works on macOS and Linux (including WSL).

## Install

### From source

```bash
git clone https://github.com/geiz/claude-bell.git
cd claude-bell
make install
```

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/geiz/claude-bell/main/install.sh | bash
```

By default, installs to `/usr/local`. Set `PREFIX` to change:

```bash
make install PREFIX=~/.local
```

## Usage

### Option 1: Wrapper command

Run Claude through `claude-bell` — it plays a sound when Claude finishes:

```bash
claude-bell                    # interactive mode
claude-bell -p "fix the bug"   # print mode
```

### Option 2: Zsh integration

Source the zsh integration in your `.zshrc` to automatically wrap the `claude` command:

```bash
source /usr/local/lib/claude-bell/claude-bell.zsh
```

Then just use `claude` as normal — sounds play automatically.

### Option 3: Claude Code hook

Use `claude-bell-hook` as a [Claude Code stop hook](https://docs.anthropic.com/en/docs/claude-code/hooks) to play a sound whenever Claude finishes responding:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "claude-bell-hook" }]
      }
    ]
  }
}
```

### Test sound

```bash
claude-bell test-sound          # play default sound
claude-bell test-sound Glass    # play a macOS system sound
```

## Configuration

Config file: `~/.config/claude-bell/config`

```bash
claude-bell config init         # create config with defaults
claude-bell config list         # show current values
claude-bell config set KEY VAL  # set a value
claude-bell config get KEY      # get a value
claude-bell config edit         # open in $EDITOR
```

### Options

| Key | Default | Description |
|-----|---------|-------------|
| `CLAUDE_BELL_SOUND` | `default` | Sound on success: `default`, `bell`, `none`, file path, or macOS/freedesktop sound name |
| `CLAUDE_BELL_ERROR_SOUND` | `error` | Sound on error |
| `CLAUDE_BELL_VOLUME` | `80` | Volume (0-100) |
| `CLAUDE_BELL_MUTE` | `false` | Mute all sounds |
| `CLAUDE_BELL_BACKEND` | `auto` | Audio backend: `auto`, `afplay`, `paplay`, `aplay`, `speaker-test`, `bell` |
| `CLAUDE_BELL_NOTIFY` | `false` | Show desktop notification alongside sound |
| `CLAUDE_BELL_MIN_DURATION` | `0` | Only play sound if Claude ran for at least N seconds |
| `CLAUDE_BELL_PITCH` | `1.0` | Pitch multiplier (0.5 = low, 1.0 = normal, 2.0 = high) |

### Precedence

Environment variables > config file > defaults

```bash
CLAUDE_BELL_PITCH=1.5 claude-bell -p "hi"   # one-off override
```

### Custom sounds

Drop `.wav` files into `~/.config/claude-bell/sounds/` and reference them by name:

```bash
claude-bell config set CLAUDE_BELL_SOUND my-chime
```

## Audio backends

Detected automatically:

| Platform | Backend |
|----------|---------|
| macOS | `afplay` (built-in) |
| Linux | `paplay` > `aplay` > `speaker-test` |
| Fallback | Terminal bell (`\a`) |

Pitch shifting on Linux requires [SoX](https://sox.sourceforge.net/) (`sudo apt install sox`).

## Uninstall

```bash
make uninstall
```

## License

[MIT](LICENSE)

## Contributors

- [David S](https://github.com/geiz)

Built with [Claude Code](https://claude.ai/claude-code)
