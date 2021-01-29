-- Load .vimrc
vim.cmd([[runtime .vimrc]])

-- Neovim specific settings
vim.o.icm = 'split'

-- Plugins
vim.cmd 'packadd paq-nvim'
local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt=true}

paq 'gruvbox-community/gruvbox'
vim.g.gruvbox_italic = 1
vim.g.gruvbox_improved_strings = 1
vim.g.gruvbox_improved_warnings = 1
vim.g.gruvbox_contrast_light = 'hard'
vim.g.gruvbox_contrast_dark = 'medium'
vim.cmd [[colorscheme gruvbox]]

paq 'airblade/vim-gitgutter'

paq 'editorconfig/editorconfig-vim'

paq 'itchyny/lightline.vim'
vim.g.lightline = {
  colorscheme = 'gruvbox'
}
vim.o.showmode = false

paq {'junegunn/fzf', hook = vim.fn["fzf#install"]}
paq 'junegunn/fzf.vim'
vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }
vim.g.fzf_action = {
  ['ctrl-s'] = 'split',
  ['ctrl-v'] = 'vsplit'
}
vim.g.fzf_colors = {
  fg      = {'fg', 'Normal'},
  fg      = {'fg', 'Normal'},
  bg      = {'bg', 'Normal'},
  hl      = {'fg', 'Comment'},
  ['fg+'] = {'fg', 'CursorLine', 'CursorColumn', 'Normal'},
  ['bg+'] = {'bg', 'CursorLine', 'CursorColumn'},
  ['hl+'] = {'fg', 'Statement'},
  info    = {'fg', 'PreProc'},
  border  = {'fg', 'Ignore'},
  prompt  = {'fg', 'Conditional'},
  pointer = {'fg', 'Exception'},
  marker  = {'fg', 'Keyword'},
  spinner = {'fg', 'Label'},
  header  = {'fg', 'Comment'}
}
vim.api.nvim_set_keymap('n', '<c-p>', ':FZF<cr>', {noremap = true})
vim.api.nvim_set_keymap('n', '<localleader><space>', ':Buffers<cr>', {noremap = true})

paq 'junegunn/vim-easy-align'
vim.api.nvim_set_keymap('v', '<Enter>', '<Plug>(EasyAlign)', {})
vim.api.nvim_set_keymap('n', '<Leader>a', '<Plug>(EasyAlign)', {})

paq 'kopischke/vim-fetch'

paq 'machakann/vim-sandwich'

function _G.structInput()
  local structName = vim.fn.input('Struct: ')
  local startBun = ''
  if (structName ~= '') then
    startBun = '%' .. structName .. '{'
  else
    error('OperatorSandwichCancel')
  end
  return { startBun, '}' }
end

local sandwich_recipes = vim.api.nvim_eval('sandwich#default_recipes')
local custom_recipes =
  {
    {
      buns     = { '%{', '}' },
      filetype = { 'elixir' },
      input    = { 'm' },
      nesting  = 1
    },
    {
      buns     = 'v:lua.structInput()',
      filetype = { 'elixir' },
      kind     = { 'add', 'replace' },
      action   = { 'add' },
      input    = { 'M' },
      listexpr = 1,
      nesting  = 1
    },
    {
      buns     = { [[%\w\+{]], '}' },
      filetype = { 'elixir' },
      input    = { 'M' },
      nesting  = 1,
      regex    = 1
    },
    {
      buns     = { '<%= ', ' %>' },
      filetype = { 'eruby', 'eelixir' },
      input    = { '=' },
      nesting  = 1
    },
    {
      buns     = { '<% ', ' %>' },
      filetype = { 'eruby', 'eelixir' },
      input    = { '-' },
      nesting  = 1
    },
    {
      buns     = { '<%# ', ' %>' },
      filetype = { 'eruby', 'eelixir' },
      input    = { '#' },
      nesting  = 1
    },
    {
      buns     = { '#{', '}' },
      filetype = { 'ruby' },
      input    = { 's' },
      nesting  = 1
    },
    {
      buns     = { '[', ']()' },
      filetype = { 'markdown' },
      input    = { 'l' },
      nesting  = 1,
      cursor   = 'tail'
    }
  }
vim.list_extend(sandwich_recipes, custom_recipes)
vim.g['sandwich#recipes'] = sandwich_recipes

paq 'mattn/gist-vim'
paq 'mattn/webapi-vim'

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

paq {'nvim-treesitter/nvim-treesitter', hook = ':TSUpdate'}
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  }
}

function _G.toggleProse()
  if (vim.g.proseMode) then
    vim.g.proseMode = false
    vim.o.showmode = true
    vim.o.showcmd = true
    vim.cmd 'PencilOff'
    vim.cmd 'Limelight!'
    vim.cmd 'Goyo!'
  else
    vim.g.proseMode = true
    vim.cmd 'packadd vim-pencil'
    vim.cmd 'packadd goyo.vim'
    vim.cmd 'packadd limelight.vim'
    vim.o.showmode = false
    vim.o.showcmd = false
    vim.cmd 'PencilSoft'
    vim.cmd 'Limelight'
    vim.cmd 'Goyo'
  end
end

paq {'junegunn/limelight.vim', opt = true}

paq {'junegunn/goyo.vim', opt = true}
vim.g.goyo_width = 60

paq {'reedes/vim-pencil', opt = true}
vim.g['pencil#conceallevel'] = 0
vim.g['pencil#wrapModeDefault'] = 'soft'
vim.api.nvim_set_keymap(
  'n',
  '<localleader>m',
  ':lua _G.toggleProse()<cr>',
  {noremap = true, silent = true}
)
