-- Load .vimrc
vim.cmd([[runtime .vimrc]])


-- Neovim specific settings
vim.o.icm = 'split'

-- PLUGINS
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",       -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- UI
  "cormacrelf/dark-notify",  -- switch light/dark
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        char = {
          enabled = false
        }
      }
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          -- default options: exact mode, multi window, all directions, with a backdrop
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
    },
  },
  "junegunn/vim-easy-align",
  "kopischke/vim-fetch",     -- be able to open from stack traces
  "lewis6991/gitsigns.nvim", -- gitsigns
  "machakann/vim-sandwich",
  {
    "mcchrish/zenbones.nvim",
    dependencies             = {
      "rktjmp/lush.nvim"
    }
  },
  "norcalli/nvim-colorizer.lua",
  "nvim-lualine/lualine.nvim",
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  "tpope/vim-abolish",       -- rename... could be LSP"'d away someday
  "tpope/vim-commentary",    -- easy comments
  "tpope/vim-eunuch",        -- handle missing files and unix-y stuff
  "tpope/vim-projectionist", -- create and rename files by convention
  "tpope/vim-ragtag",        -- handle html tags
  "tpope/vim-repeat",        -- repeat actions
  "tpope/vim-speeddating",   -- work with dates
  "tpope/vim-unimpaired",    -- bindings to toggle common settings
  "wellle/targets.vim",      -- expand the target objects
  "windwp/nvim-autopairs",
  "windwp/nvim-ts-autotag",
  -- Syntax
  "elixir-editors/vim-elixir",
  -- git/gist/github
  "mattn/gist-vim",
  "mattn/webapi-vim",
  "rhysd/git-messenger.vim",
  "tpope/vim-fugitive",
  "tpope/vim-git",
  "tpope/vim-rhubarb",
  -- LSP
  "folke/lsp-trouble.nvim",
  {
    "glepnir/lspsaga.nvim",
    event = "BufRead",
    config = function()
      require("lspsaga").setup({
        symbol_in_winbar = {
          separator = " › ",
          color_mode = false,
        },
      })
    end,
    dependencies = { {"nvim-tree/nvim-web-devicons"} }
  },
  "neovim/nvim-lspconfig",
  "nvim-lua/completion-nvim",
  "nvim-lua/popup.nvim",
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { {'nvim-lua/plenary.nvim'} }
  },
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  -- Prose
  {"folke/zen-mode.nvim", lazy = true},
  -- ZK
  {"renerocksai/telekasten.nvim"},
})

-- THEME
vim.g.zenbones = {
  solid_line_nr          = true,
  solid_vert_split       = true,
}
vim.cmd [[color zenbones]]

require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
  },
  indent = {
    enable = true
  }
}

-- statusline
require('lualine').setup {
  options = {
    theme = "zenbones"
  }
}

vim.o.showmode = false
require('dark_notify').run()

-- UI
require("oil").setup({
  view_options = {
    show_hidden = true
  }
})
vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })

require('gitsigns').setup{
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.next_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    map('n', '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.prev_hunk() end)
      return '<Ignore>'
    end, {expr=true})

    -- Actions
    map({'n', 'v'}, '<leader>hs', ':Gitsigns stage_hunk<CR>')
    map({'n', 'v'}, '<leader>hr', ':Gitsigns reset_hunk<CR>')
    map('n', '<leader>hS', gs.stage_buffer)
    map('n', '<leader>hu', gs.undo_stage_hunk)
    map('n', '<leader>hR', gs.reset_buffer)
    map('n', '<leader>hp', gs.preview_hunk)
    map('n', '<leader>hb', function() gs.blame_line{full=true} end)
    map('n', '<leader>tb', gs.toggle_current_line_blame)
    map('n', '<leader>hd', gs.diffthis)
    map('n', '<leader>hD', function() gs.diffthis('~') end)
    map('n', '<leader>td', gs.toggle_deleted)

    -- Text object
    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}

-- highlight colors
require'colorizer'.setup()


-- Use rg
vim.o.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }

vim.keymap.set('n', '<c-p>', ":lua require('telescope.builtin').find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>", {noremap = true, silent = true})
vim.keymap.set('n', '<localleader><space>', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true})

-- ZK
local home = vim.fn.expand("~/src/wiki")

require('telekasten').setup({
  home         = home,
  take_over_my_home = true,
  auto_set_filetype = false,
  dailies      = home .. '/' .. 'journal/daily',
  weeklies     = home .. '/' .. 'journal/weekly',
  templates    = home .. '/' .. 'templates',
  image_subdir = nil,
  uuid_type = "%Y%m%d%H%M",
  follow_creates_nonexisting = true,
  journal_auto_open = false,
  template_new_daily = home .. '/' .. 'templates/daily.md',
  template_new_weekly= home .. '/' .. 'templates/weekly.md',
  image_link_style = "markdown",
  sort = "filename",
  plug_into_calendar = true,
  calendar_opts = {
    weeknm = 4,
    calendar_monday = 1,
    calendar_mark = 'left-fit',
  },
  close_after_yanking = false,
  insert_after_inserting = true,
  tag_notation = "#tag",
  command_palette_theme = "ivy",
  show_tags_theme = "ivy",
  subdirs_in_links = true,
  template_handling = "smart",
  new_note_location = "smart",
  rename_update_links = true,
  media_previewer = "telescope-media-files",
  follow_url_fallback = nil,
})

vim.keymap.set('n', '<localleader>zf', ":Telekasten find_notes<cr>", {noremap = true, silent = true})
vim.keymap.set('n', '<localleader>zd', ":Telekasten find_daily_notes<cr>", {noremap = true, silent = true})
vim.keymap.set('n', '<localleader>zg', ":Telekasten search_notes<cr>", {noremap = true, silent = true})
vim.keymap.set('n', '<localleader>zz', ":lua require('telekasten').follow_link()<CR>", {noremap = true, silent = true})
vim.keymap.set('n', '<localleader>z', ":lua require('telekasten').panel()<CR>", {noremap = true, silent = true})
vim.keymap.set('i', '[[', "<cmd>:lua require('telekasten').insert_link()<CR>", {noremap = true, silent = true})

-- easyalign
vim.keymap.set('v', '<Enter>', '<Plug>(EasyAlign)', {})
vim.keymap.set('n', '<Leader>a', '<Plug>(EasyAlign)', {})


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

-- close tags
require('nvim-ts-autotag').setup()


-- LSP LANGUAGE SERVERS
require('trouble').setup()

vim.fn.sign_define("DiagnosticSignError", {text = "", hl = "DiagnosticSignError", texthl = "DiagnosticSignError", culhl = "DiagnosticSignErrorLine"})
vim.fn.sign_define("DiagnosticSignWarn", {text = "", hl = "DiagnosticSignWarn", texthl = "DiagnosticSignWarn", culhl = "DiagnosticSignWarnLine"})
vim.fn.sign_define("DiagnosticSignInfo", {text = "", hl = "DiagnosticSignInfo", texthl = "DiagnosticSignInfo", culhl = "DiagnosticSignInfoLine"})
vim.fn.sign_define("DiagnosticSignHint", {text = "", hl = "DiagnosticSignHint", texthl = "DiagnosticSignHint", culhl = "DiagnosticSignHintLine"})

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', '<space>t', '<cmd>TroubleToggle<CR>', opts)
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', 'gR', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.server_capabilities.document_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.server_capabilities.document_range_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.server_capabilities.document_highlight then
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
  cmd = { "/opt/homebrew/bin/elixir-ls" };
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

require'lspconfig'.lua_ls.setup {
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

-- floating windows
-- LSP finder - Find the symbol's definition
-- If there is no definition, it will instead be hidden
-- When you use an action in finder like "open vsplit",
-- you can use <C-t> to jump back
vim.keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>")

-- Code action
vim.keymap.set({"n","v"}, "<leader>ca", "<cmd>Lspsaga code_action<CR>")

-- Rename all occurrences of the hovered word for the entire file
vim.keymap.set("n", "gr", "<cmd>Lspsaga rename<CR>")

-- Rename all occurrences of the hovered word for the selected files
vim.keymap.set("n", "gr", "<cmd>Lspsaga rename ++project<CR>")

-- Peek definition
-- You can edit the file containing the definition in the floating window
-- It also supports open/vsplit/etc operations, do refer to "definition_action_keys"
-- It also supports tagstack
-- Use <C-t> to jump back
vim.keymap.set("n", "gd", "<cmd>Lspsaga peek_definition<CR>")

-- Go to definition
vim.keymap.set("n","gd", "<cmd>Lspsaga goto_definition<CR>")

-- Show line diagnostics
-- You can pass argument ++unfocus to
-- unfocus the show_line_diagnostics floating window
vim.keymap.set("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>")

-- Show cursor diagnostics
-- Like show_line_diagnostics, it supports passing the ++unfocus argument
vim.keymap.set("n", "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>")

-- Show buffer diagnostics
vim.keymap.set("n", "<leader>sb", "<cmd>Lspsaga show_buf_diagnostics<CR>")

-- Diagnostic jump
-- You can use <C-o> to jump back to your previous location
vim.keymap.set("n", "[E", "<cmd>Lspsaga diagnostic_jump_prev<CR>")
vim.keymap.set("n", "]E", "<cmd>Lspsaga diagnostic_jump_next<CR>")

-- Toggle outline
vim.keymap.set("n","<leader>o", "<cmd>Lspsaga outline<CR>")
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>")
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc ++keep<CR>")

-- Call hierarchy
vim.keymap.set("n", "<Leader>ci", "<cmd>Lspsaga incoming_calls<CR>")
vim.keymap.set("n", "<Leader>co", "<cmd>Lspsaga outgoing_calls<CR>")

-- Floating terminal
vim.keymap.set({"n", "t"}, "<A-d>", "<cmd>Lspsaga term_toggle<CR>")


-- PROSE MODE
-- I write prose in markdown, all the following is to help with that.
function _G.toggleProse()
  require("zen-mode").toggle({
    window = {
      backdrop = 1,
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
      if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
        vim.cmd 'set so=999'
        vim.cmd 'set nornu nonu'
        vim.cmd 'set wrap'
        vim.cmd 'set linebreak'
        vim.cmd 'set colorcolumn=0'

        vim.keymap.set('n', 'j', 'gj', {noremap = true})
        vim.keymap.set('n', 'k', 'gk', {noremap = true})
      end
    end,
    on_close = function()
      vim.cmd 'set so=3'
      vim.cmd 'set rnu'
      if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
        vim.cmd 'set nowrap'
        vim.cmd 'set nolinebreak'
        vim.cmd 'set colorcolumn=80'
      end

      vim.keymap.set('n', 'j', 'j', {noremap = true})
      vim.keymap.set('n', 'k', 'k', {noremap = true})
    end
  })
end

vim.keymap.set(
  'n',
  '<localleader>m',
  ':lua _G.toggleProse()<cr>',
  {noremap = true, silent = true}
)

-- Covenience macros
-- fix ellipsis: "..." -> "…"
vim.keymap.set('n',
  '<leader>fe',
  "mc:%s,\\.\\.\\.,…,g<CR>:nohlsearch<CR>`c",
  {noremap = true, silent = true})
-- fix spelling: just an easier finger roll on 40% keyboard
vim.keymap.set('n',
  '<leader>fs',
  '1z=',
  {noremap = true, silent = true})

vim.keymap.set('n',
  '<leader>a',
  "<cmd>lua require('telescope.builtin').live_grep()<cr>",
  {noremap = true, silent = true})
