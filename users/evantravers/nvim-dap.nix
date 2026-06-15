{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      { plugin = nvim-dap-view; optional = true; }
      {
        plugin = nvim-dap;
        optional = true;
        type = "lua";
        config = ''
          local dap_loaded = false
          local function load_dap()
            if dap_loaded then return end
            dap_loaded = true

            vim.cmd.packadd('nvim-dap')
            vim.cmd.packadd('nvim-dap-view')
            vim.cmd.packadd('nvim-dap-virtual-text')
            vim.cmd.packadd('nvim-dap-ruby')

            local dap = require('dap')

            -- Node.js adapter configuration
            dap.adapters["pwa-node"] = {
              type = "server",
              host = "localhost",
              port = "''${port}",
              executable = {
                command = "js-debug",
                args = { "''${port}" }
              }
            }

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

            require('dap-ruby').setup()

            -- Set final keymaps
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
          end

          -- Stub keymaps that load DAP on first use
          local opts = function(label)
            return {noremap = true, silent = true, desc = label}
          end
          local dap_keys = {
            {'<localleader>db', 'toggle_breakpoint', "Toggle Breakpoint"},
            {'<localleader>dc', 'continue', "Continue/Start Debugging"},
            {'<localleader>di', 'step_into', "Step Into"},
            {'<localleader>dn', 'step_over', "Step Over"},
            {'<localleader>du', 'step_out', "Step Out"},
            {'<localleader>dr', 'repl_toggle', "Toggle REPL"},
            {'<localleader>dU', 'dap_view', "Toggle Debug UI"},
            {'<localleader>dq', 'close', "Quit Debugging"},
            {'<localleader>dk', 'up', "Go Up Call Stack"},
            {'<localleader>dj', 'down', "Go Down Call Stack"},
            {'<localleader>dl', 'run_last', "Run Last Debug Session"},
          }
          for _, k in ipairs(dap_keys) do
            vim.keymap.set('n', k[1], function()
              load_dap()
              -- re-feed the key after loading
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k[1], true, false, true), 'm', false)
            end, opts(k[3]))
          end
        '';
      }
      {
        plugin = nvim-dap-virtual-text;
        optional = true;
      }
      {
        plugin = nvim-dap-ruby;
        optional = true;
      }
    ];
  };
}
