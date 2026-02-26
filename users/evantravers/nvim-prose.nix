{ pkgs, ... }:
{
  programs.neovim = {
    plugins = with pkgs.unstable.vimPlugins; [
      {
        plugin = zen-mode-nvim;
        type = "lua";
        config = ''
          -- set keybind for searching my wiki
          vim.keymap.set('n', "<space>z", "<cmd>lua MiniPick.builtin.files(nil, {source={cwd=vim.fn.expand('~/src/wiki')}})<cr>", {noremap = true, silent = true, desc = "Wiki"})

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
    ];
  };
}
