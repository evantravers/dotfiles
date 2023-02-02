ifeq ($(uname -p), 'arm')
BREW_BIN      := /opt/homebrew/bin
else
BREW_BIN      := /usr/local/bin
endif

XDG_DATA_HOME := $(HOME)/.local/share

ASDF          := $(HOME)/.asdf/bin/asdf
BREW          := $(BREW_BIN)/brew
STOW          := $(BREW_BIN)/stow
NVIM          := $(BREW_BIN)/nvim
GIT           := $(BREW_BIN)/git
PAQ           := $(XDG_DATA_HOME)/nvim/site/pack/paqs/start/paq-nvim
TPM           := $(HOME)/.config/tmux/plugins/tpm
DOOM          := $(HOME)/.emacs.d

STOW_PKGS     := emacs fish git kitty nvim starship tmux
BREW_PKGS     := $(STOW) $(NVIM) $(GIT)

.PHONY: default dots mac
.DEFAULT_GOAL := dots

dots: | $(STOW)
	$(STOW) $(STOW_PKGS)
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo

install: dots $(PAQ) $(ASDF) $(TPM) $(DOOM)

mac:
	./macos

$(BREW):
	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

$(BREW_PKGS): | $(BREW)
	$(BREW) bundle

$(ASDF): | $(GIT)
	$(GIT) clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	$(GIT) checkout "$($(GIT) describe --abbrev=0 --tags)"

$(PAQ): | $(NVIM) $(GIT)
	$(GIT) clone --depth=1 https://github.com/savq/paq-nvim.git $(PAQ)
	$(NVIM) +PaqInstall +qall

$(TPM): | $(GIT)
	mkdir -p $@
	$(GIT) clone https://github.com/tmux-plugins/tpm $(HOME)/.config/tmux/plugins/tpm
	$(TPM)/bin/install_plugins

$(DOOM): | $(GIT)
	$(GIT) clone https://github.com/hlissner/doom-emacs $(HOME)/.emacs.d
	$(HOME)/.emacs.d/bin/doom install
