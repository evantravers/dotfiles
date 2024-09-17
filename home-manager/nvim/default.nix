{lib, pkgs, ...}:
{
  home.file.".config/nvim/.vimrc".source = ../../.config/nvim/.config/nvim/.vimrc;

  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  programs.neovim = {
    enable = true;

    extraLuaConfig = lib.fileContents ../../.config/nvim/.config/nvim/init.lua;

    plugins = with pkgs.vimPlugins; [
      # UI and Themes
      # =======================================================================
      {
        plugin = zenbones-nvim; # Minimalist theme I love.
        type = "lua";
        config = ''
          vim.g.zenbones = {
            solid_line_nr          = true,
            solid_vert_split       = true,
          }
          vim.cmd [[color zenbones]]
        '';
      }
      lush-nvim # Required by zenbones for all the colors
      {
        plugin = nvim-highlight-colors; # highlight CSS colors
        type = "lua";
        config = ''
          require'nvim-highlight-colors'.setup({
            render = 'virtual',
            enable_tailwind = true
          })
        '';
      }
      {
        plugin = oil-nvim; # Sits on top of netrw to make file actions easy.
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
        plugin = gitsigns-nvim; # Display git modifications in signcolumn
        type = "lua";
        config = ''
          require('gitsigns').setup()
        '';
      }
      {
        plugin = todo-comments-nvim; # Highlight todo messages
        type = "lua";
        config = ''
        require("todo-comments").setup()
        '';
      }
      zen-mode-nvim # Create minimalist prose writing environment
      {
        plugin = render-markdown; # Display markdown including docs
        type = "lua";
        config = ''
        require("render-markdown").setup()
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "auto-dark-mode-nvim"; # switch vim color with OS theme
          src = pkgs.fetchFromGitHub {
            owner = "f-person";
            repo = "auto-dark-mode.nvim";
            rev = "14cad96b80a07e9e92a0dcbe235092ed14113fb2";
            hash = "sha256-bSkS2IDkRMQCjaePFYtq39Bokgd1Bwoxgu2ceP7Bh5s=";
          };
        };
        type = "lua";
        config = ''
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
      }
      {
        plugin = telescope-nvim; # UI for pickers
        type = "lua";
        config = ''
          vim.keymap.set('n', '<space>/', "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap = true, silent = true, desc = "Live Grep"})
          vim.keymap.set('n', '<space>f', ":lua require('telescope.builtin').find_files({ find_command = {'rg', '--files', '--hidden', '-g', '!.git' }})<cr>", {noremap = true, silent = true, desc = "Live Grep"})
          vim.keymap.set('n', '<space>b', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true, desc = "Buffers"})
          vim.keymap.set('n', '<space>z', ":lua require('telescope.builtin').find_files({prompt_title = 'Search ZK', shorten_path = false, cwd = '~/src/wiki'})<cr>", {noremap = true, silent = true, desc = "Wiki"})
        '';
      }
      # Treesitter
      # =======================================================================
      {
        plugin = nvim-treesitter.withAllGrammars; # Treesitter
        type = "lua";
        config = ''
          require'nvim-treesitter.configs'.setup {
            highlight = { enable = true, },
            indent = { enable = true },
          }
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          name = "nvim-tree-pairs"; # make % match in TS
          src = pkgs.fetchFromGitHub {
            owner = "yorickpeterse";
            repo = "nvim-tree-pairs";
            rev = "e7f7b6cc28dda6f3fa271ce63b0d371d5b7641da";
            hash = "sha256-fb4EsrWAbm8+dWAhiirCPuR44MEg+KYb9hZOIuEuT24=";
          };
        };
        type = "lua";
        config = ''
        require('tree-pairs').setup()
        '';
      }
      {
        plugin = nvim-treesitter-textobjects; # helix-style selection of TS tree
        type = "lua";
        config = ''
        require'nvim-treesitter.configs'.setup {
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = "<M-o>",
              scope_incremental = "<M-O>",
              scope_decremental = "<M-I>",
              node_incremental = "<M-o>",
              node_decremental = "<M-i>",
            },
          },
        }
        '';
      }
      # Utilities and Mini
      # =======================================================================
      {
        plugin = mini-nvim; # Ridiculously complete family of plugins
        type = "lua";
        config = ''
          require('mini.ai').setup()         -- a/i textobjects
          require('mini.align').setup()      -- aligning
          require('mini.bracketed').setup()  -- unimpaired bindings with TS
          require('mini.comment').setup()    -- TS-wise comments
          require('mini.icons').setup()      -- minimal icons
          require('mini.jump').setup()       -- fFtT work past a line
          require('mini.pairs').setup()      -- pair brackets
          require('mini.statusline').setup() -- minimal statusline
          require('mini.surround').setup({   -- surround
            custom_surroundings = {
              ['l'] = { output = { left = '[', right = ']()'}}
            }
          })
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
      targets-vim     # Classic text-objects
      vim-eunuch      # powerful buffer-level file options
      vim-ragtag      # print/execute bindings for template files
      vim-speeddating # incrementing dates and times
      vim-fugitive    # :Git actions
      vim-rhubarb     # github plugins for fugitive
      # LSP and Completion
      # =======================================================================
      {
        plugin = nvim-lspconfig; # Interface for LSPs
        type = "lua";
        config = lib.fileContents ./lsp.lua;
      }
    ];
  };
}
