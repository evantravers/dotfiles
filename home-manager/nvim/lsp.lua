vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, {desc = "Add buffer diagnostics to the location list."})

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('force', opts, {desc = "Declaration"}))
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('force', opts, {desc = "Definition"}))
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('force', opts, {desc = "Implementation"}))
    vim.keymap.set('n', '<M-k>', vim.lsp.buf.signature_help, vim.tbl_extend('force', opts, {desc = "Signature Help"}))
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, vim.tbl_extend('force', opts, {desc = "Add Workspace Folder"}))
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, vim.tbl_extend('force', opts, {desc = "Remove Workspace Folder"}))
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, vim.tbl_extend('force', opts, {desc = "List Workspace Folders"}))
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, vim.tbl_extend('force', opts, {desc = "Type Definition"}))
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, vim.tbl_extend('force', opts, {desc = "Rename Symbol"}))
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, vim.tbl_extend('force', opts, {desc = "Code Action"}))
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('force', opts, {desc = "Buffer References"}))
    vim.keymap.set('n', '<localleader>f', function()
      vim.lsp.buf.format { async = true }
    end, vim.tbl_extend('force', opts, {desc = "Format Buffer"}))
  end,
})

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

require'lspconfig'.elixirls.setup {
  cmd = { "elixir-ls" }
}
require'lspconfig'.solargraph.setup({
  cmd = { "solargraph", "stdio" },
  filetypes = { "ruby" },
  root_dir = root_pattern("Gemfile", ".git"),
  settings = {
    solargraph = {
      diagnostics = true,
      useBundler = true
    }
  }
})
require'lspconfig'.nixd.setup {}
require'lspconfig'.lua_ls.setup {
  cmd = { "lua-language-server" };
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
require'lspconfig'.ltex.setup({
  settings = {
    ltex = {
      language = "en-US",
      enabled = true
    }
  }
})
require'lspconfig'.markdown_oxide.setup({
  settings = {
    filetypes = {
      "markdown",
      "md"
    }
  }
})
