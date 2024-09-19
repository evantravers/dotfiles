{lib, pkgs, ...}:
{
  home.file.".config/nvim/.vimrc".source = ../../.config/nvim/.config/nvim/.vimrc;

  home.activation.mkdirNvimFolders = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.config/nvim/backups $HOME/.config/nvim/swaps $HOME/.config/nvim/undo
  '';

  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraLuaConfig = lib.fileContents ../../.config/nvim/.config/nvim/init.lua;

    plugins = with pkgs.vimPlugins; [
      # =======================================================================
      # UI AND THEMES
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
      lush-nvim # Required by zenbones for all the colors
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
        plugin = zen-mode-nvim; # Create minimalist prose writing environment
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
              gitsigns = { enabled = true },
              tmux = { enabled = true },
              wezterm = {
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
          {noremap = true, silent = true, desc = "Toggle Writing Mode"}
        )
        '';
      }
      {
        plugin = render-markdown; # Display markdown including docs
        type = "lua";
        config = ''
        require("render-markdown").setup()
        '';
      }
      {
        plugin = telescope-nvim; # UI for pickers
        type = "lua";
        config = ''
          vim.keymap.set('n', '<space>/', "<cmd>lua require('telescope.builtin').live_grep()<cr>", {noremap = true, silent = true, desc = "Live Grep"})
          vim.keymap.set('n', '<space>f', ":lua require('telescope.builtin').git_files()<cr>", {noremap = true, silent = true, desc = "Find Files"})
          vim.keymap.set('n', '<space>F', ":lua require('telescope.builtin').find_files()<cr>", {noremap = true, silent = true, desc = "Find Files @ CWD"})
          vim.keymap.set('n', '<space>b', ":lua require('telescope.builtin').buffers()<cr>", {noremap = true, silent = true, desc = "Buffers"})
          vim.keymap.set('n', '<space>z', ":lua require('telescope.builtin').find_files({prompt_title = 'Search ZK', shorten_path = false, cwd = '~/src/wiki'})<cr>", {noremap = true, silent = true, desc = "Wiki"})
        '';
      }
      # =======================================================================
      # TREESITTER
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
              node_incremental = "<M-o>",
              node_decremental = "<M-i>",
            },
          },
        }
        '';
      }
      # =======================================================================
      # UTILITIES AND MINI
      # =======================================================================
      {
        plugin = mini-nvim; # Ridiculously complete family of plugins
        type = "lua";
        config = ''
          require('mini.ai').setup()         -- a/i textobjects
          require('mini.align').setup()      -- aligning
          require('mini.bracketed').setup()  -- unimpaired bindings with TS
          require('mini.comment').setup()    -- TS-wise comments
          require('mini.diff').setup()       -- hunk management and highlight
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
          require('mini.pairs').setup()      -- pair brackets
          require('mini.statusline').setup() -- minimal statusline
          require('mini.surround').setup({   -- surround
            custom_surroundings = {
              ['l'] = { output = { left = '[', right = ']()'}}
            }
          })
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
      targets-vim     # Classic text-objects
      vim-eunuch      # powerful buffer-level file options
      vim-ragtag      # print/execute bindings for template files
      vim-speeddating # incrementing dates and times
      vim-fugitive    # :Git actions
      vim-rhubarb     # github plugins for fugitive
      # =======================================================================
      # LSP AND COMPLETION
      # =======================================================================
      {
        plugin = nvim-lspconfig; # Interface for LSPs
        type = "lua";
        config = lib.fileContents ./lsp.lua;
      }
    ];
  };
}
