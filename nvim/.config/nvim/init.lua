-- Plugins

vim.cmd 'packadd paq-nvim'
local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt=true}

paq 'gruvbox-community/gruvbox'
vim.g.gruvbox_italic = 1
vim.g.gruvbox_improved_strings = 1
vim.g.gruvbox_improved_warnings = 1
vim.g.gruvbox_guisp_fallback = 'fg'
vim.g.gruvbox_contrast_light = 'hard'
vim.g.gruvbox_contrast_dark = 'medium'
vim.cmd [[colorscheme gruvbox]]

paq 'airblade/vim-gitgutter'

paq 'editorconfig/editorconfig-vim'

paq 'itchyny/lightline.vim'
vim.g.lightline = {
	colorscheme = 'gruvbox'
}
vim.cmd 'set noshowmode'

-- Plug 'itspriddle/vim-marked', { 'for': ['markdown'] }
-- Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': 'yes \| ./install --bin' }
-- Plug 'junegunn/fzf.vim'
-- Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
-- Plug 'junegunn/limelight.vim', { 'on': 'Goyo' }
-- Plug 'junegunn/vim-easy-align'
-- Plug 'junegunn/vim-plug'
-- Plug 'kopischke/vim-fetch'
-- Plug 'machakann/vim-sandwich'
-- Plug 'mattn/gist-vim'
-- Plug 'mattn/webapi-vim'
-- Plug 'mileszs/ack.vim'
-- Plug 'plasticboy/vim-markdown'
-- Plug 'reedes/vim-pencil', { 'on': 'Goyo' }
-- Plug 'rhysd/git-messenger.vim'
-- Plug 'tpope/vim-abolish'
-- Plug 'tpope/vim-commentary'
-- Plug 'tpope/vim-dispatch'
-- Plug 'tpope/vim-eunuch'
-- Plug 'tpope/vim-fugitive'
-- Plug 'tpope/vim-git'
-- Plug 'tpope/vim-projectionist'
-- Plug 'tpope/vim-ragtag'
-- Plug 'tpope/vim-repeat'
-- Plug 'tpope/vim-rhubarb'
-- Plug 'tpope/vim-speeddating'
-- Plug 'tpope/vim-unimpaired'
-- Plug 'tpope/vim-vinegar'
-- Plug 'wellle/targets.vim'

paq {'neovim/nvim-lspconfig'}
paq {'nvim-lua/completion-nvim'}
paq {'nvim-lua/lsp_extensions.nvim'}

-- Options
 
vim.cmd 'set ignorecase'
vim.cmd 'set smartcase'

vim.cmd 'set wildmode=list:longest,full'
vim.cmd 'set wildignore=*.swp,*.o,*.so,*.exe,*.dll'

vim.cmd 'set scrolloff=3'

vim.cmd 'set ts=2'
vim.cmd 'set sw=2'
vim.cmd 'set expandtab'

vim.cmd 'set ruler'
vim.cmd 'set number'
vim.cmd 'set nowrap'
vim.cmd [[set fillchars=vert:\│]]
vim.cmd 'set colorcolumn=80'
vim.cmd 'set relativenumber'

vim.cmd 'set hidden'

-- set backupdir=~/.config/nvim/backups,.
-- set directory=~/.config/nvim/swaps,.
-- if exists('&undodir')
--   set undodir=~/.config/nvim/undo,.
-- endif

vim.cmd 'set icm=split'

-- "=============================================
-- " Remaps
-- "=============================================
-- 
-- let mapleader=','
-- let maplocalleader=','
-- 
-- " Jump key
-- nnoremap ` '
-- nnoremap ' `
-- 
-- " Change pane
-- nnoremap <C-h> <C-w>h
-- nnoremap <C-j> <C-w>j
-- nnoremap <C-k> <C-w>k
-- nnoremap <C-l> <C-w>l
-- 
-- " Turn off search highlight
-- nnoremap <localleader>/ :nohlsearch<CR>
-- 
-- " Trim trailing whitespace
-- nnoremap <localleader>tw m`:%s/\s\+$//e<CR>:nohlsearch<CR>``
-- 
-- "=============================================
-- " Other Settings
-- "=============================================
-- 
-- " Use relative line numbers
-- 
-- " Toggle paste mode
-- set pastetoggle=<leader>z
-- 
-- " Fancy tag lookup
-- set tags=./tags;/,tags;/
-- 
-- " Fancy macros
-- nnoremap Q @q
-- vnoremap Q :norm @q<cr>
-- 
-- " Visible whitespace
-- set listchars=tab:»·,trail:·
-- set list
-- 
-- "=============================================
-- " Package Settings
-- "=============================================
-- 
-- " junegunn/fzf
-- let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"'
-- let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
-- let g:fzf_action = {
-- \ 'ctrl-s': 'split',
-- \ 'ctrl-v': 'vsplit'
-- \ }
-- let g:fzf_colors = {}
-- nnoremap <c-p> :FZF<cr>
-- nnoremap <localleader><space> :Buffers<cr>
-- 
-- let g:goyo_width = 60
-- 
-- function! GoyoBefore()
--   silent !tmux set status off
--   :Limelight
--   :PencilSoft
-- endfunction
-- 
-- function! GoyoAfter()
--   silent !tmux set status on
--   :Limelight!
--   :PencilOff
-- endfunction
-- 
-- let g:goyo_callbacks = [function('GoyoBefore'), function('GoyoAfter')]
-- nnoremap <Leader>m :Goyo<CR>
-- 
-- " junegunn/vim-easy-align
-- vmap <Enter> <Plug>(EasyAlign)
-- nmap <Leader>a <Plug>(EasyAlign)
-- 
-- " mileszs/ack.vim
-- let g:ackprg = 'rg --vimgrep --no-heading'
-- 
-- set background=dark
-- 
-- if $termTheme == 'light'
--   set background=light
-- endif
-- 
-- " itchyny/lightline.vim
-- let g:lightline = {
-- \ 'colorscheme': 'gruvbox',
-- \ }
-- set noshowmode
-- 
-- " w0rp/ale
-- let g:ale_lint_delay = 5000
-- let g:ale_javascript_eslint_use_global = 1
-- let g:ale_linters = {'javascript': ['eslint']}
-- 
-- " itspriddle/vim-marked
-- nnoremap <Leader>M :MarkedOpen<CR>
-- 
-- " Things 3
-- command! -nargs=* Things :silent !open "things:///add?show-quick-entry=true&title=%:t&notes=%<cr>"
-- nnoremap <Leader>T :Things<cr>
-- 
-- " machakann/vim-sandwich
-- let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
-- let g:sandwich#recipes += [
--       \   {
--       \     'buns'    : ['%{', '}'],
--       \     'filetype': ['elixir'],
--       \     'input'   : ['m'],
--       \     'nesting' : 1,
--       \   },
--       \   {
--       \     'buns'    : 'StructInput()',
--       \     'filetype': ['elixir'],
--       \     'kind'    : ['add', 'replace'],
--       \     'action'  : ['add'],
--       \     'input'   : ['M'],
--       \     'listexpr'    : 1,
--       \     'nesting' : 1,
--       \   },
--       \   {
--       \     'buns'    : ['%\w\+{', '}'],
--       \     'filetype': ['elixir'],
--       \     'input'   : ['M'],
--       \     'nesting' : 1,
--       \     'regex'   : 1,
--       \   },
--       \   {
--       \     'buns':     ['<%= ', ' %>'],
--       \     'filetype': ['eruby', 'eelixir'],
--       \     'input':    ['='],
--       \     'nesting':  1
--       \   },
--       \   {
--       \     'buns':     ['<% ', ' %>'],
--       \     'filetype': ['eruby', 'eelixir'],
--       \     'input':    ['-'],
--       \     'nesting':  1
--       \   },
--       \   {
--       \     'buns':     ['<%# ', ' %>'],
--       \     'filetype': ['eruby', 'eelixir'],
--       \     'input':    ['#'],
--       \     'nesting':  1
--       \   },
--       \   {
--       \     'buns':     ['{{ ', ' }}'],
--       \     'filetype': ['liquid', 'mustache'],
--       \     'input':    ['O'],
--       \     'nesting':  1
--       \   },
--       \   {
--       \     'buns':     ['#{', '}'],
--       \     'filetype': ['ruby'],
--       \     'input':    ['s'],
--       \     'nesting':  1
--       \   },
--       \   {
--       \     'buns':     ['[', ']()'],
--       \     'filetype': ['markdown'],
--       \     'input':    ['l'],
--       \     'nesting':  1,
--       \     'cursor':  'tail',
--       \   }
--       \ ]
-- 
-- function! StructInput() abort
--   let s:StructLast = input('Struct: ')
--   if s:StructLast !=# ''
--     let struct = printf('%%%s{', s:StructLast)
--   else
--     throw 'OperatorSandwichCancel'
--   endif
--   return [struct, '}']
-- endfunction
-- 
-- " reedes/vim-pencil
-- let g:pencil#wrapModeDefault = 'soft'
-- 
-- " plasticboy/vim-markdown
-- let g:vim_markdown_folding_disabled = 1
-- let g:vim_markdown_conceal = 0
-- let g:vim_markdown_conceal_code_blocks = 0
-- 
-- " zk
-- nnoremap <leader>zf :Files $SMZPATH<CR>
-- 
-- function! Zk()
--   command! -nargs=* ZkFind execute ":e " . system("smz f " . expand("<cword>"))
-- 
--   nnoremap <leader>gf :ZkFind()<CR>
-- endfunction
-- 
-- augroup zk
--   autocmd!
--   autocmd FileType markdown call Zk()
-- augroup END
