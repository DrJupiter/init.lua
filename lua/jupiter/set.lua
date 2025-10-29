vim.g.mapleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"  -- Highlights the 80th column

vim.opt.wrap = true         -- Enables/Disables line wrapping
local has_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if has_osc52 then
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
  vim.opt.clipboard:append("unnamedplus")
end
