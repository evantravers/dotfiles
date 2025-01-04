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
          solid_line_nr    = true,
          solid_vert_split = true,
        }
        vim.cmd.colorscheme "zenbones"
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
            vim.o.background = 'dark'
          end,
          set_light_mode = function()
            vim.o.background = 'light'
          end,
        })
        '';
      }
      lush-nvim # Required by zenbones for all the colors
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
      {
        plugin = render-markdown-nvim; # Display markdown including docs
        type = "lua";
        config = ''
        require("render-markdown").setup({
          checkbox = {
            custom = {
              todo = { raw = "[-]", rendered = "󰜺", highlight = "RenderMarkdownCancelled" },
              cancelled = { raw = '[-]', rendered = '󰜺 ', highlight = 'RenderMarkdownTodo' },
              incomplete = { raw = '[/]', rendered = '󰦖 ', highlight = 'RenderMarkdownTodo' },
              forwarded = { raw = "[>]", rendered = "", highlight = "RenderMarkdownForwarded" },
              scheduled = { raw = "[<]", rendered = "󰸘", highlight = "RenderMarkdownScheduled" },
            }
          }
        })
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
        local opts = function(label)
          return {noremap = true, silent = true, desc = label}
        end
        require('mini.ai').setup()         -- a/i textobjects
        require('mini.align').setup()      -- aligning
        require('mini.bracketed').setup()  -- unimpaired bindings with TS
        require('mini.diff').setup()       -- hunk management and highlight
        require('mini.extra').setup()      -- extra p}ickers
        require('mini.files').setup()      -- file manipulation
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
        require('mini.operators').setup()
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
            choose_marked = '<M-x>'
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
        vim.keymap.set('n', '<space>F', "<cmd>Pick files tool='git'<cr>", opts("Find Files in CWD"))
        vim.keymap.set('n', '<space>f', "<cmd>Pick files_root tool='git'<cr>", opts("Find Files"))
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
