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
  local clipboard_cache = {
    ["+"] = { lines = {}, regtype = "v" },
    ["*"] = { lines = {}, regtype = "v" },
  }

  local osc_copy_plus = osc52.copy("+")
  local osc_copy_star = osc52.copy("*")
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = function(lines, regtype)
        clipboard_cache["+"] = { lines = vim.deepcopy(lines), regtype = regtype }
        osc_copy_plus(lines)
      end,
      ["*"] = function(lines, regtype)
        clipboard_cache["*"] = { lines = vim.deepcopy(lines), regtype = regtype }
        osc_copy_star(lines)
      end,
    },
    paste = {
      ["+"] = function()
        local cache = clipboard_cache["+"] or {}
        return cache.lines or {}, cache.regtype or "v"
      end,
      ["*"] = function()
        local cache = clipboard_cache["*"] or {}
        return cache.lines or {}, cache.regtype or "v"
      end,
  },
    cache_enabled = 0,
  }
end
