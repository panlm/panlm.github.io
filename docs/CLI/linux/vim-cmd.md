---
title: vim-cmd
description: 
created: 2023-04-15 07:16:40.471
last_modified: 2024-03-02
tags:
  - cmd
---

# vim-cmd

## sort
```
%!sort
```

## search
```
/[京津沪渝冀豫云辽黑湘鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]\{1}[A-Z]\{1}[A-Z0-9]\{4}[A-Z0-9挂学警港澳]\{1}/
```

## json
```
%!jq -r .
```

## \\1 \\2
```
:%s/$\([^$]\+\)/"\1": "$\1",/
```
from
```
$context.accountId
```
to
```
"context.accountId": $context.accountId,
```

## my vimrc config
```
"set nocompatible
"source $VIMRUNTIME/vimrc_example.vim
"source $VIMRUNTIME/mswin.vim
"behave mswin

version 6.0
set nocompatible

"if has("gui_running")
"  set imactivatekey=C-space
"  inoremap <ESC> <ESC>:set iminsert=0<CR>
"endif

let s:cpo_save=&cpo
set cpo&vim
let &cpo=s:cpo_save
unlet s:cpo_save
set fileformat=unix
set fileformats=unix,dos
"if &filetype != 'dos'
"  set filetype=dos
"endif
set backspace=2
set history=100
set keymodel=startsel,stopsel
set selection=exclusive
set selectmode=mouse,key
set noswapfile
set showtabline=0
set foldcolumn=3
set nonumber
set nohlsearch
set noai
set modeline
set showmatch
set encoding=default
set syntax=panlm

" encoding settings
set encoding=utf-8
set langmenu=zh_CN.UTF-8
language message zh_CN.UTF-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1

if has("gui_running")
"  set guifontset=-*-vera\ sans\ yuanti\ mono-medium-r-normal-*-16-*-*-*-*-*-iso10646-1
"  set guifont=vera\ sans\ yuanti\ mono\ 12
"  set guifont=WenQuanYi\ Zen\ Hei\ Mono\ 13
"  set guifont=Liberation\ Mono\ 13
"  set guifontwide=LiHei\ Pro\ 11
"  set guifont=Consolas:h11:cANSI
  set guifont=Monaco:h14
  set showtabline=2
  set columns=116
  set lines=30
  set cmdheight=1
  set guioptions-=T "no toolbar
  set nomousehide
  set shiftwidth=3
  colorscheme oceandeep
  syntax on
endif

if has('multi_byte_ime')
  highlight Cursor guibg=Green guifg=NONE
  highlight CursorIM guibg=Purple guifg=NONE
endif

" folding setting
set foldmethod=expr
set foldlevel=0
set foldcolumn=3
"set foldclose=all
"set foldexpr=getline(v:lnum)=~'^==*\ .*\ =\\\\+$'?'>1':'='
set foldexpr=getline(v:lnum)=~'^==*\ .*\ ==*$'?('>'.strlen(matchstr(getline(v:lnum),'^==*'))):'='

" Setting viminfo option
set viminfo='50,<100,s10,:300,/300,h,rA:,rB:,%

set undolevels=100
set nowrapscan

" Auto format paragraph {{{
" (http://vim.sourceforge.net/tips/tip.php?tip_id=440)
" using gqvw to instead
"set textwidth=75
"set formatoptions=aw2tq
"map Q gq
"nmap <silent> ,f :set tw=75<cr>gqap:set tw=0<cr>
"obsoleted: nmap <f9> 70<bar>f r<cr>
"nmap <silent> <s-f9> 77<bar>ha<cr><esc>
"nmap <silent> ,w :set wrap!<bar>set wrap?<cr>
" }}}

" "Always set your working directory to the file you're editing
" autocmd BufEnter * cd %:p:h
" let g:netrw_altv = 1
" " not use explorer.vim instead of netrw
" "let g:explVertical=1
" "let g:explSplitRight=1
" let g:miniBufExplMapWindowNavVim = 1
" let g:miniBufExplMapWindowNavArrows = 1
" let g:miniBufExplMapCTabSwitchBuffs = 1
" let g:miniBufExplModSelTarget = 1

" Statusline Settings
"set statusline=%<%1*===\ %5*%f%1*%(\ ===\ %4*%h%1*%)%(\ ===\ %4*%m%1*%)%(\ ===\ %4*%r%1*%)\ ===%====\ %2*%b(0x%B)%1*\ ===\ %3*%l,%c%V%1*\ ===\ %5*%P%1*\ ===%0* laststatus=2
set statusline=%<===\ %F%m\ %y\ ===%====\ %c%V,%l/%L\ %P\ === laststatus=2

" draw a table/sheet with mouse
:map <F1> :call ToggleSketch()<CR>

" When editing a file, always jump to the last cursor position
" let g:leave_my_cursor_position_alone = 1
  autocmd BufReadPost *
        \ if ! exists("g:leave_my_cursor_position_alone") |
        \     if line("'\"") > 0 && line ("'\"") <= line("$") |
        \         exe "normal g'\"" |
        \     endif |
        \ endif

"Easy menu-style switch between files with a simple map
map	<F5>		:buffers<CR>:e #
"set virtualedit mode
nmap	,c		:set virtualedit=all<cr>
nmap	,nc		:set virtualedit=<cr>
"about windows operation
nmap	<a-n>		:new<cr><c-w

nmap	<a-q>		:close!<cr><c-w

nmap <c-n> :enew!<cr>
nmap <c-t> :tabnew<cr>
"using panlm syntax
"map ,p :set syntax=panlm<cr>
"make header tag
nmap ,1 :s/^[[:blank:]=]*/= /<cr>:s/[[:blank:]=]*$/ =/<cr>
nmap ,2 :s/^[[:blank:]=]*/== /<cr>:s/[[:blank:]=]*$/ ==/<cr>
nmap ,3 :s/^[[:blank:]=]*/=== /<cr>:s/[[:blank:]=]*$/ ===/<cr>
nmap ,4 :s/^[[:blank:]=]*/==== /<cr>:s/[[:blank:]=]*$/ ====/<cr>
nmap ,d :s/^==* \(.*\) ==*$/\1/<cr>
"edit _vimrc file quickly
"for windows
"nmap ,s :source d:\program\vim\_vimrc<cr>
"nmap ,e :e d:\program\vim\_vimrc<cr>
"for mac
nmap ,s :source ~/.gvimrc<cr>
nmap ,e :e ~/.gvimrc<cr>
nmap ,p :e d:\program\vim\vimfiles\syntax\panlm.vim<cr>
nmap ,! A	<<<

"others
map	<F3>		yiw/\c<c-r>"<cr>
map	<Leader>sh	:source $HOME/vimfiles/tools/vimsh/vimsh.vim<CR>
map	<Leader>meta	gg/<PRE><cr>ma/<\/PRE><cr>"zd'a:%d<cr>"zp:%s/\_$\_s//<cr>:%s/<a [^>]\+>//g<cr>:%s/<\/a>//g<cr>:%s/<PRE>//<cr>A&amp;&lt;&gt;&quot;<esc>:%s/<P>/\r/g<cr>:%s/&amp;/\&/g<cr>:%s/&lt;/</g<cr>:%s/&gt;/>/g<cr>:%s/&quot;/"/g<cr>gg/<\/PRE><cr>i<cr><esc>dGgg
"map     <Leader>Note    :%s#\(Note \+\)\([[:digit:]]\+\.[[:digit:]]\+\)#\1|\2|#g<cr>
nmap	,viki		:VikiMinorMode<cr>
nmap	<leader>#	:'a,'b!	nl -ba<cr>
map	,nf		:s/	\?=\+ \?//g<cr>

nmap	<silent><leader>q	:qall!<cr>

" Add ---/=== Automatic
nmap ,- Yp^v$r-
nmap ,= Yp^v$r=

" Highlight Current Line {{{
" (http://vim.sourceforge.net/tips/tip.php?tip_id=263)
" (http://vim.sourceforge.net/tips/tip.php?tip_id=769)
" highlight CurrentLine guibg=#4b4b4b guifg=white ctermbg=darkgrey ctermfg=white
" "au! Cursorhold * exe 'match CurrentLine /\%' . line('.') . 'l.*/'
" au! Cursorhold * exe 'match CurrentLine /.*\%#.*/'
" set ut=10
" nmap <silent> <f9> :au! Cursorhold<cr>:match none<cr>
" nmap <silent> <s-f9> :au! Cursorhold * exe 'match CurrentLine /.*\%#.*/'<cr>
" }}}
" nmap keys {{{
nmap <silent> <f7> :set foldcolumn=3<CR>
nmap <silent> <f8> :set foldcolumn=0<CR>
nmap <silent> <f9> :set number!<bar>set number?<CR>
nmap <silent> <f11> :set hlsearch!<bar>set hlsearch?<CR>
" }}}
" auto insert date and time {{{
iab Pdate <C-R>=strftime("%d %b %Y, %A")<CR>
iab Ptime <C-R>=strftime("%H:%M:%S")<CR>
" }}}
" Display time about cmd running {{{
"command -complete=command -nargs=+ Time :let ct=strftime("%s") | exec <q-args> |let t=strftime("%s")| :echohl MoreMsg |let min=(t - ct)/60 | let sec=(t - ct)%60 |let min = min < 10 ? "0".min : min | let sec= sec<10 ? "0".sec : sec | echo min.":".sec | echohl None
" }}}
" easy pasting to windows apps {{{
" Tip#21
" set clipboard=unnamed
" }}}

" disable set textwidth auto in /etc/vim/vimrc
let g:leave_my_textwidth_alone = 1

" vim -b : edit binary using xxd-format!
augroup Binary
  au!
  au BufReadPre  *.bin let &bin=1
  au BufReadPost *.bin if &bin | %!xxd
  au BufReadPost *.bin set ft=xxd | endif
  au BufWritePre *.bin if &bin | %!xxd -r
  au BufWritePre *.bin endif
  au BufWritePost *.bin if &bin | %!xxd
  au BufWritePost *.bin set nomod | endif
augroup END

let g:XkbSwitchEnabled = 1
let g:XkbSwitchLib = '~/.vim/ISS-mac/input-source-switcher/build/libInputSourceSwitcher.dylib' 

" vim:foldmethod=marker:foldenable:foldlevel=0:fileformat=unix

```

