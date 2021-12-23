BREW_BIN      := /usr/local/bin
XDG_DATA_HOME := $(HOME)/.local/share

ASDF          := $(HOME)/.asdf/bin/asdf
BREW          := $(BREW_BIN)/brew
STOW          := $(BREW_BIN)/stow
NVIM          := $(BREW_BIN)/nvim
GIT           := $(BREW_BIN)/git
PAQ           := $(XDG_DATA_HOME)/nvim/site/pack/paqs/start/paq-nvim
TPM           := $(HOME)/.config/tmux/plugins/tpm
DOOM          := $(HOME)/.emacs.d

LSP_DIR       := $(XDG_DATA_HOME)/lsp
LSP_ELIXIR    := $(LSP_DIR)/elixir-ls

STOW_PKGS     := emacs fish git kitty nvim starship tmux
BREW_PKGS     := $(STOW) $(NVIM) $(GIT)

.PHONY: default dots mac
.DEFAULT_GOAL := dots

dots: | $(STOW)
	$(STOW) $(STOW_PKGS)
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo

install: mac dots $(PAQ) $(ASDF) $(TPM) $(LSP_ELIXIR) $(DOOM)

mac:
	./macos

$(BREW):
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

$(BREW_PKGS):
	$(BREW) bundle

$(ASDF): | $(GIT)
	$(GIT) clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	$(GIT) checkout "$($(GIT) describe --abbrev=0 --tags)"

$(PAQ): | $(NVIM) $(GIT)
	git clone --depth=1 https://github.com/savq/paq-nvim.git \
		"$(XDG_DATA_HOME)"/nvim/site/pack/paqs/start/paq-nvim
	$(NVIM) +PaqInstall +qall

$(LSP_DIR) $(TPM_DIR):
	mkdir -p $@

$(LSP_ELIXIR): | $(LSP_DIR)
	curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
	unzip elixir-ls.zip -d $(XDG_DATA_HOME)/lsp/elixir-ls
	chmod +x $(XDG_DATA_HOME)/lsp/elixir-ls/language_server.sh
	rm elixir-ls.zip

$(TPM): | $(GIT)
	mkdir -p $@
	$(GIT) clone https://github.com/tmux-plugins/tpm $(HOME)/.config/tmux/plugins/tpm

$(DOOM): | $(GIT)
	$(GIT) clone https://github.com/hlissner/doom-emacs $(HOME)/.emacs.d
	$(HOME)/.emacs.d/bin/doom install
