BREW      := $(shell brew --version 2>/dev/null)
CLI_TOOLS := $(xcode-select --install 2>&1 | grep installed;)

default:
	make stow

stow:
	stow git
	stow kitty
	stow nvim
	stow tmux
	stow zsh

install:
ifndef CLI_TOOLS
	echo "CLI Tools are installed!"
else
	xcode-select --install
endif

ifndef BREW
	echo "Homebrew isn't installed... installing..."
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
else
	echo "Homebrew is installed!"
endif

	brew bundle
	make stow

	curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	nvim +PlugInstall +qall

ifeq ($(wildcard ~/.tmux/plugins/tpm/.),)
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
endif

ifeq ($(wildcard ~/.asdf/.),)
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	git checkout "$(git describe --abbrev=0 --tags)"
endif
