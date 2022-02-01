-- Load .vimrc
vim.cmd([[runtime .vimrc]])


-- Neovim specific settings
vim.o.icm = 'split'


-- PLUGINS
require "paq" {
  "savq/paq-nvim";

-- UI
  "editorconfig/editorconfig-vim"; -- editorconfig for being polite;
  "junegunn/vim-easy-align";
  "kopischke/vim-fetch";           -- be able to open from stack traces;
  "kyazdani42/nvim-web-devicons";  -- icons!;
  "lewis6991/gitsigns.nvim";       -- gitsigns;
  "machakann/vim-sandwich";
  "mcchrish/zenbones.nvim";
  "nvim-lualine/lualine.nvim";
  "rktjmp/lush.nvim";
  "tpope/vim-abolish";             -- rename... could be LSP";d away someday;
  "tpope/vim-commentary";          -- easy comments;
  "tpope/vim-eunuch";              -- handle missing files and unix-y stuff;
  "tpope/vim-projectionist";       -- create and rename files by convention;
  "tpope/vim-ragtag";              -- handle html tags;
  "tpope/vim-repeat";              -- repeat actions;
  "tpope/vim-speeddating";         -- work with dates;
  "tpope/vim-unimpaired";          -- bindings to toggle common settings;
  "tpope/vim-vinegar";             -- use netrw with style;
  "wellle/targets.vim";            -- expand the target objects;
  "windwp/nvim-autopairs";
-- Syntax
  "elixir-editors/vim-elixir";
-- git/gist/github
  "mattn/gist-vim";
  "mattn/webapi-vim";
  "rhysd/git-messenger.vim";
  "tpope/vim-fugitive";
  "tpope/vim-git";
  "tpope/vim-rhubarb";
-- LSP
  "SmiteshP/nvim-gps";
  "folke/lsp-trouble.nvim";
  "tami5/lspsaga.nvim";
  "neovim/nvim-lspconfig";
  "nvim-lua/completion-nvim";
  "nvim-lua/lsp_extensions.nvim";
  "nvim-lua/plenary.nvim";
  "nvim-lua/popup.nvim";
  "nvim-telescope/telescope.nvim";
  {"nvim-treesitter/nvim-treesitter", hook = ":TSUpdate"};
-- Prose
  {"reedes/vim-pencil", opt = true};
  {"folke/zen-mode.nvim", opt = true};
  {"folke/twilight.nvim", opt = true};

-- Orgmode
  {"kristijanhusak/orgmode.nvim"};

-- ZK
  {"mickael-menu/zk-nvim", branch = "feature/initial"}
}

require('orgmode').setup({
  org_agenda_files = {'~/Library/Mobile Documents/com~apple~CloudDocs/org/*'},
  org_default_notes_file = '~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org',
})

-- THEME
vim.g.zenbones_solid_line_nr = true
vim.g.zenbones_solid_vert_split = true
vim.cmd [[color zenbones]]

-- statusline
local gps = require("nvim-gps")
require('lualine').setup {
  options = {
    theme = "zenbones"
  },
  sections = {
    lualine_c = {
      { gps.get_location, condition=gps.is_available },
    }
  }
}

vim.o.showmode = false
if os.getenv('theme') == 'light' then
  vim.o.background = 'light'
end


-- UI
require('gitsigns').setup()


-- ZK
-- telescope for finding stuff
function _G.searchWiki()
  require('telescope.builtin').find_files {
    prompt_title = "Search ZK",
    shorten_path = false,
    cwd = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/wiki",
  }
end
-- Provides some convience functions for browsing my Obsidian style SMZ
local zk = require 'zk-nvim'
zk.setup()


vim.api.nvim_set_keymap('n', '<c-p>', ":lua require('telescope.builtin').find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<localleader><space>', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<localleader>ww', ":lua _G.searchWiki()<cr>", {noremap = true, silent = true})


-- easyalign
vim.api.nvim_set_keymap('v', '<Enter>', '<Plug>(EasyAlign)', {})
vim.api.nvim_set_keymap('n', '<Leader>a', '<Plug>(EasyAlign)', {})


-- vim-sandwich
function _G.structInput()
  local structName = vim.fn.input('Struct: ')
  local startBun = ''
  local endBun = ''
  if (structName ~= '') then
    startBun = '%' .. structName .. '{'
    endBun = '}'
  end
  return { startBun, endBun }
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


-- autopairs
local npairs = require("nvim-autopairs")
npairs.setup({
  check_ts = true,
  close_triple_quotes = true
})
npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
local endwise = require("nvim-autopairs.ts-rule").endwise
npairs.add_rules({
  endwise("then$", "end", "lua", nil),
  endwise("do$", "end", "lua", nil),
  endwise(" do$", "end", "elixir", nil),
})


-- LSP LANGUAGE SERVERS
require('trouble').setup()

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', '<space>t', '<cmd>LspTroubleToggle<CR>', opts)
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
  cmd = { "/usr/local/bin/elixir-ls" };
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

require'lspconfig'.tsserver.setup{on_attach = on_attach}

require'lspconfig'.sumneko_lua.setup {
  cmd = { "lua-language-server" };
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
        -- Make the server aware of Neovim/Hammerspoon runtime files
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
          [vim.fn.expand('/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/')] = true
        },
      },
    },
  },
}

require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = {'org'},
  },
  indent = {
    enable = true
  }
}

-- floating windows
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
  vim.cmd 'packadd twilight.nvim'
  vim.cmd 'packadd zen-mode.nvim'
  require("twilight").setup {
    context = 1,
  }
  require("zen-mode").toggle({
    window = {
      width = 80
    },
    plugins = {
      gitsigns = { enabled = true },
      tmux = { enabled = true },
      kitty = {
        enabled = true,
      },
    },
    on_open = function()
      if (vim.bo.filetype == "markdown") then
        vim.cmd 'set so=999'
        vim.cmd 'set nornu nonu'
        vim.cmd 'packadd vim-pencil'
        vim.cmd 'PencilSoft'
      end
    end,
    on_close = function()
      vim.cmd 'set so=3'
      vim.cmd 'set rnu'
      if (vim.bo.filetype == "markdown") then
        vim.cmd 'PencilOff'
      end
    end
  })
end

vim.g['pencil#conceallevel'] = 0
vim.g['pencil#wrapModeDefault'] = 'soft'

vim.api.nvim_set_keymap(
  'n',
  '<localleader>m',
  ':lua _G.toggleProse()<cr>',
  {noremap = true, silent = true}
)

-- Covenience macros
-- "..." -> "…"
vim.api.nvim_set_keymap('n',
  '<leader>fe',
  ":%s,\\.\\.\\.,…,g<CR>:nohlsearch<CR>",
  {noremap = true, silent = true})
