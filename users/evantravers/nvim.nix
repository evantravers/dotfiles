{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./nvim-ai.nix
  ];

  # Use .vimrc for standard vim settings
  xdg.configFile."nvim/.vimrc".source = .config/nvim/.vimrc;

  # Create folders for backups, swaps, and undo
  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    # Use init.lua for standard neovim settings
    extraLuaConfig = lib.fileContents .config/nvim/init.lua;

    plugins = with pkgs.unstable.vimPlugins; [
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
      # PROSE
      # - Optional prose mode for writing: wrap, bindings, zen
      # =======================================================================
      {
        plugin = zen-mode-nvim;
        type = "lua";
        config = ''
          -- I write prose in markdown, all the following is to help with that.
          function _G.toggleProse()
            require("zen-mode").toggle({
              window = {
                backdrop = 1,
                width = 80
              },
              plugins = {
                tmux = { enabled = true }
              },
              on_open = function()
                if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
                  vim.o.scrolloff = 999
                  vim.o.relativenumber = false
                  vim.o.number = false
                  vim.o.wrap = true
                  vim.o.linebreak = true
                  vim.o.colorcolumn = "0"

                  vim.keymap.set('n', 'j', 'gj', {noremap = true, buffer = true})
                  vim.keymap.set('n', 'k', 'gk', {noremap = true, buffer = true})
                end
              end,
              on_close = function()
                vim.o.scrolloff = 3
                vim.o.relativenumber = true
                if (vim.bo.filetype == "markdown" or vim.bo.filetype == "telekasten") then
                  vim.o.wrap = false
                  vim.o.linebreak = false
                  vim.o.colorcolumn = "80"
                end

                vim.keymap.set('n', 'j', 'j', {noremap = true, buffer = true})
                vim.keymap.set('n', 'k', 'k', {noremap = true, buffer = true})
              end
            })
          end

          vim.keymap.set(
            'n',
            '<space>m',
            ':lua _G.toggleProse()<cr>',
            {noremap = true, silent = true, desc = "Toggle Writing Mode"}
          )
        '';
      }
      # =======================================================================
      # TREESITTER
      # - enable treesitter options
      # - TS-enabled context breadcrumbs
      # - helix style scope selection
      # =======================================================================
      {
        plugin = nvim-treesitter.withAllGrammars; # Treesitter
        type = "lua";
        config = ''
        '';
      }
      {
        plugin = nvim-treesitter-context;
        type = "lua";
        config = ''
          require'treesitter-context'.setup{
            enable = false
          }
          vim.keymap.set('n', '<space>c', "<cmd>TSContext toggle<cr>", {noremap = true, silent = true, desc = "Toggle TS Context"})
        '';
      }
      # =======================================================================
      # UTILITIES AND MINI
      # =======================================================================
      {
        plugin = mini-nvim; # Ridiculously complete family of plugins
        type = "lua";
        config = ''
          -- opts decorates keymaps with labels
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

          require('mini.align').setup()      -- aligning

          require('mini.bracketed').setup()  -- unimpaired bindings with TS

          require('mini.snippets').setup()

          require('mini.completion').setup()

          require('mini.diff').setup()
          vim.keymap.set('n', '<leader>g', "<cmd>:lua MiniDiff.toggle_overlay()<cr>", opts("Toggle Diff Overlay"))

          require('mini.extra').setup()      -- extra pickers

          require('mini.files').setup({
            options = {
              use_as_default_explorer = false
            }
          })
          local oil_style = function()
            if not MiniFiles.close() then
              MiniFiles.open(vim.api.nvim_buf_get_name(0))
              MiniFiles.reveal_cwd()
            end
          end
          vim.keymap.set('n', '-', oil_style, opts("File Explorer"));

          local hipatterns = require('mini.hipatterns')
          hipatterns.setup({  -- highlight strings and colors
            highlighters = {
              -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
              fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
              hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
              todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
              note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },

              -- Highlight hex color strings (`#rrggbb`) using that color
              hex_color = hipatterns.gen_highlighter.hex_color(),
            }
          })

          require('mini.icons').setup()      -- minimal icons

          require('mini.jump').setup()       -- fFtT work past a line
          local MiniJump2d = require('mini.jump2d').setup({
            view = {
              dim = true
            },
            mappings = {
              start_jumping = ""
            }
          })
          vim.keymap.set('n', 'gw', "<cmd>:lua MiniJump2d.start(MiniJump2d.builtin_opts.single_character)<cr>", opts("Jump to Word"))

          require('mini.pairs').setup()      -- pair brackets

          require('mini.pick').setup({
            mappings = {
              choose_marked = '<C-q>' -- sends to quickfix anyway
            }
          })       -- pickers
          MiniPick.registry.files_root = function(local_opts)
            local root_patterns = { ".git" }
            local root_dir = vim.fs.dirname(vim.fs.find(root_patterns, { upward = true })[1])
            local opts = { source = { cwd = root_dir } }
            local_opts.cwd = root_dir -- nil?
            return MiniPick.builtin.files(local_opts, opts)
          end
          vim.keymap.set('n', '<space>/', "<cmd>Pick grep_live<cr>", opts("Live Grep"))
          vim.keymap.set('n', '<space>f', "<cmd>Pick files tool='git'<cr>", opts("Find Files in CWD"))
          vim.keymap.set('n', '<space>F', "<cmd>Pick files_root tool='git'<cr>", opts("Find Files"))
          vim.keymap.set('n', '<space>b', "<cmd>Pick buffers<cr>", opts("Buffers"))
          vim.keymap.set('n', "<space>'", "<cmd>Pick resume<cr>", opts("Last Picker"))
          vim.keymap.set('n', "<space>g", "<cmd>Pick git_commits<cr>", opts("Git Commits"))
          vim.keymap.set('n', "<space>z", "<cmd>lua MiniPick.builtin.files(nil, {source={cwd=vim.fn.expand('~/src/wiki')}})<cr>", opts("Wiki"))

          require('mini.statusline').setup() -- minimal statusline

          require('mini.surround').setup()

          require('mini.splitjoin').setup()  -- work with parameters

          local miniclue = require('mini.clue')
          miniclue.setup({                   -- cute prompts about bindings
            triggers = {
              { mode = 'n', keys = '<Leader>' },
              { mode = 'x', keys = '<Leader>' },
              { mode = 'n', keys = '<space>' },
              { mode = 'x', keys = '<space>' },

              -- Built-in completion
              { mode = 'i', keys = '<C-x>' },

              -- `g` key
              { mode = 'n', keys = 'g' },
              { mode = 'x', keys = 'g' },

              -- Marks
              { mode = 'n', keys = "'" },
              { mode = 'n', keys = '`' },
              { mode = 'x', keys = "'" },
              { mode = 'x', keys = '`' },

              -- Registers
              { mode = 'n', keys = '"' },
              { mode = 'x', keys = '"' },
              { mode = 'i', keys = '<C-r>' },
              { mode = 'c', keys = '<C-r>' },

              -- Window commands
              { mode = 'n', keys = '<C-w>' },

              -- `z` key
              { mode = 'n', keys = 'z' },
              { mode = 'x', keys = 'z' },

              -- Bracketed
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
            },
          })
        '';
      }

      # =======================================================================
      # UTILITIES
      # =======================================================================
      vim-eunuch # powerful buffer-level file options
      vim-ragtag # print/execute bindings for template files
      vim-speeddating # incrementing dates and times
      vim-fugitive # :Git actions
      vim-rhubarb # github plugins for fugitive

      {
        plugin = nvim-dap;
        type = "lua";
        config = ''
        '';
      }
    ];
  };
}
