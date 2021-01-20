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
-- vim.o.noshowmode = true

paq {'itspriddle/vim-marked', opt = true} -- { 'for': ['markdown'] }
vim.api.nvim_set_keymap('n', '<Leader>M', ':MarkedOpen<CR>', {noremap = true})

paq {'junegunn/fzf', hook = vim.fn["fzf#install"]} -- { 'dir': '~/.fzf', 'do': 'yes \| ./install --bin' }
paq 'junegunn/fzf.vim'
vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }
vim.g.fzf_action = {
  ['ctrl-s'] = 'split',
  ['ctrl-v'] = 'vsplit'
}
vim.g.fzf_colors = {}
vim.api.nvim_set_keymap('n', '<c-p>', ':FZF<cr>', {noremap = true})
vim.cmd [[let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"']]
vim.api.nvim_set_keymap('n', '<localleader><space>', ':Buffers<cr>', {noremap = true})

paq {'junegunn/goyo.vim', opt = true} -- { 'on': 'Goyo' }
vim.g.goyo_width = 60
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

paq {'junegunn/limelight.vim', opt = true} -- { 'on': 'Goyo' }

paq 'junegunn/vim-easy-align'
vim.api.nvim_set_keymap('v', '<Enter>', '<Plug>(EasyAlign)', {})
vim.api.nvim_set_keymap('n', '<Leader>a', '<Plug>(EasyAlign)', {})

paq 'kopischke/vim-fetch'

paq 'machakann/vim-sandwich'
-- vim.g['sandwich#recipes'] = vim.g['sandwich#default_recipes']
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

paq 'mattn/gist-vim'
paq 'mattn/webapi-vim'

paq 'plasticboy/vim-markdown'
vim.g.vim_markdown_folding_disabled = 1
vim.g.vim_markdown_conceal = 0
vim.g.vim_markdown_conceal_code_blocks = 0

paq {'reedes/vim-pencil', opt = true} -- { 'on': 'Goyo' }
vim.g['pencil#wrapModeDefault'] = 'soft'

paq 'rhysd/git-messenger.vim'
paq 'tpope/vim-abolish'
paq 'tpope/vim-commentary'
paq 'tpope/vim-dispatch'
paq 'tpope/vim-eunuch'
paq 'tpope/vim-fugitive'
paq 'tpope/vim-git'
paq 'tpope/vim-projectionist'
paq 'tpope/vim-ragtag'
paq 'tpope/vim-repeat'
paq 'tpope/vim-rhubarb'
paq 'tpope/vim-speeddating'
paq 'tpope/vim-unimpaired'
paq 'tpope/vim-vinegar'
paq 'wellle/targets.vim'

paq {'neovim/nvim-lspconfig'}
paq {'nvim-lua/completion-nvim'}
paq {'nvim-lua/lsp_extensions.nvim'}

-- Options

vim.o.ignorecase = true
vim.o.smartcase = true

vim.cmd 'set wildmode=list:longest,full'
vim.o.wildignore = '*.swp,*.o,*.so,*.exe,*.dll'

vim.o.scrolloff = 3

vim.o.ts = 2
vim.o.sw = 2
vim.o.expandtab = true

vim.o.ruler = true
vim.o.number = true
vim.o.wrap = false
vim.cmd [[set fillchars=vert:\│]]
vim.cmd 'set colorcolumn=80'
vim.cmd 'set relativenumber'

vim.cmd 'set hidden'

vim.cmd 'set backupdir=~/.config/nvim/backups,.'
vim.cmd 'set directory=~/.config/nvim/swaps,.'
vim.cmd 'set undodir=~/.config/nvim/undo,.'

vim.cmd 'set icm=split'

vim.cmd "let mapleader=','"
vim.cmd "let maplocalleader=','"

vim.api.nvim_set_keymap('n', '`', "'", {noremap = true})
vim.api.nvim_set_keymap('n', "'", '`', {noremap = true})

vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', {noremap = true})
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', {noremap = true})

vim.api.nvim_set_keymap('n', '<localleader>/', ':nohlsearch<CR>', {noremap = true})

vim.api.nvim_set_keymap('n', '<localleader>tw', [[:%s/\s\+$//e<CR>:nohlsearch<CR>]], {noremap = true})

vim.cmd 'set pastetoggle=<leader>z'

vim.cmd 'set tags=./tags;/,tags;/'

vim.api.nvim_set_keymap('n', 'Q', '@q', {noremap = true})
vim.api.nvim_set_keymap('v', 'Q', ':norm @q<cr>', {noremap = true})

vim.cmd 'set listchars=tab:»·,trail:·'
vim.cmd 'set list'
