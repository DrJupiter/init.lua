return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        local languages = {
            "lua",
            "vim",
            "vimdoc",
            "query",
            "markdown",
            "markdown_inline",
            "latex",
            "rust",
            "html",
            "javascript",
            "python",
            "typescript",
            "svelte",
            "c",
            "cpp",
        }

        treesitter.setup({})
        if #vim.api.nvim_list_uis() > 0 then
            treesitter.install(languages)
        end

        local group = vim.api.nvim_create_augroup("jupiter_treesitter", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            callback = function(args)
                pcall(vim.treesitter.start, args.buf)
            end,
        })
    end
}
