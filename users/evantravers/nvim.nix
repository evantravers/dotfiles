{ config, lib, pkgs, ... }:
{
  imports = [
    ./nvim-ai.nix
    ./nvim-dap.nix
    ./nvim-prose.nix
  ];

  config = lib.mkIf config.programs.neovim.enable {
    # Use .vimrc for standard vim settings
    xdg.configFile."nvim/.vimrc".source = .config/nvim/.vimrc;

    # Create folders for backups, swaps, and undo
    home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
    '';

    programs.neovim = {
      defaultEditor = true;

      initLua = lib.fileContents .config/nvim/init.lua;

      plugins = with pkgs.vimPlugins; [
        # =======================================================================
        # UI AND THEMES
        # Zenbones for minimal theme
        # =======================================================================
        {
          plugin = zenbones-nvim;
          type = "lua";
          config = ''
            vim.g.zenbones = {
              solid_line_nr    = true,
              solid_vert_split = true,
              darken_noncurrent_window = true,
              lighten_noncurrent_window = true,
            }
            vim.cmd.colorscheme "zenbones"
          '';
        }
        lush-nvim
        # =======================================================================
        # TREESITTER
        # - nvim-treesitter for parser installation only (not setup)
        # - nvim-treesitter-context for context breadcrumbs
        # =======================================================================
        {
          plugin = nvim-treesitter.withPlugins (p: with p; [
            bash
            comment
            css
            diff
            dockerfile
            eex
            elixir
            fish
            gitcommit
            gitignore
            heex
            html
            javascript
            json
            lua
            luadoc
            markdown
            markdown_inline
            nix
            php
            query
            regex
            ruby
            rust
            scss
            svelte
            toml
            tsx
            typescript
            vim
            vimdoc
            vue
            xml
            yaml
          ]);
          type = "lua";
          config = ''
            vim.api.nvim_create_autocmd('FileType', {
              callback = function(ev)
                local bufnr = ev.buf
                local ok = pcall(vim.treesitter.start, bufnr)
                if ok then
                  vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
              end,
            })
          '';
        }
        {
          plugin = nvim-treesitter-context;
          optional = true;
          type = "lua";
          config = ''
            local function toggle_context()
              vim.cmd('TSContext toggle')
              local enabled = not vim.lsp.inlay_hint.is_enabled()
              vim.lsp.inlay_hint.enable(enabled)
              vim.lsp.codelens.enable(enabled)
            end

            local kopts = {noremap = true, silent = true, desc = "Toggle expanded context"}

            vim.keymap.set('n', '<space>c', function()
              vim.cmd.packadd('nvim-treesitter-context')
              require'treesitter-context'.setup{ enable = false }
              vim.keymap.set('n', '<space>c', toggle_context, kopts)
              toggle_context()
            end, kopts)

            vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
              callback = function()
                if vim.lsp.codelens.is_enabled() then
                  vim.lsp.codelens.refresh()
                end
              end,
            })
          '';
        }
        # =======================================================================
        # UTILITIES AND MINI
        # =======================================================================
        {
          plugin = mini-nvim; # Ridiculously complete family of plugins
          type = "lua";
          config = ''
            local opts = function(label)
              return {noremap = true, silent = true, desc = label}
            end

            require('mini.ai').setup({
              mappings = {
                around_next = "",
                inside_next = "",
                around_last = "",
                inside_last = "",
              }
            })
            require('mini.align').setup()
            require('mini.bracketed').setup()
            require('mini.snippets').setup()
            require('mini.completion').setup()
            require('mini.input').setup()
            require('mini.icons').setup()
            require('mini.jump').setup()
            require('mini.jump2d').setup({
              view = { dim = true, n_steps_ahead = 2 },
              mappings = { start_jumping = "" }
            })
            vim.keymap.set('n', 'gw', function() MiniJump2d.start(MiniJump2d.builtin_opts.word_start) end, opts("Jump to Word"))
            require('mini.pairs').setup()
            require('mini.statusline').setup()
            require('mini.surround').setup()
            require('mini.splitjoin').setup()

            vim.api.nvim_create_autocmd('BufReadPost', {
              once = true,
              callback = function()
                vim.cmd.packadd('mini-diff-jj')
                local MiniDiff = require('mini.diff')
                MiniDiff.setup({
                  -- Sources are attempted to attach in order: jj first, git fallback.
                  source = {
                    require('mini.diff.jj'),
                    MiniDiff.gen_source.git(),
                  },
                })
                local hipatterns = require('mini.hipatterns')
                hipatterns.setup({
                  highlighters = {
                    fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
                    hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
                    todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
                    note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },
                    hex_color = hipatterns.gen_highlighter.hex_color(),
                  }
                })
              end,
            })
            vim.keymap.set('n', '<leader>g', function() MiniDiff.toggle_overlay() end, opts("Toggle Diff Overlay"))

            vim.keymap.set('n', '-', function()
              require('mini.files').setup({
                options = { use_as_default_explorer = false }
              })
              local oil_style = function()
                if not MiniFiles.close() then
                  MiniFiles.open(vim.api.nvim_buf_get_name(0))
                  MiniFiles.reveal_cwd()
                end
              end
              vim.keymap.set('n', '-', oil_style, opts("File Explorer"))
              oil_style()
            end, opts("File Explorer"))

            local function load_pick()
              require('mini.pick').setup({
                mappings = { choose_marked = '<C-q>' }
              })
              require('mini.extra').setup()
              MiniPick.registry.files_root = function(local_opts)
                local root_patterns = { ".git" }
                local root_dir = vim.fs.dirname(vim.fs.find(root_patterns, { upward = true })[1])
                return MiniPick.builtin.files(local_opts, { source = { cwd = root_dir } })
              end
            end
            local pick_keys = {
              {lhs = '<space>/', cmd = 'Pick grep_live',             desc = "Live Grep"},
              {lhs = '<space>f', cmd = "Pick files tool='git'",      desc = "Find Files in CWD"},
              {lhs = '<space>F', cmd = "Pick files_root tool='git'", desc = "Find Files"},
              {lhs = '<space>b', cmd = 'Pick buffers',               desc = "Buffers"},
              {lhs = "<space>'", cmd = 'Pick resume',                desc = "Last Picker"},
              {lhs = '<space>g', cmd = 'Pick git_commits',           desc = "Git Commits"},
              {lhs = '<space>z', cmd = 'lua MiniPick.builtin.files(nil, {source={cwd=vim.fn.expand("~/src/wiki")}})', desc = "Wiki"}
            }
            for _, k in ipairs(pick_keys) do
              vim.keymap.set('n', k.lhs, function()
                load_pick()
                vim.keymap.set('n', k.lhs, '<cmd>' .. k.cmd .. '<cr>', opts(k.desc))
                vim.cmd(k.cmd)
              end, opts(k.desc))
            end

            vim.schedule(function()
              local miniclue = require('mini.clue')
              miniclue.setup({
                triggers = {
                  { mode = 'n', keys = '<Leader>' },
                  { mode = 'x', keys = '<Leader>' },
                  { mode = 'n', keys = '<space>' },
                  { mode = 'x', keys = '<space>' },
                  { mode = 'i', keys = '<C-x>' },
                  { mode = 'n', keys = 'g' },
                  { mode = 'x', keys = 'g' },
                  { mode = 'n', keys = "'" },
                  { mode = 'n', keys = '`' },
                  { mode = 'x', keys = "'" },
                  { mode = 'x', keys = '`' },
                  { mode = 'n', keys = '"' },
                  { mode = 'x', keys = '"' },
                  { mode = 'i', keys = '<C-r>' },
                  { mode = 'c', keys = '<C-r>' },
                  { mode = 'n', keys = '<C-w>' },
                  { mode = 'n', keys = 'z' },
                  { mode = 'x', keys = 'z' },
                  { mode = 'n', keys = '[' },
                  { mode = 'n', keys = ']' },
                },
                clues = {
                  miniclue.gen_clues.builtin_completion(),
                  miniclue.gen_clues.g(),
                  miniclue.gen_clues.marks(),
                  miniclue.gen_clues.registers(),
                  miniclue.gen_clues.windows(),
                  miniclue.gen_clues.z(),
                  { mode = 'n', keys = '<Leader>d', desc = '+DAP' },
                  { mode = 'n', keys = '<Leader>f', desc = '+Fix'}
                },
              })
            end)
          '';
        }

        # =======================================================================
        # UTILITIES
        # =======================================================================
        {
          plugin = vim-eunuch; # powerful buffer-level file options
          optional = true;
          type = "lua";
          config = ''
            vim.api.nvim_create_autocmd('CmdUndefined', {
              pattern = {'Delete', 'Rename', 'Move', 'Chmod', 'Mkdir', 'Wall', 'SudoWrite', 'SudoEdit'},
              once = true,
              callback = function()
                vim.cmd.packadd('vim-eunuch')
                return true
              end
            })
          '';
        }
        {
          plugin = vim-ragtag; # print/execute bindings for template files
          optional = true;
          type = "lua";
          config = ''
            vim.api.nvim_create_autocmd('FileType', {
              pattern = {'elixir', 'html', 'eruby', 'xml', 'heex', 'eelixir', 'vue', 'svelte', 'php'},
              once = true,
              callback = function()
                vim.cmd.packadd('vim-ragtag')
              end
            })
          '';
        }
        {
          plugin = pkgs.mini-diff-jj; # jj (jujutsu) source for mini.diff; loaded via packadd in mini.diff setup
          optional = true;
        }
        vim-speeddating # incrementing dates and times
        {
          plugin = vim-fugitive; # :Git actions
          optional = true;
          type = "lua";
          config = ''
            vim.api.nvim_create_autocmd('CmdUndefined', {
              pattern = {'G', 'Git', 'Gread', 'Gwrite', 'Gdiffsplit', 'GBrowse', 'Gedit', 'Ggrep', 'Glog'},
              once = true,
              callback = function()
                vim.cmd.packadd('vim-fugitive')
                vim.cmd.packadd('vim-rhubarb')
                return true
              end
            })
          '';
        }
        {
          plugin = vim-rhubarb; # github plugins for fugitive
          optional = true;
        }
      ];
    };
  };
}
