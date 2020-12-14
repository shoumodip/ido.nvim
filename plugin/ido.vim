if exists('g:loaded_ido') | finish | endif " Prevent loading file twice

let s:save_cpo = &cpo " Save user coptions
set cpo&vim           " Reset them to defaults

lua require "menus"
nnoremap <silent> <Leader>. :lua find_files()<CR>

let &cpo = s:save_cpo " And restore after
unlet s:save_cpo

let g:loaded_ido = 1
