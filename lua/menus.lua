require "ido"

-- Find files -{{{
function find_files(dirname)
  if dirname == nil then
    if vim.fn.expand('%:p') == '' then
      dirname = fn.eval('$PWD')
    else
      dirname = vim.fn.expand('%:p:h')
    end
  end
  local user_input = ido_completing_read("Find files (" ..
  string.gsub(vim.fn.resolve(dirname), '^' .. os.getenv('HOME'), '~') ..
  "): ", fn.systemlist('ls -a ' .. dirname))

  local possible_dirname = dirname .. '/' .. user_input
  if user_input ~= '' then
    if os.execute('test -d "' .. possible_dirname .. '"') == 0 then
      find_files(possible_dirname)
    else
      api.nvim_command('edit ' .. possible_dirname)
    end
  end
end
-- }}}
