if vim.ui then
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

    local selected = require("ido").start(items, function (option)
      if opts.format_item then
        option = lookup[option]
      end

      if option then
        accept(option)
      end
    end, prompt)
  end
end
