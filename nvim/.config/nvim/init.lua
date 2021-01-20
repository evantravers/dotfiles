-- Load .vimrc
vim.cmd([[runtime .vimrc]])

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
vim.o.showmode = false

paq {'itspriddle/vim-marked', opt = true} -- { 'for': ['markdown'] }
vim.api.nvim_set_keymap('n', '<Leader>M', ':MarkedOpen<CR>', {noremap = true})

paq {'junegunn/fzf', hook = vim.fn["fzf#install"]} -- { 'dir': '~/.fzf', 'do': 'yes \| ./install --bin' }
paq 'junegunn/fzf.vim'
vim.g.fzf_layout = { window = { width = 0.9, height = 0.6 } }
vim.g.fzf_action = {
  ['ctrl-s'] = 'split',
  ['ctrl-v'] = 'vsplit'
}
vim.api.nvim_set_keymap('n', '<c-p>', ':FZF<cr>', {noremap = true})
vim.cmd [[let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --follow --glob "!.git/*"']]
vim.api.nvim_set_keymap('n', '<localleader><space>', ':Buffers<cr>', {noremap = true})

paq {'junegunn/goyo.vim', opt = true} -- { 'on': 'Goyo' }
-- vim.g.goyo_width = 60
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

function _G.structInput()
  local structName = vim.fn.input('Struct: ')
  local startBun = ''
  if (structName ~= '') then
    startBun = '%' .. structName .. '{'
  else
    vim.fn.throw('OperatorSandwichCancel')
  end
  return { startBun, '}' }
end

local sandwich_recipes = vim.fn.deepcopy(vim.api.nvim_eval('sandwich#default_recipes'))
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

-- Neovim specific settings
vim.o.icm = 'split'
