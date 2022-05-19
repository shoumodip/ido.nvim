local render = {
    default = {},
    vertical = {}
}

function render.default.draw(prompt, state)
    local output = {}
    local space = vim.opt.columns:get()

    local function draw(text, highlight)
        if space == 0 then
            return false
        end

        if text:len() + 1 > space then
            text = text:sub(1, space - 1)
        end
        space = space - text:len()
        table.insert(output, {text, highlight or "Normal"})

        return true
    end

    draw(prompt, "idoPrompt")
    draw(state.query.lhs)

    if #state.query.rhs > 0 then
        draw(state.query.rhs:sub(1, 1), "Cursor")
        draw(state.query.rhs:sub(2).." ")
    else
        draw(" ", "Cursor")
    end

    local results = #state.results
    if results > 0 then
        if draw(state.results[state.current][1], "idoSelected") and results > 1 then
            local i = state.current

            while true do
                i = i + 1

                if i > results then
                    i = 1
                end

                if i == state.current then
                    break
                end

                if not draw(" | ", "idoSeparator") then
                    break
                end

                if not draw(state.results[i][1]) then
                    break
                end
            end
        end
    end

    draw(string.rep(" ", space - 1))

    print(" ")
    vim.cmd("redraw")

    vim.api.nvim_echo(output, false, {})
end

function render.default.exit()
    vim.cmd("mode")
end

function render.vertical.init()
    vim.cmd("new")
    vim.api.nvim_buf_set_option(0, "buftype", "nofile")
    vim.api.nvim_buf_set_option(0, "bufhidden", "delete")
    vim.api.nvim_win_set_option(0, "statusline", "Ido")
end

function render.vertical.draw(prompt, state)
    local height = vim.fn.winheight(0) - 1
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
    vim.fn.matchaddpos("idoPrompt", {{1, 1, prompt:len()}})
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

function render.vertical.exit()
    vim.cmd("close")
end

return render
