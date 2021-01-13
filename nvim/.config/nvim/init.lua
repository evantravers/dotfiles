vim.cmd 'packadd paq-nvim'
local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt=true}

paq {'neovim/nvim-lspconfig'}
paq {'nvim-lua/completion-nvim'}
paq {'nvim-lua/lsp_extensions.nvim'}
