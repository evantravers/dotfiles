" Load plug
call plug#begin('~/.config/nvim/bundle')

Plug 'ElmCast/elm-vim', { 'for': 'elm' }
Plug 'SirVer/ultisnips'
Plug 'airblade/vim-gitgutter'
Plug 'cohama/lexima.vim'
Plug 'editorconfig/editorconfig-vim'
Plug 'elixir-lang/vim-elixir', { 'for': 'elixir' }
Plug 'hail2u/vim-css3-syntax', { 'for': 'css' }
Plug 'honza/vim-snippets'
Plug 'itchyny/lightline.vim'
Plug 'itspriddle/vim-marked', { 'for': 'markdown,vimwiki' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --all' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
Plug 'junegunn/limelight.vim', { 'on': 'Limelight' }
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/vim-plug'
Plug 'kopischke/vim-fetch'
Plug 'machakann/vim-sandwich'
Plug 'mattn/emmet-vim', { 'for': 'html,erb,eruby,markdown' }
Plug 'mattn/gist-vim'
Plug 'mattn/webapi-vim'
Plug 'mileszs/ack.vim'
Plug 'morhetz/gruvbox'
Plug 'mustache/vim-mustache-handlebars', { 'for': 'javascript,handlebars' }
Plug 'othree/csscomplete.vim', { 'for': 'css' }
Plug 'pangloss/vim-javascript', { 'for': 'javascript' }
Plug 'slashmili/alchemist.vim', { 'for': 'elixir' }
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-rails', {'for': 'ruby,erb,yaml,ru,haml'}
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-speeddating'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'vim-ruby/vim-ruby', { 'for': 'ruby' }
Plug 'vimwiki/vimwiki'
Plug 'w0rp/ale'
Plug 'wellle/targets.vim'

call plug#end()

" Load plugins
filetype plugin indent on

"=============================================
" Options
"=============================================

" Color
set termguicolors
syntax on

" Search
set ignorecase
set smartcase

" Tab completion
set wildmode=list:longest,full
set wildignore=*.swp,*.o,*.so,*.exe,*.dll

" Scroll
set scrolloff=3

" Tab settings
set ts=2
set sw=2
set expandtab

" Hud
set ruler
set number
set nowrap
set fillchars=vert:\│
set colorcolumn=80

" Buffers
set hidden

" Backup Directories
set backupdir=~/.config/nvim/backups,.
set directory=~/.config/nvim/swaps,.
if exists('&undodir')
  set undodir=~/.config/nvim/undo,.
endif

" Neovim specific
set icm=nosplit

"=============================================
" Remaps
"=============================================

let mapleader=','
let maplocalleader=','

" No arrow keys
map <Left>  :echo "ಠ_ಠ"<cr>
map <Right> :echo "ಠ_ಠ"<cr>
map <Up>    :echo "ಠ_ಠ"<cr>
map <Down>  :echo "ಠ_ಠ"<cr>

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

"=============================================
" Other Settings
"=============================================

" Use relative line numbers
set relativenumber

" Toggle paste mode
set pastetoggle=<leader>z

" Fancy tag lookup
set tags=./tags;/,tags;/

" Fancy macros
nnoremap Q @q
vnoremap Q :norm @q<cr>

" Visible whitespace
set listchars=tab:»·,trail:·
set list

" Soft-wrap for prose
command! -nargs=* Wrap set wrap linebreak nolist spell
let &showbreak='↪ '

"=============================================
" Package Settings
"=============================================

" junegunn/fzf
let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
let g:fzf_action = {
\ 'ctrl-s': 'split',
\ 'ctrl-v': 'vsplit'
\ }
let g:fzf_colors = {}
nnoremap <c-p> :FZF<cr>
nnoremap <localleader><space> :Buffers<cr>

" junegunn/limelight.vim
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240

function! GoyoBefore()
  silent !tmux set status off
  set tw=78
  Limelight
endfunction

function! GoyoAfter()
  silent !tmux set status on
  set tw=0
  Limelight!
endfunction

let g:goyo_callbacks = [function('GoyoBefore'), function('GoyoAfter')]
nnoremap <Leader>m :Goyo<CR>

" junegunn/vim-easy-align
vmap <Enter> <Plug>(EasyAlign)
nmap <Leader>a <Plug>(EasyAlign)

" mileszs/ack.vim
let g:ackprg = 'rg --vimgrep --no-heading'

" morhetz/gruvbox
let g:gruvbox_italic=1
let g:gruvbox_improved_strings=1
let g:gruvbox_improved_warnings=1
let g:gruvbox_guisp_fallback='fg'
let g:gruvbox_contrast_light='hard'
let g:gruvbox_contrast_dark='medium'

set background=light

if system('darkMode') =~ "Dark"
  set background=dark
endif

colorscheme gruvbox

" tpope/vim-markdown
let g:markdown_fenced_languages = ['css', 'erb=eruby', 'javascript', 'js=javascript', 'json=javascript', 'ruby', 'sass', 'xml', 'html']

" itchyny/lightline.vim
let g:lightline = {
\ 'colorscheme': 'gruvbox',
\ }
set noshowmode

" vimwiki/vimwiki
let g:vimwiki_list = [{'path': '~/wiki/',
                     \ 'auto_toc': 1,
                     \ 'auto_tags': 1,
                     \ 'auto_generate_links': 1,
                     \ 'auto_generate_tags': 1,
                     \ 'syntax': 'markdown',
                     \ 'list_margin': 0,
                     \ 'ext': '.md'}]
let g:vimwiki_global_ext = 0

command! -bang -nargs=* VimwikiSearch
  \ call fzf#vim#grep(
  \  'rg --column --line-number --no-heading --color "always" '.shellescape(<q-args>).' ' . $HOME . '/wiki/', 1,
  \  <bang>0 ? fzf#vim#with_preview('up:60%')
  \          : fzf#vim#with_preview('right:50%:hidden', '?'),
  \  <bang>0)

nnoremap <localleader>w<Space> :VimwikiSearch<cr>

map <M-Space> <Plug>VimwikiToggleListItem
nmap <A-n> <Plug>VimwikiNextLink
nmap <A-p> <Plug>VimwikiPrevLink

command! -nargs=1 VimwikiNewNote write ~/dropbox/wiki/notes/<args>
nnoremap <localleader>w<CR> :VimwikiNewNote

" w0rp/ale
let g:ale_lint_delay = 5000
let g:ale_javascript_eslint_use_global = 1
let g:ale_linters = {'javascript': ['eslint']}

" itspriddle/vim-marked
nnoremap <Leader>M :MarkedOpen<CR>

" Things 3
command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"
nnoremap <Leader>T :Things<cr>

" vim-sandwich
let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
let g:sandwich#recipes += [
      \   {
      \     'buns'    : ['%{', '}'],
      \     'filetype': ['elixir'],
      \     'input'   : ['m'],
      \     'nesting' : 1,
      \   },
      \   {
      \     'buns'    : 'StructInput()',
      \     'filetype': ['elixir'],
      \     'kind'    : ['add', 'replace'],
      \     'action'  : ['add'],
      \     'input'   : ['M'],
      \     'listexpr'    : 1,
      \     'nesting' : 1,
      \   },
      \   {
      \     'buns'    : ['%\w\+{', '}'],
      \     'filetype': ['elixir'],
      \     'input'   : ['M'],
      \     'nesting' : 1,
      \     'regex'   : 1,
      \   },
      \ ]

function! StructInput() abort
  let s:StructLast = input('Struct: ')
  if s:StructLast !=# ''
    let struct = printf('%%%s{', s:StructLast)
  else
    throw 'OperatorSandwichCancel'
  endif
  return [struct, '}']
endfunction
