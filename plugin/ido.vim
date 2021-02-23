if exists("g:loaded_ido")
  finish
endif

highlight! IdoPrompt     guibg=#161616 guifg=#96a6c8

highlight! IdoCursor     guibg=#cc8c3c guifg=#161616
highlight! IdoUXElements guibg=#161616 guifg=#857c7f

highlight! IdoNormal     guibg=#161616 guifg=#ebdbb2
highlight! IdoSelected   guibg=#161616 guifg=#d79921
highlight! IdoSuggestion guibg=#161616 guifg=#cc8c3c gui=bold

highlight! IdoHideCursor gui=reverse blend=100

let g:loaded_ido = 1
