{ config, lib, pkgs, ... }:
{
  options.programs.neovim.ai.enable = lib.mkEnableOption "Neovim AI integration";

  config = lib.mkIf (config.programs.neovim.enable && config.programs.neovim.ai.enable) {
    programs.neovim = {
      plugins = with pkgs.vimPlugins; [
        { plugin = plenary-nvim; optional = true; }
        # CodeCompanion as the core AI source
        {
          plugin = codecompanion-nvim;
          optional = true;
          type = "lua";
          config = ''
            local function load_codecompanion()
              vim.cmd.packadd('plenary.nvim')
              vim.cmd.packadd('codecompanion-nvim')
              vim.cmd.packadd('markview.nvim')

              -- required for githubmodels token via gh
              vim.env["CODECOMPANION_TOKEN_PATH"] = vim.fn.expand("~/.config")
              local ai_strategy = os.getenv("AI_STRATEGY") or "llama_cpp"

              require("codecompanion").setup({
                interactions = {
                  chat = {
                    adapter = ai_strategy,
                    keymaps = {
                      close = {modes = { n = "<C-q>", i = "<C-q>" }, opts = {}},
                      options = {modes = { n = "<leader>h" }, opts = {}},
                    },
                  },
                  inline = { adapter = ai_strategy }
                },
                display = {
                  chat = {
                    intro_message = "Welcome to CodeCompanion ✨! Press <leader>h for options",
                  },
                },
                adapters = {
                  acp = {
                    devclarity_claude_code = function()
                      return require("codecompanion.adapters").extend("claude_code", {
                        env = {
                          ANTHROPIC_API_KEY = "cmd:op read op://Private/yy6goxmme5pm5jkhsmspolopme/credential --no-newline"
                        },
                        commands = {
                          default = {
                            "claude-agent-acp"
                          }
                        }
                      })
                    end,
                    opencode = function()
                      return require('codecompanion.adapters').extend('claude_code', {
                        name = 'opencode',
                        formatted_name = 'OpenCode',
                        commands = {
                          default = { 'opencode', 'acp' },
                        },
                      })
                    end
                  },
                  http = {
                    -- hide adapters that I haven't explicitly configured
                    opts = { show_defaults = false, },
                    anthropic = function()
                      return require("codecompanion.adapters").extend("anthropic", {
                        env = {
                          api_key = "cmd:op read op://Private/Claude/credential --no-newline"
                        }
                      })
                    end,
                    githubmodels = function()
                      return require("codecompanion.adapters").extend("githubmodels", {
                        schema = {
                          model = {
                            default = "gpt-4.1",
                          },
                        },
                      })
                    end,
                    llama_cpp = function()
                      return require("codecompanion.adapters").extend("openai_compatible", {
                        name = "llama_cpp",
                        formatted_name = "llama.cpp",
                        env = {
                          url = "http://localhost:8080",
                          api_key = "none",
                        },
                        schema = {
                          model = {
                            default = "bartowski/Qwen_Qwen3.6-27B-GGUF:Q4_1",
                          },
                        },
                      })
                    end
                  }
                },
                extensions = {
                }
              })

              require("markview").setup({
                preview = {
                  filetypes = { "codecompanion" },
                  ignore_buftypes = {},
                }
              })

              -- set final keymaps
              vim.keymap.set({ "n", "v" }, "<LocalLeader>A", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true, desc = "✨ Actions" })
              vim.keymap.set({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, desc = "✨ Toggle Chat" })
              vim.keymap.set("v", "<LocalLeader>c", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true, desc = "✨ Add to Chat" })
            end

            -- Stub keymaps that load on first use
            vim.keymap.set({ "n", "v" }, "<LocalLeader>A", function()
              load_codecompanion()
              vim.cmd('CodeCompanionActions')
            end, { noremap = true, silent = true, desc = "✨ Actions" })

            vim.keymap.set({ "n", "v" }, "<LocalLeader>a", function()
              load_codecompanion()
              vim.cmd('CodeCompanionChat Toggle')
            end, { noremap = true, silent = true, desc = "✨ Toggle Chat" })

            vim.keymap.set("v", "<LocalLeader>c", function()
              load_codecompanion()
              vim.cmd('CodeCompanionChat Add')
            end, { noremap = true, silent = true, desc = "✨ Add to Chat" })

            -- CmdUndefined for :CodeCompanion commands
            vim.api.nvim_create_autocmd('CmdUndefined', {
              pattern = 'CodeCompanion*',
              once = true,
              callback = function()
                load_codecompanion()
                return true
              end
            })

            -- Expand 'cc' into 'CodeCompanion' in the command line
            vim.cmd([[cab cc CodeCompanion]])
          '';
        }

        # Markview for making codecompanion prettier
        { plugin = markview-nvim; optional = true; }
      ];
    };
  };
}
