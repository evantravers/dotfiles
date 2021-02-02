-- Load .vimrc
vim.cmd([[runtime .vimrc]])


-- Neovim specific settings
vim.o.icm = 'split'


-- PLUGINS
-- Using paq.nvim
vim.cmd 'packadd paq-nvim'
local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt=true}


-- THEME
-- gruvbox colors
paq 'gruvbox-community/gruvbox'
vim.g.gruvbox_italic = 1
vim.g.gruvbox_improved_strings = 1
vim.g.gruvbox_improved_warnings = 1
vim.g.gruvbox_contrast_light = 'hard'
vim.g.gruvbox_contrast_dark = 'medium'
vim.cmd [[colorscheme gruvbox]]
-- statusline
paq 'itchyny/lightline.vim'
vim.g.lightline = {
  colorscheme = 'gruvbox'
}
vim.o.showmode = false


-- UI
-- bindings to toggle common settings
paq 'tpope/vim-unimpaired'
-- gitgutter
paq 'airblade/vim-gitgutter'
-- be able to open from stack traces
paq 'kopischke/vim-fetch'
-- rename... could be LSP'd away someday
paq 'tpope/vim-abolish'
-- easy comments
paq 'tpope/vim-commentary'
-- handle missing files and unix-y stuff
paq 'tpope/vim-eunuch'
-- create and rename files by convention
paq 'tpope/vim-projectionist'
-- handle html tags
paq 'tpope/vim-ragtag'
-- repeat actions
paq 'tpope/vim-repeat'
-- work with dates
paq 'tpope/vim-speeddating'
-- use netrw with style
paq 'tpope/vim-vinegar'
-- expand the target objects
paq 'wellle/targets.vim'

-- editorconfig for being polite
paq 'editorconfig/editorconfig-vim'


-- fzf for finding stuff
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


-- easyalign
paq 'junegunn/vim-easy-align'
vim.api.nvim_set_keymap('v', '<Enter>', '<Plug>(EasyAlign)', {})
vim.api.nvim_set_keymap('n', '<Leader>a', '<Plug>(EasyAlign)', {})


-- elixir
paq 'elixir-lang/vim-elixir'


-- vim-sandwich
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


-- git/gist/github
paq 'tpope/vim-fugitive'
paq 'tpope/vim-git'
paq 'mattn/gist-vim'
paq 'mattn/webapi-vim'
paq 'rhysd/git-messenger.vim'
paq 'tpope/vim-rhubarb'


-- LSP LANGUAGE SERVERS
paq {'neovim/nvim-lspconfig'}
require'lspconfig'.elixirls.setup({
  cmd = { os.getenv("XDG_CONFIG_HOME") .. "/lsp/elixir-ls/language_server.sh" };
  on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = { noremap=true, silent=true }
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<space>k', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

    -- Set some keybinds conditional on server capabilities
    if client.resolved_capabilities.document_formatting then
      buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
    elseif client.resolved_capabilities.document_range_formatting then
      buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
    end

    -- Set autocommands conditional on server_capabilities
    if client.resolved_capabilities.document_highlight then
      vim.api.nvim_exec([[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
      augroup lsp_document_highlight
      autocmd!
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
      ]], false)
    end
  end
})
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


-- PROSE MODE
-- I write prose in markdown, all the following is to help with that.
function _G.toggleProse()
  if (vim.g.proseMode == true) then
    vim.cmd 'PencilOff'
    vim.cmd 'Limelight!'
    vim.cmd 'Goyo!'
    vim.cmd [[set wrap!]]
    vim.cmd [[silent !tmux set status on]]
    vim.o.showmode = true
    vim.o.showcmd = true
    vim.g.proseMode = false
  else
    vim.cmd 'packadd vim-pencil'
    vim.cmd 'packadd goyo.vim'
    vim.cmd 'packadd limelight.vim'
    vim.cmd [[silent !tmux set status off]]
    vim.o.showmode = false
    vim.o.showcmd = false
    vim.wo.foldlevel = 4
    vim.cmd 'PencilSoft'
    vim.cmd 'Limelight'
    vim.cmd 'Goyo'
    vim.g.proseMode = true
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
