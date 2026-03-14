-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
vim.opt.scrolloff = 999
vim.opt.sidescrolloff = 999

vim.keymap.set("i", "<D-v>", "<C-r>+", {
  noremap = true,
  silent = true,
  desc = "Paste in insert mode",
})

vim.opt.background = "dark"
vim.cmd "colorscheme rose-pine"
