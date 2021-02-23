if exists("g:loaded_ido")
  finish
endif

highlight! IdoPrompt     guifg=#96a6c8

highlight! IdoCursor     guifg=#161616 guibg=#cc8c3c
highlight! IdoUXElements guifg=#857c7f

highlight! IdoNormal     guifg=#ebdbb2
highlight! IdoSelected   guifg=#d79921
highlight! IdoSuggestion guifg=#cc8c3c gui=bold

highlight! IdoHideCursor gui=reverse blend=100

let g:loaded_ido = 1
