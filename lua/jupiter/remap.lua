vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

local function buf_has_lsp_formatter(bufnr)
    local clients = vim.lsp.get_clients({ bufnr = bufnr }) or {}

    for _, client in ipairs(clients) do
        if client.supports_method and client.supports_method("textDocument/formatting") then
            return true
        end
        if client.server_capabilities and client.server_capabilities.documentFormattingProvider then
            return true
        end
    end

    return false
end

vim.keymap.set("n", "<Tab>", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if buf_has_lsp_formatter(bufnr) then
        vim.lsp.buf.format({ bufnr = bufnr, async = false })
    end

    vim.cmd.write()
end, { desc = 'Format (if supported) and save current buffer' })

vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y"]])
