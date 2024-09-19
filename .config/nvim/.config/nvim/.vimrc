" Load plugins
filetype plugin indent on

" Search
set ignorecase
set smartcase

" Tab completion
set wildmode=list:longest,full
set wildignore=*.swp,*.o,*.so,*.exe,*.dll

" Tab settings
set ts=2
set sw=2
set expandtab

" Hud
set termguicolors
syntax on
set colorcolumn=80
set cursorline
set fillchars=vert:\│
set hidden
set list
set listchars=tab:»·,trail:·
set nofoldenable
set nowrap
set number
set relativenumber
set ruler
set scrolloff=3

" Tags
set tags=./tags;/,tags;/

" Backup Directories
set backupdir=~/.config/nvim/backups,.
set directory=~/.config/nvim/swaps,.
if exists('&undodir')
  set undodir=~/.config/nvim/undo,.
endif

let mapleader=','
let maplocalleader=','

" Jump key
nnoremap ` '
nnoremap ' `

" Change pane
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Turn off search highlight
nnoremap <localleader>/ :nohlsearch<CR>

" Trim trailing whitespace
nnoremap <localleader>tw m`:%s/\s\+$//e<CR>:nohlsearch<CR>``

" Fancy macros
nnoremap Q @q
vnoremap Q :norm @q<cr>
