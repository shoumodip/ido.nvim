local render = {
    default = {},
    vertical = {}
}

function render.default.init()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer, "bufhidden", "delete")

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    local window = vim.api.nvim_open_win(buffer, true, {
        style = "minimal",
        border = "single",
        relative = "editor",
        width = math.ceil(width * 0.7),
        height = math.ceil(height * 0.8),
        row = math.ceil(height * 0.1 - 2),
        col = math.ceil(width * 0.15)
    })

    vim.api.nvim_win_set_option(window, "winhighlight", "Normal:Normal,FloatBorder:WinSeparator")
    vim.cmd("mode")
end

function render.default.draw(prompt, state)
    local height = vim.api.nvim_win_get_height(0) - 1
    local output = {}

    if state.query.rhs == "" then
        table.insert(output, prompt..state.query.lhs.." ")
    else
        table.insert(output, prompt..state.query.lhs..state.query.rhs)
    end

    local head = 1 + math.floor((state.current - 1) / height) * height
    local tail = math.min(head + height - 1, #state.results)

    for index = head, tail do
        table.insert(output, state.results[index][1])
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
    vim.fn.setpos(".", {0, state.current - head + 2, 1, 0})
    vim.api.nvim_win_set_option(0, "cursorline", #state.results > 0)

    vim.fn.clearmatches()
    vim.fn.matchaddpos("Question", {{1, 1, prompt:len()}})
    vim.fn.matchaddpos("Cursor", {{1, prompt:len() + state.query.lhs:len() + 1, 1}})

    local row = 2
    for index = head, tail do
        local positions = state.results[index][3]

        for _, col in ipairs(positions) do
            vim.fn.matchaddpos("Search", {{row, col, 1}})
        end

        row = row + 1
    end

    vim.cmd("redraw")
end

function render.default.exit()
    vim.cmd("close")
end

function render.vertical.init()
    vim.cmd("new")
    vim.api.nvim_buf_set_option(0, "buftype", "nofile")
    vim.api.nvim_buf_set_option(0, "bufhidden", "delete")
    vim.api.nvim_win_set_option(0, "statusline", "Ido")
end

render.vertical.draw = render.default.draw
render.vertical.exit = render.default.exit

return render
