BREW      := $(shell brew --version 2>/dev/null)
CLI_TOOLS := $(xcode-select --install 2>&1 | grep installed;)

.PHONY: tmux asdf emacs nvim

default: dots

dots:
	stow emacs
	stow fish
	stow git
	stow kitty
	stow nvim
	stow starship
	stow tmux

xcode:
	# xcode:
ifndef CLI_TOOLS
else
	# xcode cli tools…
	xcode-select --install
endif

brew:
	# brew:
ifndef BREW
	echo "Homebrew isn't installed… installing…"
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
else
endif
	# brew bundle…
	brew bundle

mac:
	./macos

nvim: dots
	# nvim:
ifeq ($(wildcard ~/.local/share/nvim/site/pack/paqs/opt/paq-nvim/.*),)
	# paq…
	git clone https://github.com/savq/paq-nvim.git \
			"$${XDG_DATA_HOME:-$$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim || true
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo
	nvim +PaqInstall +qall
endif

asdf:
	# asdf:
ifeq ($(wildcard ~/.asdf/.*),)
	# installing…
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	git checkout "$(git describe --abbrev=0 --tags)"
endif

lsp:
	# lsp servers:
ifeq ($(wildcard ~/.config/lsp/.*),)
	mkdir -p ~/.config/lsp/
endif
ifeq ($(wildcard ~/.config/lsp/elixir-ls/.*),)
	# elixir…
	curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
	unzip elixir-ls.zip -d ~/.config/lsp/elixir-ls
	chmod +x ~/.config/lsp/elixir-ls/language_server.sh
	rm elixir-ls.zip
endif

tmux: dots
	# tmux:
ifeq ($(wildcard ~/.config/tmux/plugins/tpm/.*),)
	# plugins…
	git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
endif

emacs: dots
	# emacs doom:
ifeq ($(wildcard ~/.emacs.d),)
	# cloning…
	git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install
endif

install: xcode brew mac dots asdf tmux lsp emacs
