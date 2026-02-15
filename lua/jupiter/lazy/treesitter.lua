return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        local parsers = require("nvim-treesitter.parsers")
        local installing = {}

        treesitter.setup({})

        local function is_installed(lang)
            return vim.tbl_contains(treesitter.get_installed("parsers"), lang)
        end

        local function is_allowed(lang)
            local parser = parsers[lang]
            if not parser then
                return false
            end
            return (parser.tier or 4) <= 2
        end

        local function notify_if_ui(msg, level)
            if #vim.api.nvim_list_uis() > 0 then
                vim.notify(msg, level)
            end
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("jupiter_treesitter", { clear = true }),
            desc = "Auto-install/start treesitter parser",
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                local lang = vim.treesitter.language.get_lang(ft) or ft
                if lang == "" then
                    return
                end

                local ui_attached = #vim.api.nvim_list_uis() > 0
                local known = parsers[lang] ~= nil

                if ui_attached and known and is_allowed(lang) and not is_installed(lang) and not installing[lang] then
                    local ok, task_or_err = pcall(treesitter.install, { lang })
                    if not ok then
                        notify_if_ui("treesitter install failed for " .. lang .. ": " .. tostring(task_or_err), vim.log.levels.WARN)
                        return
                    end

                    local task = task_or_err
                    if task and type(task.await) == "function" then
                        installing[lang] = true
                        task:await(function(err, success)
                            installing[lang] = nil
                            if err or not success then
                                notify_if_ui(
                                    "treesitter install failed for " .. lang .. ": " .. tostring(err or "unknown error"),
                                    vim.log.levels.WARN
                                )
                                return
                            end

                            if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype == ft then
                                local ok_start_after, err_start_after = pcall(vim.treesitter.start, args.buf)
                                if not ok_start_after then
                                    notify_if_ui(
                                        "treesitter start failed for " .. lang .. ": " .. tostring(err_start_after),
                                        vim.log.levels.DEBUG
                                    )
                                end
                            end
                        end)
                    end

                    return
                end

                local ok_start, err_start = pcall(vim.treesitter.start, args.buf)
                if not ok_start and known and ui_attached then
                    notify_if_ui("treesitter start failed for " .. lang .. ": " .. tostring(err_start), vim.log.levels.DEBUG)
                end
            end,
        })
    end
}
