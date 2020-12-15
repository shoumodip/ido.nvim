require "ido"
local api = vim.api
local fn = vim.fn

-- Find files -{{{
function ido_find_files(dirname)
  dirname = dirname and dirname or vim.loop.cwd()

  local user_input = ido_completing_read("Find files (" ..
  string.gsub(vim.fn.resolve(dirname), '^' .. os.getenv('HOME'), '~') ..
  "): ", fn.systemlist('ls -a ' .. dirname))

  local possible_dirname = dirname .. '/' .. user_input
  if user_input ~= '' then
    if os.execute('test -d "' .. possible_dirname .. '"') == 0 then
      ido_find_files(possible_dirname)
    else
      api.nvim_command('edit ' .. possible_dirname)
    end
  end
end
-- }}}
