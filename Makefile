BREW_BIN   := /usr/local/bin

ASDF       := $(HOME)/.asdf/bin/asdf
BREW       := $(BREW_BIN)/brew
STOW       := $(BREW_BIN)/stow
NVIM       := $(BREW_BIN)/nvim
GIT        := $(BREW_BIN)/git
PAQ        := $(HOME)/.local/share/nvim/site/pack/paqs/opt/paq-nvim
TPM        := $(HOME)/.config/tmux/plugins/tpm
DOOM       := $(HOME)/.emacs.d

LSP_DIR    := $(HOME)/.config/lsp
LSP_ELIXIR := $(LSP_DIR)/elixir-ls

STOW_PKGS  := emacs fish git kitty nvim starship tmux
BREW_PKGS  := $(STOW) $(NVIM) $(GIT)

.PHONY: default tmux asdf emacs $(NVIM) dots

default: dots

dots: $(STOW)
	$(STOW) $(STOW_PKGS)
	mkdir -p ~/.config/nvim/backups ~/.config/nvim/swaps ~/.config/nvim/undo # FIXME

$(BREW_PKGS):
	$(BREW) bundle

$(BREW):
	/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \

mac:
	./macos

$(PAQ): $(NVIM) $(GIT)
	$(GIT) clone https://github.com/savq/paq-nvim.git \
			"$${XDG_DATA_HOME:-$$HOME/.local/share}"/nvim/site/pack/paqs/opt/paq-nvim || true
	$(NVIM) +PaqInstall +qall

$(ASDF): $(GIT)
	$(GIT) clone https://github.com/asdf-vm/asdf.git ~/.asdf
	cd ~/.asdf
	$(GIT) checkout "$($(GIT) describe --abbrev=0 --tags)"

$(LSP_DIR) $(TPM_DIR):
	mkdir -p $@

$(LSP_ELIXIR): $(LSP_DIR)
	curl -fLO https://github.com/elixir-lsp/elixir-ls/releases/latest/download/elixir-ls.zip
	unzip elixir-ls.zip -d ~/.config/lsp/elixir-ls
	chmod +x ~/.config/lsp/elixir-ls/language_server.sh
	rm elixir-ls.zip

$(TPM): $(GIT)
	mkdir -p $@
	$(GIT) clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

$(DOOM): $(GIT)
	$(GIT) clone https://github.com/hlissner/doom-emacs ~/.emacs.d
	~/.emacs.d/bin/doom install

install: mac dots $(PAQ) $(ASDF) $(TPM) $(LSP_ELIXIR) $(DOOM)
