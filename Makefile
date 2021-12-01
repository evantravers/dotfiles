BREW      := $(shell brew --version 2>/dev/null)
CLI_TOOLS := $(xcode-select --install 2>&1 | grep installed;)

.PHONY: tmux asdf emacs

default:
	make stow

stow:
	stow fish
	stow git
	stow kitty
	stow nvim
	stow tmux
	stow emacs
	stow starship

install:
	./macos

ifndef CLI_TOOLS
else
	xcode-select --install
endif

ifndef BREW
	echo "Homebrew isn't installed... installing..."
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
else
endif

	# install brew bundles
	brew bundle

	# symlink dotfiles
	make stow

ifeq ($(wildcard ~/.local/share/nvim/site/pack/paqs/opt/paq-nvim/.*),)
	# setup vim
	git clone https://github.com/savq/paq-nvim.git \
			"$${XDG_DATA_HOME:-$$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim || true
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo
	nvim +PaqInstall +qall
endif

	make asdf
	make tmux
	make lsp
	make emacs

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
ifeq ($(wildcard ~/.config/lsp/lua-language-server/.*),)
	# lua
	brew install ninja
	git clone https://github.com/sumneko/lua-language-server ~/.config/lsp/lua-language-server
	cd ~/.config/lsp/lua-language-server && git submodule update --init --recursive
	cd ~/.config/lsp/lua-language-server/3rd/luamake && compile/install.sh
	cd ~/.config/lsp/lua-language-server/ && ./3rd/luamake/luamake rebuild
endif

tmux:
	stow tmux
ifeq ($(wildcard ~/.config/tmux/plugins/tpm/.*),)
	# clone in tmux plugins
	git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
endif

asdf:
ifeq ($(wildcard ~/.asdf/.*),)
	# install asdf
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	git checkout "$(git describe --abbrev=0 --tags)"
endif

emacs:
	stow emacs
	# install doom
	git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install
