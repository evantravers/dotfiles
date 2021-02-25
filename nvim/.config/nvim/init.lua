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
paq 'bluz71/vim-nightfly-guicolors'
vim.cmd [[colorscheme nightfly]]

-- statusline
paq 'hoob3rt/lualine.nvim'
local lualine = require('lualine')
lualine.status()
lualine.options.theme = 'nightfly'

vim.o.showmode = false
if os.getenv('termTheme') == 'light' then
  vim.o.background = 'light'
end


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


-- telescope for finding stuff
paq 'nvim-lua/popup.nvim'
paq 'nvim-lua/plenary.nvim'
paq 'nvim-telescope/telescope.nvim'

function _G.searchWiki()
  require('telescope.builtin').find_files {
    prompt_title = "Search ZK",
    shorten_path = false,
    cwd = "~/src/github.com/evantravers/undo-zk/wiki/",
  }
end

vim.api.nvim_set_keymap('n', '<c-p>', ":lua require('telescope.builtin').git_files()<cr>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<localleader><space>', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<localleader>ww', ":lua _G.searchWiki()<cr>", {noremap = true, silent = true})


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
    },
    {
      buns     = { '<mark>', '</mark>' },
      filetype = { 'markdown' },
      input    = { 'm' },
      nesting  = 1,
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
paq 'neovim/nvim-lspconfig'

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
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

local lspconfig = require('lspconfig')

local function root_pattern(...)
  local patterns = vim.tbl_flatten {...}

  return function(startpath)
    for _, pattern in ipairs(patterns) do
      return lspconfig.util.search_ancestors(
        startpath,
        function(path)
          if lspconfig.util.path.exists(vim.fn.glob(lspconfig.util.path.join(path, pattern))) then
            return path
          end
        end
      )
    end
  end
end

require'lspconfig'.elixirls.setup({
  cmd = { os.getenv("XDG_CONFIG_HOME") .. "/lsp/elixir-ls/language_server.sh" };
  on_attach = on_attach
})
require'lspconfig'.solargraph.setup({
  cmd = { "solargraph", "stdio" },
  filetypes = { "ruby" },
  root_dir = root_pattern("Gemfile", ".git"),
  on_attach = on_attach,
  settings = {
    solargraph = {
      diagnostics = true,
      useBundler = true
    }
  }
})

local sumneko_root_path = os.getenv("XDG_CONFIG_HOME") .. "/lsp/lua-language-server"
local sumneko_binary = sumneko_root_path.."/bin/macOS/lua-language-server"

require'lspconfig'.sumneko_lua.setup {
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"};
  on_attach = on_attach,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Setup your lua path
        path = vim.split(package.path, ';'),
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim', 'hs'},
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
        },
      },
    },
  },
}

paq 'nvim-lua/completion-nvim'
paq 'nvim-lua/lsp_extensions.nvim'

paq {'nvim-treesitter/nvim-treesitter', hook = ':TSUpdate'}
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  }
}

-- floating windows
paq 'glepnir/lspsaga.nvim'
local saga = require('lspsaga')
saga.init_lsp_saga()
-- code finder
vim.api.nvim_set_keymap('n',
  'gh',
  "<cmd>lua require'lspsaga.provider'.lsp_finder()<CR>",
  {noremap = true, silent = true})
-- docs
vim.api.nvim_set_keymap('n',
  'K',
  "<cmd>lua require('lspsaga.hover').render_hover_doc()<CR>",
  {noremap = true, silent = true})
vim.api.nvim_set_keymap('n',
  '<C-f>',
  "<cmd>lua require('lspsaga.hover').smart_scroll_hover(1)<CR>",
  {noremap = true, silent = true})
vim.api.nvim_set_keymap('n',
  '<C-b>',
  "<cmd>lua require('lspsaga.hover').smart_scroll_hover(-1)<CR>",
  {noremap = true, silent = true})
-- code actions
vim.api.nvim_set_keymap('n',
  '<space>ca',
  "<cmd>lua require('lspsaga.codeaction').code_action()<CR>",
  {noremap = true, silent = true})
vim.api.nvim_set_keymap('v',
  '<space>ca',
  "<cmd>'<,'>lua require('lspsaga.codeaction').range_code_action()<CR>",
  {noremap = true, silent = true})
-- signature help
vim.api.nvim_set_keymap('n',
  '<space>k',
  "<cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>",
  {noremap = true, silent = true})
-- rename
vim.api.nvim_set_keymap('n',
  '<space>rn',
  "<cmd>lua require('lspsaga.rename').rename()<CR>",
  {noremap = true, silent = true})
-- preview definition
vim.api.nvim_set_keymap('n',
  '<space>gd',
  "<cmd>lua require'lspsaga.provider'.preview_definition()<CR>",
  {noremap = true, silent = true})
-- diagnostics
vim.api.nvim_set_keymap('n',
  '<space>d',
  "<cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>",
  {noremap = true, silent = true})
vim.api.nvim_set_keymap('n',
  '[d',
  "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>",
  {noremap = true, silent = true})
vim.api.nvim_set_keymap('n',
  ']d',
  "<cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>",
  {noremap = true, silent = true})


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

paq {'vimwiki/vimwiki', branch = 'dev'}
vim.g.vimwiki_global_ext = 0
vim.g.vimwiki_list = {
  {
    path = '~/src/github.com/evantravers/undo-zk/wiki/',
    syntax = 'markdown',
    ext = '.md',
    diary_rel_path = 'journal'
  }
}
