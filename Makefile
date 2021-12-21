BREW      := $(shell brew --version 2>/dev/null)
CLI_TOOLS := $(xcode-select --install 2>&1 | grep installed;)

.PHONY: tmux asdf emacs nvim

default:
	make dots

dots:
	stow fish
	stow git
	stow kitty
	stow starship

xcode:
ifndef CLI_TOOLS
else
	xcode-select --install
endif

brew:
ifndef BREW
	echo "Homebrew isn't installed... installing..."
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
else
endif
	# install brew bundles
	brew bundle

mac:
	./macos

nvim:
	stow nvim
ifeq ($(wildcard ~/.local/share/nvim/site/pack/paqs/opt/paq-nvim/.*),)
	# setup vim
	git clone https://github.com/savq/paq-nvim.git \
			"$${XDG_DATA_HOME:-$$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim || true
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo
	nvim +PaqInstall +qall
endif

asdf:
ifeq ($(wildcard ~/.asdf/.*),)
	# install asdf
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	git checkout "$(git describe --abbrev=0 --tags)"
endif

lsp:
	# setup LSP
ifeq ($(wildcard ~/.config/lsp/.*),)
	mkdir -p ~/.config/lsp/
endif
ifeq ($(wildcard ~/.config/lsp/elixir-ls/.*),)
	# elixir
	curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
	unzip elixir-ls.zip -d ~/.config/lsp/elixir-ls
	chmod +x ~/.config/lsp/elixir-ls/language_server.sh
	rm elixir-ls.zip
endif

tmux:
	stow tmux
ifeq ($(wildcard ~/.config/tmux/plugins/tpm/.*),)
	# clone in tmux plugins
	git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
endif

emacs:
	stow emacs
	# install doom
	git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install

install:
	make xcode
	make brew
	make mac
	make dots
	make asdf
	make tmux
	make lsp
	make emacs
