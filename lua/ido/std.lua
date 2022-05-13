local ido = require("ido")

local std = {}

function std.browse()
    local cwd = vim.fn.expand("%:p:h")
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

        vim.cmd("edit "..file)
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

    local buffer = ido.start(list, {prompt = "Buffer: "})
    if buffer then
        vim.cmd("buffer "..buffer)
    end
end

function std.filetypes()
    local filetype = ido.start(vim.fn.getcompletion("", "filetype"), {prompt = "Filetypes: "})
    if filetype then
        vim.cmd("setlocal filetype="..filetype)
    end
end

function std.find_files()
    local file = ido.start(vim.split(vim.fn.glob("**"), "\n"), {prompt = "Files: ", accept_query = true})
    if file then
        vim.cmd("edit "..file)
    end
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
        local file = ido.start(vim.fn.systemlist("git ls-files --cached --others --exclude-standard"), {
            prompt = "Git Files: ",
            accept_query = true
        })

        if file then
            vim.cmd("edit "..file)
        end
    end
end

function std.git_diff()
    if std.check_inside_git("std.git_diff") then
        local file = ido.start(vim.fn.systemlist("git diff --name-only"), {prompt = "Git Diff: "})
        if file then
            vim.cmd("edit "..file)
        end
    end
end

function std.git_log()
    if std.check_inside_git("std.git_log") then
        if vim.fn.exists("*FugitiveFind") == 0 then
            vim.api.nvim_err_writeln("std.git_log: tpope/vim-fugitive not installed")
        else
            local commit = ido.start(vim.fn.systemlist("git log --format='%h%d %s %cr'"), {prompt = "Git Log: "})
            if commit then
                commit = commit:gsub(" .*", "")
                vim.cmd("edit "..vim.fn.FugitiveFind(commit))
            end
        end
    end
end

function std.git_status()
    if std.check_inside_git("std.git_status") then
        local file = ido.start(vim.fn.systemlist("git status --short --untracked-files=all"), {prompt = "Git Status: "})

        if file then
            file = file:gsub(" ?[^ ]+ ", "", 1)
            vim.cmd("edit "..file)
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

return std
