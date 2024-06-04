local ido = {
  utils = {},
  buffer = {},
  window = {},
  mappings = {},
  registers = {}
}

local fzy = require("fzy.lua")
local version = vim.version().minor
local redraw_needed = version < 7
local title_possible = version >= 9
local current_title = nil

function ido.open(name)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buffer, "bufhidden", "wipe")

  local window = vim.api.nvim_open_win(buffer, true, ido.window.opts)
  vim.api.nvim_win_set_option(window, "wrap", false)
  vim.api.nvim_win_set_option(window,
    "winhighlight", "Normal:Normal,FloatBorder:WinSeparator")

  ido.buffer[name] = buffer
  ido.window[name] = window
end

function ido.next()
  local cursor = vim.api.nvim_win_get_cursor(ido.window.items)

  if cursor[1] == vim.api.nvim_buf_line_count(ido.buffer.items) then
    cursor[1] = 1
  else
    cursor[1] = cursor[1] + 1
  end

  vim.api.nvim_win_set_cursor(ido.window.items, cursor)
  if redraw_needed then
    vim.cmd("mode")
    if current_title then
      print(current_title)
    end
  end
end

function ido.prev()
  local cursor = vim.api.nvim_win_get_cursor(ido.window.items)

  if cursor[1] == 1 then
    cursor[1] = vim.api.nvim_buf_line_count(ido.buffer.items)
  else
    cursor[1] = cursor[1] - 1
  end

  vim.api.nvim_win_set_cursor(ido.window.items, cursor)
  if redraw_needed then
    vim.cmd("mode")
    if current_title then
      print(current_title)
    end
  end
end

function ido.exit()
  ido.active = false

  vim.cmd("stopinsert")
  vim.fn.win_gotoid(ido.last)
  vim.api.nvim_buf_delete(ido.buffer.query, {force = true})
  vim.api.nvim_buf_delete(ido.buffer.items, {force = true})
end

function ido.get_item()
  local line = vim.api.nvim_win_get_cursor(ido.window.items)[1]
  return vim.api.nvim_buf_get_lines(ido.buffer.items, line - 1, line, false)[1]
end

function ido.get_query()
  return vim.api.nvim_buf_get_lines(ido.buffer.query, 0, 1, false)[1]
end

function ido.accept_item()
  local item = ido.get_item()

  if item == "" then
    item = ido.get_query()
  end

  ido.exit()
  ido.accept(item)
end

function ido.accept_query()
  local item = ido.get_query()
  ido.exit()
  ido.accept(item)
end

function ido.bind(binds)
  if ido.active then
    if vim.keymap then
      for key, func in pairs(binds) do
        vim.keymap.set("i", key, func, {buffer = ido.buffer.query})
      end
    else
      for key, func in pairs(binds) do
        table.insert(ido.bindings, func)
        vim.api.nvim_buf_set_keymap(ido.buffer.query, "i", key,
          "<c-o>:lua require('ido').bindings["..#ido.bindings.."]()<cr>",
          {silent = true, noremap = true})
      end
    end
  else
    for key, func in pairs(binds) do
      ido.mappings[key] = func
    end
  end
end

function ido.match()
  local query = ido.get_query()
  if query == "" then
    vim.api.nvim_buf_set_lines(ido.buffer.items, 0, -1, false, ido.items)
    return
  end

  local matches = fzy.filter(query, ido.items)
  table.sort(matches, function (a, b) return a[3] > b[3] end)

  vim.api.nvim_buf_set_lines(ido.buffer.items, 0, -1, false,
    vim.tbl_map(function (e) return e[1] end, matches))

  vim.api.nvim_buf_clear_namespace(ido.buffer.items, ido.highlights, 0, -1)
  for line, match in ipairs(matches) do
    for _, position in ipairs(match[2]) do
      vim.api.nvim_buf_add_highlight(
        ido.buffer.items, ido.highlights, "IncSearch",
        line - 1, position - 1, position)
    end
  end

  vim.api.nvim_win_set_cursor(ido.window.items, {1, 0})
end

function ido.title(title)
  current_title = title
  if title_possible then
    ido.window.opts.title = " "..title.." "
    vim.api.nvim_win_set_config(ido.window.query, ido.window.opts)
  else
    print(title)
  end
end

function ido.start(items, accept, title)
  ido.last = vim.fn.win_getid()
  ido.items = items
  ido.active = true
  ido.accept = accept

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  ido.window.opts = {
    style = "minimal",
    border = "rounded",
    relative = "editor",

    row = math.ceil(height * 0.1),
    col = math.ceil(width * 0.15),
    width = math.ceil(width * 0.7),
    height = math.ceil(height * 0.8) - 3
  }

  ido.open("items")
  vim.api.nvim_win_set_option(ido.window.items, "cursorline", true)

  ido.window.opts.row = ido.window.opts.row - 2
  ido.window.opts.height = 1
  ido.window.opts.border = {"╭", "─" ,"╮", "│", "┤", "─", "├", "│"}

  current_title = title
  if title then
    if title_possible then
      ido.window.opts.title = " "..title.." "
      ido.window.opts.title_pos = "center"
    else
      print(title)
    end
  end
  ido.open("query")

  ido.highlights = vim.api.nvim_create_namespace("")

  vim.api.nvim_buf_set_lines(ido.buffer.items, 0, -1, false, ido.items)
  vim.api.nvim_buf_attach(ido.buffer.query, true, {
    on_lines = vim.schedule_wrap(function ()
      vim.defer_fn(ido.match, 0)
    end),

    on_detach = function ()
      vim.defer_fn(function ()
        if vim.api.nvim_buf_is_valid(ido.buffer.items) then
          vim.api.nvim_buf_delete(ido.buffer.items, {force = true})
        end
      end, 0)
    end
  })

  vim.cmd("startinsert")

  if not vim.keymap then
    ido.bindings = {}
  end

  ido.bind(ido.mappings)
end

ido.bind {
  ["<c-c>"] = ido.exit,
  ["<esc>"] = ido.exit,
  ["<tab>"] = ido.next,
  ["<s-tab>"] = ido.prev,

  ["<cr>"] = ido.accept_item,
  ["<c-j>"] = ido.accept_query,
}

function ido.utils.in_git()
  return os.execute("git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null") == 0
end

function ido.utils.path_short(path, pwd)
  if path == pwd then
    path = "."
  end

  if not vim.endswith(pwd, "/") then
    pwd = pwd.."/"
  end

  if vim.startswith(path, pwd) then
    path = path:sub(#pwd + 1)
  end

  if vim.startswith(path, vim.env.HOME) then
    path = "~"..path:sub(#vim.env.HOME + 1)
  end

  return path
end

function ido.register(name, func)
  ido[name] = func
  table.insert(ido.registers, name)
end

function ido.execute()
  ido.start(ido.registers, function (name)
    if type(ido[name]) == "function" then
      vim.defer_fn(ido[name], 100)
    end
  end, "Execute")
end

ido.register("browse", function ()
  local pwd = vim.loop.cwd()
  local cwd = pwd

  local function list()
    return vim.fn.systemlist("ls -Apv "..vim.fn.shellescape(cwd))
  end

  local function sync()
    ido.title("Browse: "..cwd)
    vim.api.nvim_buf_set_lines(ido.buffer.query, 0, -1, false, {})

    ido.items = list()
    ido.match()
  end

  local function join(a, b)
    local final = a.."/"..b
    if final:sub(1, 2) == "//" then
      final = final:sub(2)
    end
    return final
  end

  ido.start(list(), function (file)
    vim.cmd("edit "..ido.utils.path_short(join(cwd, file), pwd))
  end, "Browse: "..cwd)

  ido.bind {
    ["<a-l>"] = function ()
      local item = ido.get_item()
      if item:sub(-1) == "/" then
        cwd = join(cwd, item:sub(1, -2))
        sync()
      end
    end,

    ["<a-h>"] = function ()
      cwd = cwd:sub(1, cwd:find("/[^/]*$") - 1)
      if cwd == "" then
        cwd = "/"
      end
      sync()
    end,

    ["<a-o>"] = function ()
      ido.exit()
      if pcall(vim.cmd, "cd "..cwd) then
        print("ido: changed working directory to '"..cwd.."'")
      else
        vim.api.nvim_err_writeln("ido: could not change working directory to '"..cwd.."'")
      end
    end
  }
end)

ido.register("buffers", function ()
  local cwd = vim.loop.cwd()
  local buffers = {}
  local current = vim.api.nvim_get_current_buf()

  for _, item in ipairs(vim.fn.getbufinfo({buflisted = true})) do
    if item.bufnr ~= current then
      table.insert(buffers, {ido.utils.path_short(item.name, cwd), item.lastused})
    end
  end

  table.sort(buffers, function (a, b)
    return a[2] > b[2]
  end)

  for i, buffer in ipairs(buffers) do
    buffers[i] = buffer[1]
  end

  current = ido.utils.path_short(vim.api.nvim_buf_get_name(current), cwd)
  if current ~= "" then
    table.insert(buffers, current)
  end

  ido.start(buffers, function (buffer) vim.cmd("buffer "..buffer) end, "Buffers")
end)

ido.register("colorschemes", function ()
  local colors = vim.fn.getcompletion("", "color")
  ido.start(colors, function (color) vim.cmd("colorscheme "..color) end, "Colorschemes")
end)

ido.register("git_files", function ()
  if not ido.utils.in_git() then
    ido.browse()
    return
  end

  ido.start(
    vim.fn.systemlist("git ls-files --cached --others --exclude-standard"),
    function (file) vim.cmd("edit "..file) end, "Git Files")
end)

ido.register("git_grep", function ()
  if not ido.utils.in_git() then
    vim.api.nvim_err_writeln("ido: working directory does not belong to a Git repository")
    return
  end

  local query = vim.fn.input("Git Grep: ")
  if query == "" then
    return
  end

  local matches = vim.fn.systemlist("git grep -inI --untracked "..
    vim.fn.shellescape(query))

  ido.start(matches, function (match)
    match = vim.split(match, ":")
    vim.cmd("edit "..match[1])

    match = tonumber(match[2])

    local col = vim.api.nvim_buf_get_lines(0, match - 1, match, false)[1]
      :find(query)

    vim.api.nvim_win_set_cursor(0, {match, col})
  end, "Git Grep")
end)

ido.register("projects", function (base)
  if base == nil or base == "" then
    base = vim.fn.input("Base: ", "", "file")
  end

  if base == nil or base == "" then
    return
  end

  base = vim.fn.expand(base)
  ido.start(vim.fn.systemlist("ls "..base), function (project)
    local path = base.."/"..project
    if pcall(vim.cmd, "cd "..path) then
      print("ido: changed working directory to '"..path.."'")
    else
      vim.api.nvim_err_writeln("ido: could not change working directory to '"..path.."'")
    end
  end, "Projects")
end)

ido.register("man_pages", function ()
  ido.start(vim.fn.systemlist("man -k . | awk '{print $1 $2}'"), function (page)
    vim.cmd("Man "..page)
  end, "Manpages")
end)

ido.register("helptags", function ()
  local langs = {"en"}
  local langs_map = {en = true}
  local tag_files = {}
  local function add_tag_file(lang, file)
    if langs_map[lang] then
      if tag_files[lang] then
        table.insert(tag_files[lang], file)
      else
        tag_files[lang] = {file}
      end
    end
  end

  local function path_tail(path)
    for i = #path, 1, -1 do
      if path:sub(i, i) == "/" then
        return path:sub(i + 1, -1)
      end
    end
    return path
  end

  local help_files = {}
  local all_files = vim.api.nvim_get_runtime_file("doc/*", true)
  for _, fullpath in ipairs(all_files) do
    local file = path_tail(fullpath)
    if file == "tags" then
      add_tag_file("en", fullpath)
    elseif file:match "^tags%-..$" then
      local lang = file:sub(-2)
      add_tag_file(lang, fullpath)
    else
      help_files[file] = fullpath
    end
  end

  local tags = {}
  local tags_map = {}
  local delimiter = string.char(9)
  for _, lang in ipairs(langs) do
    for _, file in ipairs(tag_files[lang] or {}) do
      local lines = vim.fn.readfile(file)
      for _, line in ipairs(lines) do
        if not line:match "^!_TAG_" then
          local fields = vim.split(line, delimiter, true)
          if #fields == 3 and not tags_map[fields[1]] then
            if fields[1] ~= "help-tags" or fields[2] ~= "tags" then
              table.insert(tags, fields[1])
              tags_map[fields[1]] = true
            end
          end
        end
      end
    end
  end

  ido.start(tags, function (tag) vim.cmd("help "..tag) end, "Helptags")
end)

return ido
