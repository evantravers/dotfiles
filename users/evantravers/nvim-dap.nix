{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.unstable.vimPlugins; [
      {
        plugin = nvim-dap-view;
        type = "lua";
      }
      {
        plugin = nvim-dap;
        type = "lua";
        config = ''
          local dap = require('dap')

          -- Node.js adapter configuration
          -- Requires js-debug to be installed via nix (available in PATH)
          dap.adapters["pwa-node"] = {
            type = "server",
            host = "localhost",
            port = "''${port}",
            executable = {
              command = "js-debug",
              args = { "''${port}" }
            }
          }

          -- JavaScript/TypeScript debugging configurations
          local js_based_languages = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

          for _, language in ipairs(js_based_languages) do
            dap.configurations[language] = {
              {
                type = "pwa-node",
                request = "launch",
                name = "Launch file",
                program = "''${file}",
                cwd = "''${workspaceFolder}",
              },
              {
                type = "pwa-node",
                request = "attach",
                name = "Attach",
                processId = require('dap.utils').pick_process,
                cwd = "''${workspaceFolder}",
              },
              {
                type = "pwa-node",
                request = "launch",
                name = "Debug Jest Tests",
                runtimeExecutable = "node",
                runtimeArgs = {
                  "./node_modules/.bin/jest",
                  "--runInBand",
                },
                rootPath = "''${workspaceFolder}",
                cwd = "''${workspaceFolder}",
                console = "integratedTerminal",
                internalConsoleOptions = "neverOpen",
              },
            }
          end

          -- Elixir debugging configuration
          -- Requires elixir-debug-adapter to be installed via nix (available in PATH)
          dap.adapters["mix_task"] = {
            type = "executable",
            command = "elixir-debug-adapter",
            args = {}
          }

          dap.configurations.elixir = {
            {
              type = "mix_task",
              name = "mix test",
              task = "test",
              taskArgs = {"--trace"},
              request = "launch",
              startApps = true,
              projectDir = "''${workspaceFolder}",
              requireFiles = {
                "test/**/test_helper.exs",
                "test/**/*_test.exs"
              }
            },
            {
              type = "mix_task",
              name = "mix test (current file)",
              task = "test",
              taskArgs = {"--trace", "''${file}"},
              request = "launch",
              startApps = true,
              projectDir = "''${workspaceFolder}",
              requireFiles = {
                "test/**/test_helper.exs",
                "test/**/*_test.exs"
              }
            },
          }

          -- Debug keymaps under <localleader>d
          local opts = function(label)
            return {noremap = true, silent = true, desc = label}
          end

          vim.keymap.set('n', '<localleader>db', function() dap.toggle_breakpoint() end, opts("Toggle Breakpoint"))
          vim.keymap.set('n', '<localleader>dc', function() dap.continue() end, opts("Continue/Start Debugging"))
          vim.keymap.set('n', '<localleader>di', function() dap.step_into() end, opts("Step Into"))
          vim.keymap.set('n', '<localleader>dn', function() dap.step_over() end, opts("Step Over"))
          vim.keymap.set('n', '<localleader>du', function() dap.step_out() end, opts("Step Out"))
          vim.keymap.set('n', '<localleader>dr', function() dap.repl.toggle() end, opts("Toggle REPL"))
          vim.keymap.set('n', '<localleader>dU', function() vim.cmd('DapViewToggle') end, opts("Toggle Debug UI"))
          vim.keymap.set('n', '<localleader>dq', function() dap.close() end, opts("Quit Debugging"))
          vim.keymap.set('n', '<localleader>dk', function() dap.up() end, opts("Go Up Call Stack"))
          vim.keymap.set('n', '<localleader>dj', function() dap.down() end, opts("Go Down Call Stack"))
          vim.keymap.set('n', '<localleader>dl', function() dap.run_last() end, opts("Run Last Debug Session"))
        '';
      }
      {
        plugin = nvim-dap-virtual-text;
        type = "lua";
        config = ''
          require("nvim-dap-virtual-text").setup({
            enabled = true,
            enabled_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
            only_first_definition = true,
            all_references = false,
            clear_on_continue = false,
            display_callback = function(variable, buf, stackframe, node, options)
              if #variable.value > 15 then
                return " " .. string.sub(variable.value, 1, 15) .. "... "
              end
              return " " .. variable.value .. " "
            end,
          })
        '';
      }
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "nvim-dap-ruby";
          version = "2025-07-08";
          src = pkgs.fetchFromGitHub {
            owner = "suketa";
            repo = "nvim-dap-ruby";
            rev = "ba36f9905ca9c6d89e5af5467a52fceeb2bbbf6d";
            sha256 = "sha256-57BBhdrikDEswZe2QW+jHMSgfXIjauc6iDNpWS0YUaU=";
          };
        };
        type = "lua";
        config = ''
          require('dap-ruby').setup()
        '';
      }
    ];
  };
}
