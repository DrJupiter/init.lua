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

local uv = vim.uv or vim.loop
local branch_cache = {}
local branch_cache_ttl_ms = 2000
local docker_segment_cache

local function now_ms()
  return math.floor((uv.hrtime() or 0) / 1000000)
end

local function read_first_line(path)
  local ok, lines = pcall(vim.fn.readfile, path, "", 1)
  if not ok or #lines == 0 then
    return ""
  end
  return lines[1] or ""
end

local function resolve_git_dir(git_marker)
  local stat = uv.fs_stat(git_marker)
  if not stat then
    return nil
  end

  if stat.type == "directory" then
    return git_marker
  end

  local first = read_first_line(git_marker)
  local pointer = first:match("^gitdir:%s*(.+)%s*$")
  if not pointer or pointer == "" then
    return nil
  end

  if pointer:sub(1, 1) == "/" then
    return vim.fs.normalize(pointer)
  end

  local parent = vim.fs.dirname(git_marker) or "."
  return vim.fs.normalize(parent .. "/" .. pointer)
end

local function current_repo_root_and_git_dir()
  local file_path = vim.api.nvim_buf_get_name(0)
  local start
  if file_path == "" then
    start = vim.fs.normalize(uv.cwd() or ".")
  else
    start = vim.fs.dirname(vim.fs.normalize(file_path)) or "."
  end

  local markers = vim.fs.find(".git", { path = start, upward = true, limit = 1 })
  local marker = markers[1]
  if not marker then
    return nil, nil
  end

  local git_dir = resolve_git_dir(marker)
  if not git_dir then
    return nil, nil
  end

  local root = vim.fs.dirname(marker)
  return root, git_dir
end

local function parse_head_branch(head_line)
  if head_line == "" then
    return ""
  end

  local branch = head_line:match("^ref:%s+refs/heads/(.+)$")
  if branch then
    return branch
  end

  if head_line:match("^[0-9a-fA-F]+$") then
    return head_line:sub(1, 7)
  end

  return ""
end

local function current_branch()
  local repo_root, git_dir = current_repo_root_and_git_dir()
  if not repo_root or not git_dir then
    return ""
  end

  local cached = branch_cache[repo_root]
  local now = now_ms()
  if cached and (now - cached.ts) < branch_cache_ttl_ms then
    return cached.value
  end

  local head = read_first_line(git_dir .. "/HEAD")
  local branch = parse_head_branch(head)
  branch_cache[repo_root] = { value = branch, ts = now }
  return branch
end

local docker_colors = {
  "#cc241d",
  "#98971a",
  "#d79921",
  "#458588",
  "#b16286",
  "#689d6a",
}

local function define_docker_highlights()
  for i, color in ipairs(docker_colors) do
    vim.api.nvim_set_hl(0, "JupiterDocker" .. i, {
      fg = color,
      ctermfg = i,
      bold = true,
    })
  end
end

local function docker_segment()
  if docker_segment_cache ~= nil then
    return docker_segment_cache
  end

  if not uv.fs_stat("/.dockerenv") then
    docker_segment_cache = ""
    return docker_segment_cache
  end

  local hostname = uv.os_gethostname() or ""
  local hex = hostname:sub(1, 6)
  local value = tonumber(hex, 16)

  if not value then
    local sum = 0
    for i = 1, #hostname do
      sum = sum + hostname:byte(i)
    end
    value = sum
  end

  local idx = (value % #docker_colors) + 1
  docker_segment_cache = "%#JupiterDocker" .. idx .. "#●🐳●%*"
  return docker_segment_cache
end

local function escape_statusline_text(text)
  return (text or ""):gsub("%%", "%%%%")
end

_G.JupiterStatusline = function()
  local sections = {}
  local branch = current_branch()
  if branch ~= "" then
    table.insert(sections, " " .. escape_statusline_text(branch) .. " ")
  end

  local docker = docker_segment()
  if docker ~= "" then
    table.insert(sections, docker)
  end

  if #sections == 0 then
    return "%F"
  end

  return "%F%=  " .. table.concat(sections, " | ")
end

define_docker_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("JupiterStatuslineDockerColors", { clear = true }),
  callback = define_docker_highlights,
})

vim.opt.statusline = "%!v:lua.JupiterStatusline()"
