{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.vimPlugins; [
      {
        plugin = zen-mode-nvim;
        optional = true;
        type = "lua";
        config = ''
          -- set keybind for searching my wiki (no zen-mode dependency)
          vim.keymap.set('n', '<space>m', function()
            vim.cmd.packadd('zen-mode.nvim')

            function _G.toggleProse()
              require("zen-mode").toggle({
                window = {
                  backdrop = 1,
                  width = 80
                },
                plugins = {
                  tmux = { enabled = false }
                },
                on_open = function()
                  vim.o.scrolloff = 999
                  vim.o.relativenumber = false
                  vim.o.number = false
                  vim.o.wrap = true
                  vim.o.linebreak = true
                  vim.o.colorcolumn = "0"

                  vim.keymap.set('n', 'j', 'gj', {noremap = true, buffer = true})
                  vim.keymap.set('n', 'k', 'gk', {noremap = true, buffer = true})
                end,
                on_close = function()
                  vim.o.scrolloff = 3
                  vim.o.relativenumber = true
                  vim.o.wrap = false
                  vim.o.linebreak = false
                  vim.o.colorcolumn = "80"

                  vim.keymap.set('n', 'j', 'j', {noremap = true, buffer = true})
                  vim.keymap.set('n', 'k', 'k', {noremap = true, buffer = true})
                end
              })
            end

            -- replace keymap with direct call after first load
            vim.keymap.set('n', '<space>m', ':lua _G.toggleProse()<cr>', {noremap = true, silent = true, desc = "Toggle Writing Mode"})
            _G.toggleProse()
          end, {noremap = true, silent = true, desc = "Toggle Writing Mode"})
        '';
      }
    ];
  };
}
