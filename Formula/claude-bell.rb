class ClaudeBell < Formula
  desc "Sound notifications for Claude Code"
  homepage "https://github.com/geiz/claude-bell"
  url "https://github.com/geiz/claude-bell/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  def install
    bin.install "bin/claude-bell"
    lib.install Dir["lib/claude-bell"]
    (share/"claude-bell/sounds").install Dir["share/claude-bell/sounds/*"]
    bash_completion.install "completions/claude-bell.bash" => "claude-bell"
    zsh_completion.install "completions/_claude-bell"
  end

  test do
    assert_match "claude-bell", shell_output("#{bin}/claude-bell --version")
  end
end
