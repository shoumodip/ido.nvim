require "ido"
local api = vim.api
local fn = vim.fn

-- Find files -{{{
-- ido_find_files{
--   cwd = "~/.config/nvim",
--   prompt = "Vim:",
-- }
function ido_find_files(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.loop.cwd()
  opts.prompt = opts.prompt or string.format(
    "Find files (%s):",
    string.gsub(
      vim.fn.resolve(opts.cwd), '^' ..
      os.getenv('HOME'), '~'
  ))

  return ido_complete {
    prompt = opts.prompt,
    items = vim.fn.systemlist('ls -a ' .. opts.cwd),
    on_enter = function(s)
      if s ~= '' then
        s = opts.cwd .. '/' .. s
        if vim.fn.isdirectory(vim.fn.expand(s)) == 1 then
          return ido_find_files{ cwd = s, prompt = opts.prompt }
          -- TODO: find alternative way to referesh ido items and prompts.
        else
          return vim.cmd('edit ' .. s)
        end
      end
    end
  }

end
-- }}}
