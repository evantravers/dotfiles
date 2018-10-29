default:
	make stow

stow:
	stow git
	stow kitty
	stow nvim
	stow tmux
	stow zsh
	stow asdf

install:
	make stow
	if [ ! $(which brew)  ]; then
		echo "[dotfiles] Installing homebrew..."
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi
	brew bundle
	# install plug.vim
	curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	nvim +PlugInstall +qall
	# install tmux tpm
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	# install asdf
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.0
