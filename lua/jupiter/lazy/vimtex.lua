return {
  "lervag/vimtex",
  lazy = false,     -- we don't want to lazy load VimTeX
  -- tag = "v2.15", -- uncomment to pin to a specific release
  init = function()
    -- VimTeX configuration goes here, e.g.
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_compiler_silent = 0
    vim.g.vimtex_quickfix_open_on_warning = 0
    vim.g.tex_conceal = 'abdmg'
    vim.g.vimtex_compiler_latexmk = {
      -- Add compiler options here
      options = {
        "-pdf",
        "-shell-escape",  -- <--- THIS IS THE IMPORTANT LINE
        "-verbose",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
      },
    }
  end
}
