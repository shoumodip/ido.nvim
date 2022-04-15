if exists('g:loaded_ido')
    finish
endif
let g:loaded_ido = 1

highlight idoHideCursor gui=reverse blend=100
highlight! link idoPrompt Question
highlight! link idoSelected Identifier
highlight! link idoSeparator Comment

command! -nargs=1 Ido execute "lua require('ido." . split(<q-args>, '\.')[0] . "')." . split(<q-args>, '\.')[1] . "()"
