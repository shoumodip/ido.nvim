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

return render
