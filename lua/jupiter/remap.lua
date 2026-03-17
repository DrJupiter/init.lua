vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<Tab>", function()
    require("conform").format({ timeout_ms = 3000, lsp_fallback = true })
    vim.cmd.write()
end, { desc = 'Format (if supported) and save current buffer' })

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y"]])
