-- Load .vimrc
vim.cmd([[runtime .vimrc]])

-- Neovim specific settings
vim.o.icm = 'split'
vim.o.cia = 'kind,abbr,menu'
vim.o.foldtext = 'v:lua.vim.treesitter.foldtext()'
vim.o.winborder = 'rounded'

vim.opt.foldmethod = "expr"
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

vim.o.showmode = false

vim.fn.sign_define("DiagnosticSignError", {text = "", hl = "DiagnosticSignError", texthl = "DiagnosticSignError", culhl = "DiagnosticSignErrorLine"})
vim.fn.sign_define("DiagnosticSignWarn", {text = "", hl = "DiagnosticSignWarn", texthl = "DiagnosticSignWarn", culhl = "DiagnosticSignWarnLine"})
vim.fn.sign_define("DiagnosticSignInfo", {text = "", hl = "DiagnosticSignInfo", texthl = "DiagnosticSignInfo", culhl = "DiagnosticSignInfoLine"})
vim.fn.sign_define("DiagnosticSignHint", {text = "", hl = "DiagnosticSignHint", texthl = "DiagnosticSignHint", culhl = "DiagnosticSignHintLine"})

-- Built-in undotree (v0.12+)
vim.cmd.packadd('nvim.undotree')
vim.keymap.set('n', '<leader>u', ':Undotree<CR>', { desc = 'Toggle undotree' })

-- Treesitter indent (built-in in 0.10+)
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    local ok = pcall(vim.treesitter.start)
    if ok then
      vim.bo.indentexpr = 'v:lua.vim.treesitter.indentexpr()'
    end
  end,
})

-- Make <Tab> work for snippets
vim.keymap.set({ 'i', 's' }, '<Tab>', function()
  if vim.snippet.active({ direction = 1 }) then
    return '<cmd>lua vim.snippet.jump(1)<cr>'
  else
    return '<Tab>'
  end
end, { expr = true })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    if client:supports_method('textDocument/documentColor') then
      vim.lsp.document_color.enable(true, {bufnr = ev.buf}, { style = "virtual" })
    end
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set({'n', 'v'}, 'grf', function()
        vim.lsp.buf.format({ bufnr = ev.buf })
      end, { buffer = ev.buf, desc = 'Format with LSP' })
    end
  end,
})

-- Diagnostic Virtual lines for only current line
vim.diagnostic.config({ virtual_lines = { current_line = true, }, })

-- LSP Configurations
vim.lsp.config.elixir = {
  cmd = { "expert", "--stdio" },
  filetypes = { 'elixir', 'heex' },
  root_markers = { 'mix.exs', '.git' },
  settings = {
    elixir = {
      formatting = {
        command = { "mix", "format" }
      }
    }
  }
}

vim.lsp.config.nix = {
  cmd = { "nil" },
  filetypes = { "nix" },
  settings = {
    nil_lsp = {
      nixpkgs = {
        expr = "import <nixpkgs> { }",
      },
      root_markers = { "flake.nix", ".git" },
      settings = {
        formatting = {
          command = { "nixfmt" },
        },
        nix = {
          flake = {
            autoArchive = true,
            autoEvalInputs = true,
            nixpkgsInputName = "nixpkgs",
          },
        },
      },
    },
  }
}

vim.lsp.config.lua = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = vim.split(package.path, ';'),
      },
      diagnostics = { globals = {'vim', 'hs'}, },
      workspace = {
        library = {
          [vim.fn.expand('$VIMRUNTIME/lua')] = true,
          [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
          [vim.fn.expand('/Applications/Hammerspoon.app/Contents/Resources/extensions/hs/')] = true
        },
      },
    },
  }
}

vim.lsp.config.ruby = {
  cmd = { "ruby-lsp" },
  filetypes = { "ruby", "eruby" },
  root_markers = { ".git" },
}

vim.lsp.config.markdown = {
  cmd = { "markdown-oxide" },
  filetypes = { "markdown" }
}

vim.lsp.config.javascript = {
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "typescript",
    "vue",
    "javascriptreact",
    "typescriptreact"
  }
}

vim.lsp.enable({
  'elixir',
  'ruby',
  'nix',
  'lua',
  'markdown',
  'javascript'
})

vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(ev)
    local val = ev.data.params.value
    local token = ev.data.params.token
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local source = client and client.name or 'lsp'

    if val.kind == 'begin' or val.kind == 'report' then
      vim.api.nvim_echo(
        {{ val.title or val.message or 'Working…', 'Normal' }},
        false,
        {
          kind = 'progress',
          title = val.title or source,
          source = source,
          percent = val.percentage or 0,
          status = 'running',
        }
      )
    elseif val.kind == 'end' then
      vim.api.nvim_echo(
        {{ val.message or 'Done', 'Normal' }},
        false,
        {
          kind = 'progress',
          title = val.title or source,
          source = source,
          percent = 100,
          status = 'success',
        }
      )
    end
  end,
})

-- Covenience macros
-- fix ellipsis: "..." -> "…"
vim.keymap.set('n',
  '<leader>fe',
  "mc:%s,\\.\\.\\.,…,g<CR>:nohlsearch<CR>`c",
  {noremap = true, silent = true, desc = "... -> …"})
-- fix spelling: just an easier finger roll on 40% keyboard
vim.keymap.set('n',
  '<leader>fs',
  '1z=',
  {noremap = true, silent = true, desc = "Fix spelling under cursor"})
