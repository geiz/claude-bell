PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/claude-bell
SHAREDIR = $(PREFIX)/share/claude-bell

.PHONY: install uninstall

install:
	@printf 'Installing claude-bell to $(PREFIX)...\n'
	install -d $(BINDIR) $(LIBDIR) $(SHAREDIR)/sounds
	install -m 755 bin/claude-bell $(BINDIR)/claude-bell
	install -m 644 lib/claude-bell/audio.sh $(LIBDIR)/audio.sh
	install -m 644 lib/claude-bell/config.sh $(LIBDIR)/config.sh
	install -m 644 lib/claude-bell/help.sh $(LIBDIR)/help.sh
	install -m 644 share/claude-bell/sounds/done.wav $(SHAREDIR)/sounds/done.wav
	install -m 644 share/claude-bell/sounds/error.wav $(SHAREDIR)/sounds/error.wav
	@if [ -d $(PREFIX)/share/bash-completion/completions ]; then \
		install -m 644 completions/claude-bell.bash $(PREFIX)/share/bash-completion/completions/claude-bell; \
	fi
	@if [ -d $(PREFIX)/share/zsh/site-functions ]; then \
		install -m 644 completions/_claude-bell $(PREFIX)/share/zsh/site-functions/_claude-bell; \
	fi
	@printf 'Done. Run "claude-bell --version" to verify.\n'

uninstall:
	@printf 'Uninstalling claude-bell from $(PREFIX)...\n'
	rm -f $(BINDIR)/claude-bell
	rm -rf $(LIBDIR)
	rm -rf $(SHAREDIR)
	rm -f $(PREFIX)/share/bash-completion/completions/claude-bell
	rm -f $(PREFIX)/share/zsh/site-functions/_claude-bell
	@printf 'Done.\n'
