local ido = require("ido")

local std = {}

function std.browse()
    local cwd = vim.bo.buftype == "terminal" and vim.fn.getcwd() or vim.fn.expand("%:p:h")
    if cwd ~= "/" then
        cwd = cwd.."/"
    end

    local function list()
        return vim.fn.systemlist("ls -pA '"..cwd:gsub("'", "'\"'\"'").."'")
    end

    local function update()
        if cwd:sub(-1) ~= "/" then
            cwd = cwd.."/"
        end

        ido.state.items = list()
        ido.state.modified = true
        ido.state.options.prompt = "Browse: "..cwd:gsub(vim.env.HOME, "~")
        ido.state.query = {lhs = "", rhs = ""}
    end

    local cmd = "edit"
    local file = ido.start(list(), {
        prompt = "Browse: "..cwd:gsub(vim.env.HOME, "~"),

        accept_query = true,

        mappings = {
            ["/"] = function ()
                if #ido.state.results > 0 then
                    local final = cwd..ido.state.results[ido.state.current][1]

                    if vim.fn.isdirectory(final) == 1 then
                        cwd = final
                        update()
                    end
                end
            end,

            ["<c-v>"] = function ()
                if #ido.state.results > 0 then
                    if vim.fn.isdirectory(cwd..ido.state.results[ido.state.current][1]) == 0 then
                        cmd = "vsplit"
                        ido.done()
                    end
                end
            end,

            ["<c-s>"] = function ()
                if #ido.state.results > 0 then
                    if vim.fn.isdirectory(cwd..ido.state.results[ido.state.current][1]) == 0 then
                        cmd = "split"
                        ido.done()
                    end
                end
            end,

            ["~"] = function ()
                if ido.internal.query() == "" then
                    cwd = vim.env.HOME
                    update()
                else
                    ido.internal.insert("~")
                end
            end
        },

        hooks = {
            ["delete_backward_nothing"] = function ()
                if cwd ~= "/" then
                    cwd = vim.fn.fnamemodify(cwd, ":h:h")
                    update()
                end
            end
        }
    })

    if file then
        if file:sub(-1) == "/" then
            file = file:sub(1, -2)
        end

        file = cwd..file

        cwd = vim.loop.cwd()
        if #file > #cwd and file:sub(1, #cwd) == cwd then
            file = file:sub(#cwd + 2)
        end

        vim.cmd(cmd.." "..file)
    end
end

function std.buffer_sort(list)
    local current = vim.fn.fnamemodify(vim.fn.bufname(), ":p")
    local found_current = false

    for i, name in ipairs(list) do
        if vim.fn.fnamemodify(name, ":p") == current then
            table.remove(list, i)
            current = name
            found_current = true
        end
    end

    table.sort(list, function (a, b)
        return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
    end)

    if found_current then
        table.insert(list, current)
    end
end

function std.buffer()
    local list = vim.fn.getcompletion("", "buffer")
    std.buffer_sort(list)

    local cmd = "buffer"
    local buffer = ido.start(list, {
        prompt = "Buffer: ",
        mappings = {
            ["<c-v>"] = function ()
                if #ido.state.results > 0 then
                    cmd = "vsplit"
                    ido.done()
                end
            end,

            ["<c-s>"] = function ()
                if #ido.state.results > 0 then
                    cmd = "split"
                    ido.done()
                end
            end
        }
    })

    if buffer then
        vim.cmd(cmd.." "..buffer)
    end
end

function std.filetypes()
    local filetype = ido.start(vim.fn.getcompletion("", "filetype"), {prompt = "Filetypes: "})
    if filetype then
        vim.cmd("setlocal filetype="..filetype)
    end
end

function std.find_files_template(prompt, files)
    local cmd = "edit"

    local file = ido.start(files, {
        prompt = prompt,
        accept_query = true,
        mappings = {
            ["<c-v>"] = function ()
                if #ido.state.results > 0 then
                    cmd = "vsplit"
                    ido.done()
                end
            end,

            ["<c-s>"] = function ()
                if #ido.state.results > 0 then
                    cmd = "split"
                    ido.done()
                end
            end
        }
    })

    if file then
        vim.cmd(cmd.." "..file)
    end
end

function std.find_files()
    std.find_files_template("Files: ", vim.split(vim.fn.glob("**"), "\n"))
end

function std.recent_files()
    std.find_files_template("Recent Files: ", vim.v.oldfiles)
end

function std.is_inside_git()
    return os.execute("git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null") == 0
end

function std.check_inside_git(name)
    if std.is_inside_git() then
        return true
    else
        vim.api.nvim_err_writeln(name..": working directory does not belong to a Git repository")
        return false
    end
end

function std.git_files()
    if std.check_inside_git("std.git_files") then
        std.find_files_template("Git Files: ", vim.fn.systemlist("git ls-files --cached --others --exclude-standard"))
    end
end

function std.git_diff()
    if std.check_inside_git("std.git_diff") then
        std.find_files_template("Git Diff: ", vim.fn.systemlist("git diff --name-only"))
    end
end

function std.git_grep()
    if std.check_inside_git("std.git_grep") then
        local file = ido.start({}, {
            filter = function ()
                local query = ido.internal.query()
                if #query > 0 then
                    ido.state.results = vim.tbl_map(function (item)
                        local offset = item:find(":")
                        offset = item:find(":", offset + 1)
                        local positions, score = ido.internal.match(query, item:sub(offset + 1, -1))
                        return {item, score, vim.tbl_map(function (n) return n + offset end, positions)}
                    end, vim.fn.systemlist("git grep -inI --untracked '"..query:gsub("'", "'\"'\"'").."'"))
                    table.sort(ido.state.results, function (lhs, rhs) return lhs[2] > rhs[2] end)
                end
            end,
            prompt = "Git Grep: ",
            accept_query = true,
        })

        if file then
            local location = vim.split(file, ':')
            vim.cmd("edit "..location[1].." | normal! "..location[2].."G")
        end
    end
end

function std.git_log()
    if std.check_inside_git("std.git_log") then
        if vim.fn.exists("*FugitiveFind") == 0 then
            vim.api.nvim_err_writeln("std.git_log: tpope/vim-fugitive not installed")
        else
            local cmd = "edit"
            local commit = ido.start(vim.fn.systemlist("git log --format='%h%d %s %cr'"), {
                prompt = "Git Log: ",
                mappings = {
                    ["<c-v>"] = function ()
                        if #ido.state.results > 0 then
                            cmd = "vsplit"
                            ido.done()
                        end
                    end,

                    ["<c-s>"] = function ()
                        if #ido.state.results > 0 then
                            cmd = "split"
                            ido.done()
                        end
                    end
                }
            })
            if commit then
                commit = commit:gsub(" .*", "")
                vim.cmd(cmd.." "..vim.fn.FugitiveFind(commit))
            end
        end
    end
end

function std.git_status()
    if std.check_inside_git("std.git_status") then
        local cmd = "edit"
        local file = ido.start(vim.fn.systemlist("git status --short --untracked-files=all"), {
            prompt = "Git Status: ",
            mappings = {
                ["<c-v>"] = function ()
                    if #ido.state.results > 0 then
                        cmd = "vsplit"
                        ido.done()
                    end
                end,

                ["<c-s>"] = function ()
                    if #ido.state.results > 0 then
                        cmd = "split"
                        ido.done()
                    end
                end
            }
        })

        if file then
            file = file:gsub(" ?[^ ]+ ", "", 1)
            vim.cmd(cmd.." "..file)
        end
    end
end

function std.git_branch()
    if std.check_inside_git("std.git_branch") then
        local branches = vim.fn.systemlist("git branch")
        local current = nil
        for i = 1, #branches do
            if branches[i]:sub(1, 1) == "*" then
                current = i
            end

            branches[i] = branches[i]:sub(3)
        end
        table.insert(branches, branches[current])
        table.remove(branches, current)

        local branch = ido.start(branches, {prompt = "Git Branch: ", accept_query = true})
        if branch then
            local escaped = branch:gsub("'", "'\"'\"'")
            if os.execute("git checkout '"..escaped.."' 2>/dev/null || git checkout -b '"..escaped.."' 2>/dev/null") ~= 0 then
                vim.api.nvim_err_writeln("git_branch: count not switch to branch '"..branch.."'")
            else
                print("git_branch: switched to '"..branch.."'")
            end
        end
    end
end

function std.manpages()
    local manpage = ido.start(require('man').man_complete("*", "Man *"), {
        prompt = "Manpages: "
    }, {
        query = {
            lhs = vim.fn.expand("<cword>"), rhs = ""
        }
    })
    if manpage then
        vim.cmd("Man "..manpage)
    end
end

-- Stolen from https://github.com/nvim-telescope/telescope.nvim
function std.helptags()
    local langs={"en"}
    local langs_map = {en = true}
    local tag_files = {}
    local function add_tag_file(lang, file)
        if langs_map[lang] then
            if tag_files[lang] then
                table.insert(tag_files[lang], file)
            else
                tag_files[lang] = { file }
            end
        end
    end

    local function path_tail(path)
        for i = #path, 1, -1 do
            if path:sub(i, i) == '/' then
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

    local topic = ido.start(tags, {prompt = "Helptags: "}, {
        query = {
            lhs = vim.fn.expand("<cWORD>"), rhs = ""
        }
    })
    if topic then
        vim.cmd("help "..topic)
    end
end

return std
