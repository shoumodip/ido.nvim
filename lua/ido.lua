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

function ido.internal.get(option)
    if ido.state.options and ido.state.options[option] then
        return ido.state.options[option]
    else
        return ido.options[option]
    end
end

function ido.internal.set(option, value)
    if ido.state.options and ido.state.options[option] then
        ido.state.options[option] = value
    else
        ido.options[option] = value
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
        if #ido.state.query.rhs > 0 then
            ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs:sub(1, 1)
            ido.state.query.rhs = ido.state.query.rhs:sub(2)
        end
    end,

    backward = function ()
        if #ido.state.query.lhs > 0 then
            ido.state.query.rhs = ido.state.query.lhs:sub(-1)..ido.state.query.rhs
            ido.state.query.lhs = ido.state.query.lhs:sub(1, -2)
        end
    end
})

ido.motion.define("word", {
    forward = function ()
        if #ido.state.query.rhs > 0 then
            local index, final = ido.state.query.rhs:find("%w+")
            if index ~= nil then
                ido.state.query.lhs = ido.state.query.lhs..ido.state.query.rhs:sub(1, final)
                ido.state.query.rhs = ido.state.query.rhs:sub(final + 1)
            end
        end
    end,

    backward = function ()
        if #ido.state.query.lhs > 0 then
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
    ido.state.completion = nil
    local query = ido.internal.query()

    if #query > 0 then
        for _, item in ipairs(ido.state.items) do
            local positions, score = ido.internal.match(query, item)

            if score ~= -math.huge then
                local last_match = positions[#positions] + 1

                if not ido.state.completion then
                    ido.state.completion = item:sub(last_match)
                else
                    while #ido.state.completion > 0 and not vim.startswith(item:sub(last_match), ido.state.completion) do
                        ido.state.completion = ido.state.completion:sub(1, -2)
                    end
                end

                table.insert(ido.state.results, {item, score})
            end
        end

        table.sort(ido.state.results, function (lhs, rhs) return lhs[2] > rhs[2] end)
    else
        for _, item in ipairs(ido.state.items) do
            table.insert(ido.state.results, {item, math.huge})
        end
    end

    if not ido.state.completion then
        ido.state.completion = ""
    end
end

function ido.internal.keystring(key, inside)
    if type(key) == "number" then
        if key == 9 then
            return inside and "tab" or "<tab>"
        elseif key == 13 then
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

        if #key == 1 then
            key = key:byte()
        end

        assert(not inside)
        return "<a-"..ido.internal.keystring(key, true)..">"
    end
end

function ido.internal.render()
    local output = {}
    local render = ido.internal.get("render")

    render.text(output, ido.internal.get("prompt"), "idoPrompt")
    render.text(output, ido.state.query.lhs)

    if #ido.state.query.rhs > 0 then
        render.text(output, ido.state.query.rhs:sub(1, 1), "Cursor")
        render.text(output, ido.state.query.rhs:sub(2).." ")
    else
        render.text(output, " ", "Cursor")
    end

    local results = #ido.state.results
    if results > 0 then
        if render.text(output, ido.state.results[ido.state.current][1], "idoSelected") and results > 1 then
            local i = ido.state.current

            while true do
                i = i + 1

                if i > results then
                    i = 1
                end

                if i == ido.state.current then
                    break
                end

                if not render.delim(output) then
                    break
                end

                if not render.text(output, ido.state.results[i][1]) then
                    break
                end
            end
        end
    end

    render.done(output)
    output = {}
end

function ido.stop()
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

function ido.complete()
    ido.state.query.lhs = ido.state.query.lhs..ido.state.completion
end

function ido.start(items, init, state)
    ido.state = vim.tbl_extend("force", {
        active = true,
        items = items,
        query = {lhs = "", rhs = ""},
        modified = true,
        options = init
    }, state or {})

    vim.opt.guicursor:remove("a:Cursor")
    vim.opt.guicursor:append("a:idoHideCursor")

    ido.internal.get("render").init()
    while ido.state.active do
        if ido.state.modified then
            ido.internal.filter()
        end

        ido.internal.render()

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
            ido.state.current = nil
        end
    end
    ido.internal.get("render").exit()

    vim.opt.guicursor:remove("a:idoHideCursor")
    vim.opt.guicursor:append("a:Cursor")

    return ido.state.current
end

ido.setup {
    prompt = ">>> ",

    ignorecase = vim.o.ignorecase,

    render = require("ido.render").default,

    mappings = {
        ["<tab>"] = ido.complete,
        ["<esc>"] = ido.stop,
        ["<cr>"] = ido.done,

        ["<bs>"] = ido.delete.char.backward,
        ["<del>"] = ido.delete.char.forward,

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
