local ido = {
    motion = {},
    delete = {},
    options = {},
    internal = {},
    state = {},
}

function ido.setup(config)
    ido.options = vim.tbl_deep_extend("force", ido.options, config or {})
end

function ido.internal.get(field)
    if ido.state.options and ido.state.options[field] then
        return ido.state.options[field]
    else
        return ido.options[field]
    end
end

function ido.internal.set(field, value)
    if ido.state.options and ido.state.options[field] then
        ido.state.options[field] = value
    else
        ido.options[field] = value
    end
end

function ido.internal.key(key)
    if ido.state.options and ido.state.options.mappings and ido.state.options.mappings[key] then
        return ido.state.options.mappings[key]
    else
        return ido.options.mappings[key]
    end
end

function ido.internal.hook(name)
    if ido.state.options and ido.state.options.hooks and ido.state.options.hooks[name] then
        ido.state.options.hooks[name]()
    elseif ido.options.hooks[name] then
        ido.options.hooks[name]()
    end
end

function ido.internal.query()
    return ido.state.query.lhs..ido.state.query.rhs
end

function ido.internal.insert(char)
    ido.state.query.lhs = ido.state.query.lhs..char
    ido.state.modified = true
end

function ido.motion.define(name, action)
    ido.motion[name] = action
    ido.delete[name] = {
        forward = function ()
            if #ido.state.query.rhs > 0 then
                ido.state.modified = true

                local lhs = ido.state.query.lhs
                action.forward()
                ido.state.query.lhs = lhs
            else
                ido.internal.hook("delete_forward_nothing")
            end
        end,

        backward = function ()
            if #ido.state.query.lhs > 0 then
                ido.state.modified = true

                local rhs = ido.state.query.rhs
                action.backward()
                ido.state.query.rhs = rhs
            else
                ido.internal.hook("delete_backward_nothing")
            end
        end
    }
end

ido.motion.define("char", {
    forward = function ()
        if ido.state.query.rhs:len() > 0 then
            ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs:sub(1, 1)
            ido.state.query.rhs = ido.state.query.rhs:sub(2)
        end
    end,

    backward = function ()
        if ido.state.query.lhs:len() > 0 then
            ido.state.query.rhs = ido.state.query.lhs:sub(-1)..ido.state.query.rhs
            ido.state.query.lhs = ido.state.query.lhs:sub(1, -2)
        end
    end
})

ido.motion.define("word", {
    forward = function ()
        if ido.state.query.rhs:len() > 0 then
            local index, final = ido.state.query.rhs:find("%w+")
            if index ~= nil then
                ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs:sub(1, final)
                ido.state.query.rhs = ido.state.query.rhs:sub(final + 1)
            end
        end
    end,

    backward = function ()
        if ido.state.query.lhs:len() > 0 then
            local index, final = ido.state.query.lhs:reverse():find("%w+")
            if index ~= nil then
                ido.state.query.rhs = ido.state.query.lhs:sub(-final)..ido.state.query.rhs
                ido.state.query.lhs = ido.state.query.lhs:sub(1, -final - 1)
            end
        end
    end
})

ido.motion.define("line", {
    forward = function ()
        ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs
        ido.state.query.rhs = ""
    end,

    backward = function ()
        ido.state.query.rhs = ido.state.query.lhs..ido.state.query.rhs
        ido.state.query.lhs = ""
    end
})

local fzy = dofile(debug.getinfo(1).source:sub(2, -12).."deps/fzy-lua-native/lua/native.lua")

function ido.internal.match(query, item)
    if fzy.has_match(query, item, not ido.internal.get("ignorecase")) then
        return fzy.positions(query, item, not ido.internal.get("ignorecase"))
    else
        return {}, -math.huge
    end
end

function ido.internal.filter()
    ido.internal.hook("filter_items")

    ido.state.current = 1
    ido.state.modified = false
    ido.state.results = {}
    local query = ido.internal.query()

    if #query > 0 then
        for _, item in ipairs(ido.state.items) do
            local _, score = ido.internal.match(query, item)

            if score ~= -math.huge then
                table.insert(ido.state.results, {item, score})
            end
        end

        table.sort(ido.state.results, function (lhs, rhs) return lhs[2] > rhs[2] end)
    else
        for _, item in ipairs(ido.state.items) do
            table.insert(ido.state.results, {item, math.huge})
        end
    end
end

function ido.internal.keystring(key, inside)
    if type(key) == "number" then
        if key == 13 then
            return inside and "cr" or "<cr>"
        elseif key == 27 then
            return inside and "esc" or "<esc>"
        elseif key <= 26 then
            assert(not inside)
            return "<c-"..string.char(("a"):byte() + key - 1)..">"
        else
            return string.char(key)
        end
    end

    if key == "€kb" then
        return inside and "bs" or "<bs>"
    elseif key == "€kD" then
        return inside and "del" or "<del>"
    else
        key = key:sub(4)

        if key:len() == 1 then
            key = key:byte()
        end

        assert(not inside)
        return "<a-"..ido.internal.keystring(key, true)..">"
    end
end

function ido.internal.render()
    local capacity = 2 * vim.opt.columns:get()
    local space = capacity
    local output = {}

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

    draw(ido.internal.get("prompt"), "idoPrompt")
    draw(ido.state.query.lhs)
    
    if #ido.state.query.rhs > 0 then
        draw(ido.state.query.rhs:sub(1, 1), "Cursor")
        draw(ido.state.query.rhs:sub(2).." ")
    else
        draw(" ", "Cursor")
    end

    local results = #ido.state.results
    if results > 0 then
        if draw(ido.state.results[ido.state.current][1], "idoSelected") and results > 1 then
            local i = ido.state.current

            while true do
                i = i + 1

                if i > results then
                    i = 1
                end

                if i == ido.state.current then
                    break
                end

                if not draw(" | ", "idoSeparator") then
                    break
                end

                if not draw(ido.state.results[i][1]) then
                    break
                end
            end
        end
    end

    if space > 0 then
        draw(string.rep(" ", space - 1))
    end

    vim.api.nvim_echo(output, false, {})
end

function ido.quit()
    ido.state.active = false
    ido.state.current = nil
end

function ido.done()
    ido.state.active = false

    if #ido.state.results > 0 then
        ido.state.current = ido.state.results[ido.state.current][1]
    elseif ido.internal.get("accept_query") then
        ido.state.current = ido.internal.query()
    else
        ido.state.current = nil
    end
end

function ido.next()
    if ido.state.current < #ido.state.results then
        ido.state.current = ido.state.current + 1
    else
        ido.state.current = 1
    end
end

function ido.prev()
    if ido.state.current > 1 then
        ido.state.current = ido.state.current - 1
    else
        ido.state.current = #ido.state.results
    end
end

function ido.start(items, init)
    ido.state = {
        active = true,
        items = items,
        query = {lhs = "", rhs = ""},
        modified = true,
        options = init
    }

    local cmdheight = vim.o.cmdheight
    vim.o.cmdheight = 2

    vim.opt.guicursor:remove("a:Cursor")
    vim.opt.guicursor:append("a:idoHideCursor")

    ido.internal.hook("event_start")
    while ido.state.active do
        if ido.state.modified then
            ido.internal.filter()
        end

        print(" ")
        vim.cmd("redraw")
        ido.internal.get("render")()

        local ok, key = pcall(vim.fn.getchar)

        if ok then
            local action = ido.internal.key(ido.internal.keystring(key))
            if action then
                action()
            elseif type(key) == "number" and key >= 32 and key <= 126 then
                ido.internal.insert(string.char(key))
            end
        else
            ido.state.active = false
        end
    end
    ido.internal.hook("event_stop")

    vim.opt.guicursor:remove("a:idoHideCursor")
    vim.opt.guicursor:append("a:Cursor")

    vim.o.cmdheight = 1
    print(" ")
    vim.cmd("redraw")

    return ido.state.current
end

ido.setup {
    prompt = ">>> ",

    ignorecase = vim.o.ignorecase,

    render = ido.internal.render,

    mappings = {
        ["<bs>"] = ido.delete.char.backward,
        ["<del>"] = ido.delete.char.forward,
        ["<esc>"] = ido.quit,
        ["<cr>"] = ido.done,

        ["<c-d>"] = ido.delete.char.forward,
        ["<c-k>"] = ido.delete.char.backward,

        ["<c-f>"] = ido.motion.char.forward,
        ["<c-b>"] = ido.motion.char.backward,

        ["<a-f>"] = ido.motion.word.forward,
        ["<a-b>"] = ido.motion.word.backward,

        ["<a-d>"] = ido.delete.word.forward,
        ["<a-k>"] = ido.delete.word.backward,
        ["<a-bs>"] = ido.delete.word.backward,

        ["<c-a>"] = ido.motion.line.backward,
        ["<c-e>"] = ido.motion.line.forward,

        ["<c-n>"] = ido.next,
        ["<c-p>"] = ido.prev
    },

    hooks = {}
}

return ido
