vim.ui.select = function (items, opts, accept)
    opts = opts or {}

    local lookup = {}
    if opts.format_item then
        for i, item in ipairs(items) do
            items[i] = opts.format_item(item)
            lookup[items[i]] = item
        end
    end

    local prompt = opts.prompt
    if prompt then
        prompt = prompt.." "
    end

    local selected = require("ido").start(items, {prompt = prompt})
    if not selected then
        return
    end

    if opts.format_item then
        selected = lookup[selected]
    end

    if selected then
        accept(selected)
    end
end

vim.api.nvim_set_hl(0, "idoPrompt", {link = "Question"})
vim.api.nvim_set_hl(0, "idoSelected", {link = "Identifier"})
vim.api.nvim_set_hl(0, "idoSeparator", {link = "Comment"})
vim.api.nvim_set_hl(0, "idoHideCursor", {reverse = true, blend = 100})

vim.cmd[[command! -nargs=1 Ido execute "lua require('ido." . split(<q-args>, '\.')[0] . "')." . split(<q-args>, '\.')[1] . "()"]]
