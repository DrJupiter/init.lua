local M = {}

local dir = vim.fn.stdpath("data") .. "/cppdoc"
local group = vim.api.nvim_create_augroup("jupiter_cppdoc", { clear = true })
local view = { win = nil, name = nil, stack = {} }
local index

vim.treesitter.query.add_predicate("cpp-docs?", function(_, _, source)
    return type(source) == "number" and vim.b[source].cpp_docs == true
end, { force = true, all = false })

local function pages()
    if not index and vim.fn.filereadable(dir .. "/index.json") == 1 then
        index = vim.json.decode(table.concat(vim.fn.readfile(dir .. "/index.json"), "\n"))
    end
    return index
end

local function close()
    if view.win and vim.api.nvim_win_is_valid(view.win) then
        vim.api.nvim_win_close(view.win, true)
    end
    view.win, view.name, view.stack = nil, nil, {}
end

vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter" }, {
    group = group,
    callback = function()
        if view.win and vim.api.nvim_get_current_win() ~= view.win then
            close()
        end
    end,
})

local function symbol_at_cursor()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local from = 1

    while true do
        local first, last = line:find("[%w_:]+", from)
        if not first or first > col then
            return nil
        end
        if last >= col then
            local symbol = line:sub(first, last)
            symbol = symbol:gsub("^:+", ""):gsub(":+$", "")
            return symbol ~= "" and symbol or nil
        end
        from = last + 1
    end
end

local function show(name)
    local available = pages()
    if not available then
        vim.notify("cppdoc: no docs yet, run :CppdocUpdate", vim.log.levels.WARN)
        return true
    end

    local path = available[name]
    if not path then
        return false
    end

    local lines = vim.fn.readfile(dir .. "/md/" .. path .. ".md")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.b[buf].cpp_docs = true
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    pcall(vim.treesitter.start, buf, "markdown")

    vim.keymap.set("n", "q", close, { buffer = buf })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf })
    vim.keymap.set("n", "K", M.follow, { buffer = buf })
    vim.keymap.set("n", "<C-]>", M.follow, { buffer = buf })
    vim.keymap.set("n", "<C-t>", M.back, { buffer = buf })

    local width = math.min(92, vim.o.columns - 8)
    local height = math.min(#lines, math.floor(vim.o.lines * 0.8))
    local config = {
        relative = "editor",
        width = width,
        height = height,
        row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " " .. name .. " ",
        title_pos = "center",
    }

    if view.win and vim.api.nvim_win_is_valid(view.win) then
        vim.api.nvim_win_set_buf(view.win, buf)
        vim.api.nvim_win_set_config(view.win, config)
    else
        view.win = vim.api.nvim_open_win(buf, false, config)
    end

    vim.wo[view.win].wrap = true
    vim.wo[view.win].linebreak = true
    vim.wo[view.win].conceallevel = 2
    vim.wo[view.win].concealcursor = "nc"
    view.name = name
    return true
end

function M.open(name)
    if view.win and vim.api.nvim_win_is_valid(view.win) then
        if view.name == name then
            vim.api.nvim_set_current_win(view.win)
            return true
        end
        table.insert(view.stack, view.name)
    end
    return show(name)
end

function M.follow()
    local symbol = symbol_at_cursor()
    if not symbol then
        return
    end

    local scope = view.name and view.name:match("^(.*)::[^:]+$")
    local candidates = { symbol }
    if scope then
        table.insert(candidates, scope .. "::" .. symbol)
    end
    table.insert(candidates, "std::" .. symbol)

    for _, candidate in ipairs(candidates) do
        if M.open(candidate) then
            return
        end
    end
    vim.notify("cppdoc: no page for " .. symbol, vim.log.levels.WARN)
end

function M.back()
    local previous = table.remove(view.stack)
    if previous then
        show(previous)
    end
end

local function receiver_position()
    local line = vim.api.nvim_get_current_line()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local start = cursor[2] + 1
    while start > 1 and line:sub(start - 1, start - 1):match("[%w_]") do
        start = start - 1
    end

    local prefix = line:sub(1, start - 1):gsub("%s+$", "")
    prefix = prefix:match("^(.-)%->$") or prefix:match("^(.-)%.$")
    if not prefix then
        return nil
    end

    prefix = prefix:gsub("%s+$", "")
    local receiver = prefix:match("[%w_]+$")
    if not receiver then
        return nil
    end
    return { line = cursor[1] - 1, character = #prefix - #receiver }
end

local function class_candidates(typename)
    local out = {}
    for _, t in ipairs({ typename, typename:match("%(aka ([^)]+)%)") }) do
        t = t:gsub("%(aka [^)]+%)", ""):gsub("%b<>", ""):gsub("%f[%w_]const%f[^%w_]", ""):gsub("[%s*&]+$", ""):gsub("^%s+", "")
        if t ~= "" then
            table.insert(out, vim.startswith(t, "std::") and t or "std::" .. t)
        end
    end
    return out
end

function M.hover(client, bufnr)
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local receiver = receiver_position()

    client:request("textDocument/symbolInfo", params, function(err, res)
        local info = not err and res and res[1]
        local scope = info and (info.containerName or ""):gsub("%b<>", "")
        if not info or not vim.startswith(scope, "std::") then
            return vim.lsp.buf.hover()
        end
        if M.open(scope .. info.name) then
            return
        end
        if not receiver then
            return vim.lsp.buf.hover()
        end

        client:request("textDocument/hover", { textDocument = params.textDocument, position = receiver }, function(_, hover)
            local value = type(hover) == "table" and type(hover.contents) == "table" and hover.contents.value or ""
            for _, class in ipairs(class_candidates(value:match("Type: `([^`]+)`") or "")) do
                if M.open(class .. "::" .. info.name) then
                    return
                end
            end
            vim.lsp.buf.hover()
        end, bufnr)
    end, bufnr)
end

function M.search()
    local available = pages()
    if not available then
        vim.notify("cppdoc: no docs yet, run :CppdocUpdate", vim.log.levels.WARN)
        return
    end

    local names = vim.tbl_keys(available)
    table.sort(names)

    local actions = require("telescope.actions")
    require("telescope.pickers")
        .new({}, {
            prompt_title = "cppreference",
            finder = require("telescope.finders").new_table({ results = names }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(prompt_buf)
                actions.select_default:replace(function()
                    local entry = require("telescope.actions.state").get_selected_entry()
                    actions.close(prompt_buf)
                    M.open(entry[1])
                end)
                return true
            end,
        })
        :find()
end

function M.update()
    local cwd = vim.fn.stdpath("config") .. "/cppdoc"
    vim.notify("cppdoc: downloading and converting cppreference, takes about a minute")

    vim.system({ "python3", cwd .. "/build.py", dir }, { cwd = cwd, text = true }, function(out)
        index = nil
        vim.schedule(function()
            if out.code == 0 then
                local report = vim.split(vim.trim(out.stdout or "ready"), "\n")
                vim.notify("cppdoc: " .. report[#report])
            else
                vim.notify("cppdoc: build failed\n" .. (out.stderr or ""), vim.log.levels.ERROR)
            end
        end)
    end)
end

vim.api.nvim_create_user_command("Cppdoc", M.search, {})
vim.api.nvim_create_user_command("CppdocUpdate", M.update, {})

return M
