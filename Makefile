default:
	stow git
	stow kitty
	stow nvim
	stow tmux
	stow zsh
	stow asdf

prep:
	# install plug.vim
	curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# install tmux tpm
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	# install asdf
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.0

install:
	make default
	make prep
