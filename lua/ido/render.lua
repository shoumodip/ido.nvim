local render = {}

render.default = {
    space = 0
}

function render.default.init()
    render.default.space = vim.opt.columns:get()
end

function render.default.text(output, text, highlight)
    if render.default.space == 0 then
        return false
    end

    if text:len() + 1 > render.default.space then
        text = text:sub(1, render.default.space - 1)
    end
    render.default.space = render.default.space - text:len()
    table.insert(output, {text, highlight or "Normal"})

    return true
end

function render.default.done(output)
    render.default.text(output, string.rep(" ", render.default.space - 1))

    print(" ")
    vim.cmd("redraw")

    vim.api.nvim_echo(output, false, {})
    render.default.space = vim.opt.columns:get()
end

function render.default.exit()
    vim.cmd("mode")
end

function render.default.delim(output)
    return render.default.text(output, " | ", "idoSeparator")
end

render.vertical = {
    space = 0,
    prompt = false
}

function render.vertical.init()
    vim.cmd("new")
    vim.api.nvim_buf_set_option(0, "buftype", "nofile")
    vim.api.nvim_win_set_option(0, "statusline", "Ido")

    render.vertical.space = vim.fn.winheight(0)
    render.vertical.prompt = true
end

function render.vertical.text(output, text, highlight)
    if render.vertical.space == 0 then
        return false
    end

    if render.vertical.prompt then
        if highlight == "idoSelected" then
            render.vertical.prompt = false
        end
    end

    if not render.vertical.prompt then
        render.vertical.space = render.vertical.space - 1
    end

    table.insert(output, {text, highlight or "Normal"})
    return true
end

function render.vertical.done(output)
    local actual_output = {""}

    local index = 1
    while index <= #output and output[index][2] ~= "idoSelected" do
        actual_output[1] = actual_output[1]..output[index][1]
        index = index + 1
    end

    while index <= #output do
        table.insert(actual_output, output[index][1])
        index = index + 1
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, actual_output)

    vim.fn.clearmatches()
    vim.fn.matchaddpos("idoPrompt", {{1, 1, output[1][1]:len()}})
    vim.fn.matchaddpos("Cursor", {{1, output[1][1]:len() + output[2][1]:len() + 1, output[3][1]:len()}})

    if #actual_output > 1 then
        vim.fn.matchaddpos("idoSelected", {2})
    end

    vim.cmd("redraw")

    render.vertical.space = vim.fn.winheight(0)
    render.vertical.prompt = true
end

function render.vertical.exit()
    vim.cmd("close")
end

function render.vertical.delim(output)
    return true
end

return render
