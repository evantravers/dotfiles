{lib, pkgs, ...}:
{
  home.file.".config/nvim/.vimrc".source = ../config/nvim/.config/nvim/.vimrc;

  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraLuaConfig = lib.fileContents ../config/nvim/.config/nvim/init.lua;

    plugins = with pkgs.vimPlugins; [
      {
        plugin = zenbones-nvim;
        type = "lua";
        config = ''
          vim.g.zenbones = {
            solid_line_nr          = true,
            solid_vert_split       = true,
          }
          vim.cmd [[color zenbones]]
        '';
      }
      nvim-web-devicons
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          require'nvim-treesitter.configs'.setup {
            highlight = { enable = true, },
            indent = { enable = true },
          }
        '';
      }
      {
        plugin = vim-easy-align;
        type = "lua";
        config = ''
          vim.keymap.set('v', '<Enter>', '<Plug>(EasyAlign)', {})
          vim.keymap.set('n', '<Leader>a', '<Plug>(EasyAlign)', {})
        '';
      }
      vim-fetch
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
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
        '';
      }
      {
        plugin = vim-sandwich;
        type = "lua";
        config = ''
          function _G.structInput()
            local structName = vim.fn.input('Struct: ')
            local startBun = ""
            local endBun = ""
            if (structName ~= "") then
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
        '';
      }
      lush-nvim
      {
        plugin = nvim-highlight-colors;
        type = "lua";
        config = ''
          require'nvim-highlight-colors'.setup({
            render = 'virtual',
            enable_tailwind = true
          })
        '';
      }
      {
        plugin = oil-nvim;
        type = "lua";
        config = ''
          require("oil").setup({
            view_options = {
              show_hidden = true
            }
          })
          vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
        '';
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup {
            options = {
              theme = "zenbones"
            }
          }
        '';
      }
      vim-abolish
      vim-eunuch
      vim-projectionist
      vim-ragtag
      vim-repeat
      vim-speeddating
      vim-unimpaired
      targets-vim
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = ''
          local npairs = require("nvim-autopairs")
          npairs.setup({
            check_ts = true,
            close_triple_quotes = true
          })
          npairs.add_rules(require('nvim-autopairs.rules.endwise-elixir'))
          npairs.add_rules(require('nvim-autopairs.rules.endwise-lua'))
          npairs.add_rules(require('nvim-autopairs.rules.endwise-ruby'))
          local endwise = require ("nvim-autopairs.ts-rule").endwise
          npairs.add_rules({
            endwise("then$", "end", "lua", nil),
            endwise("do$", "end", "lua", nil),
            endwise(" do$", "end", "elixir", nil),
          })
        '';
      }
      {
        plugin = nvim-ts-autotag;
        type = "lua";
        config = ''
          require("nvim-ts-autotag").setup()
        '';
      }
      vim-elixir
      vim-gist
      webapi-vim
      git-messenger-vim
      vim-fugitive
      vim-git
      vim-rhubarb
      trouble-nvim
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

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
              vim.keymap.set('n', '<space>t', '<cmd>TroubleToggle<CR>', opts)
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
              vim.keymap.set('n', '<M-k>', vim.lsp.buf.signature_help, opts)
              vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
              vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
              vim.keymap.set('n', '<space>wl', function()
                print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
              end, opts)
              vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
              vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
              vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
              vim.keymap.set('n', '<space>f', function()
                vim.lsp.buf.format { async = true }
              end, opts)
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
          require'lspconfig'.tsserver.setup {}
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
          require'lspconfig'.marksman.setup({
            settings = {
              filetypes = {
                "markdown",
                "md"
              }
            }
          })
        '';
      }
      completion-nvim
      popup-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          vim.keymap.set('n', '<localleader>a', "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap = true, silent = true})
          vim.keymap.set('n', '<c-p>', ":lua require('telescope.builtin').find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>", {noremap = true, silent = true})
          vim.keymap.set('n', '<localleader><space>', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true})
          vim.keymap.set('n', '<localleader>ww', ":lua require('telescope.builtin').find_files({prompt_title = 'Search ZK', shorten_path = false, cwd = '~/src/wiki'})<cr>", {noremap = true, silent = true})
        '';
      }
      plenary-nvim
      zen-mode-nvim
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "auto-dark-mode-nvim";
          src = pkgs.fetchFromGitHub {
            owner = "f-person";
            repo = "auto-dark-mode.nvim";
            rev = "76e8d40d1e1544bae430f739d827391cbcb42fcc";
            hash = "sha256-uJ4LxczgWl4aQCFuG4cR+2zwhNo7HB6R7ZPTdgjvyfY=";
          };
          type = "lua";
          config = ''
          -- TODO: This doesn't insert properly
          require('auto-dark-mode').setup({
            update_interval = 1000,
            set_dark_mode = function()
              vim.api.nvim_set_option('background', 'dark')
            end,
            set_light_mode = function()
              vim.api.nvim_set_option('background', 'light')
            end,
          })
          '';
        };
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "nvim-tree-pairs";
          src = pkgs.fetchFromGitHub {
            owner = "yorickpeterse";
            repo = "nvim-tree-pairs";
            rev = "2a6198c66116ea18b8c64a5d0f049c5dab83aa96";
            hash = "sha256-uJ4LxczgWl4aQCFuG4cR+2zwhNo7HB6R7ZPTdgjvyfY=";
          };
          type = "lua";
          config = ''
          require('tree-pairs').setup()
          '';
        };
      }
      flash-nvim
    ];
  };
}
