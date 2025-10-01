---@diagnostic disable: undefined-global

vim.opt.tabstop = 2
vim.opt.cursorcolumn = false
vim.opt.ignorecase = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.incsearch = true
vim.opt.signcolumn = "yes"
local map = vim.keymap.set
vim.g.mapleader = " "
map('n', '<leader>o', ':update<CR> :source<CR>')
map('n', '<leader>w', ':write<CR>')
map('n', '<leader>q', ':quit<CR>')
map({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>')
map({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>')
map({ 'n', 'v', 'x' }, '<leader>s', ':e #<CR>')
map({ 'n', 'v', 'x' }, '<leader>S', ':sf #<CR>')
vim.pack.add({
	{ src = "https://github.com/vague2k/vague.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/NvChad/showkeys", opt = true },
})
require "mason".setup()
require "showkeys".setup({ position = "top-right" })
require "mini.pick".setup()
require "oil".setup()

vim.lsp.enable({
    "lua_ls",
    "emmet_ls",
    "html",
    "cssls",
    "jsonls",
    "tsserver",
    "tailwindcss",
})

map('n', '<leader>f', ":Pick files<CR>", {})
map('n', '<leader>h', ":Pick help<CR>", {})
map('n', '<leader>e', ":Oil<CR>", {})
map('t', '<C-\\><C-n>', "<C-\\><C-n>", {})
map('t', '<Esc>', "<C-\\><C-n>", {})
map('n', '<leader>lf', vim.lsp.buf.format)

require("nvim-treesitter.configs").setup({
    highlight = {enable = true}
})

require "vague".setup({ transparent = true })
vim.cmd("colorscheme vague")
vim.cmd(":hi statusline guibg=NONE")