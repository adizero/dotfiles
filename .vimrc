if &compatible | set nocompatible | endif " Avoid side effects if `nocp` already set
scriptencoding utf-8

"Xxx: this needs .term_detect script support in shell
let s:term_program=$TERM_PROGRAM
let s:term_version=$TERM_VERSION
if s:term_version ==# ''
    let s:term_version = 0
endif

let s:in_screen = $STY !=# ''
let s:in_tmux = $TMUX !=# ''

if has('nvim')
    " It is not possible to control/override behavior of nvim by setting &term or &t_ sequences
    " So the only way how to do it is by setting the TERM variable BEFORE starting nvim
    " e.g. `TERM=xterm-256color nvim` or `TERM=screen-256-color nvim` (when running in GNU screen)
    " Check terminfo capabilities with `infocmp` tool
    if &t_Co < 256
        echohl Warning
        echomsg 'Only ' . &t_Co . ' colors are defined in the terminfo of ' .  $TERM
                    \. ' (try setting TERM before running nvim)'
        echohl None
    endif
endif

if s:term_program ==# 'lxterminal' || s:term_program ==# 'gnome-terminal' ||
            \ s:term_program ==# 'xterm' || s:term_program ==# 'Konsole' ||
            \ s:term_program ==# 'PuTTY' || s:term_program ==# 'Cygwin'
    let &term = 'xterm'
elseif s:term_program ==# 'rxvt' || s:term_program ==# 'urxvt'
    let &term = 'rxvt'
elseif s:term_program ==# 'old-gnome-terminal'
    let &term = 'xterm'
    "Note: workaround for bracketed paste mode in Vim 8.0.569 (see discussion https://github.com/vim/vim/issues/1671)
    let &t_BE=''
else
    "Todo: this is a hack for screen-bce/screen.rxvt to behave as xterm/rxvt in Vim
    if &term ==# 'screen-bce' || &term ==# 'screen'
            if s:in_screen == 0
            "ssh to devpc from inside of a screen (let's fake STY)
                let s:in_screen = 1
            let $STY = '0.dev'
        endif
        let &term = 'xterm'
    elseif &term ==# 'screen.rxvt'
        let &term = 'rxvt'
    elseif &term =~# 'rxvt'  "for urxvt and 256 color variants
        let &term = 'rxvt'
    endif
endif

function! s:ScreenEscape(line)
    if s:in_screen
        " Screen has an escape hatch for talking to the real terminal.  Use it.
        let l:escaped = a:line
        return "\eP" . l:escaped . "\e\\"
    else
        return a:line
    endif
endfunction

function! s:TmuxEscape(line)
    if s:in_tmux
        " Tmux has an escape hatch for talking to the real terminal.  Use it.
        let l:escaped = substitute(a:line, "\\e", "\e\e", 'g')
        return "\ePtmux;" . l:escaped . "\e\\"
    else
        return a:line
    endif
endfunction

function! s:MultiplexerEscape(line)
    if s:in_screen
        return s:ScreenEscape(a:line)
    elseif s:in_tmux
        return s:TmuxEscape(a:line)
    else
        return a:line
    endif
endfunction

if has('win64') || has('win32') || has('win16')
    let g:OS_name='windows'

    let g:OS_dir_separator = '\'
    let g:OS_cat_command = 'type'
    let g:OS_mkdir_command = 'mkdir'
    "TODO: change to cygwin later
    let g:OS_ctags_command = 'c:\Apps\ctags57\ctags.exe'
    let g:OS_system_includes_dir = 'c:\Apps\Dev-Cpp\include'

    let g:OS_vimrc = '_vimrc'

    "windows vista uses $HOME\.vim path, xp uses $HOME\vimfiles path
    "so in xp we change it to $HOME\.vim and $HOME\.vim\after
    "but only the first and last component
    let &runtimepath=substitute(&runtimepath, '\(^[^,]*\)vimfiles', '\1.vim', '') "replace first occurrence
    let &runtimepath=substitute(&runtimepath, '\(,[^,]*\)vimfiles\([^,]*\)$', '\1.vim\2', '') "replace last occurrence

    "behave mswin
    "source $VIMRUNTIME/mswin.vim

    "let $VIMRUNTIME=fnamemodify($_, ":p")
    language mes en

    " replace all directory separators in runtimepath to OS specific
    let &runtimepath=substitute(&runtimepath, '[\/]', g:OS_dir_separator, 'g')

else
    "if SHELL env variable is set incorrectly and VIM cannot start shell, then
    "  uncomment following line, that overrides SHELL env variable
    "set shell=/bin/sh

    " let g:OS_name=system('uname -s') "system call is slow (~6ms)
    let g:OS_name='linux'  "changed to linux (not needed to be specific, any string other than windows is enough)

    let g:OS_dir_separator = '/'
    let g:OS_cat_command = 'cat'
    let g:OS_mkdir_command = 'mkdir -p'
    let g:OS_ctags_command = 'ctags'
    let g:OS_system_includes_dir = '/usr/include,/usr/local/include'

    let g:OS_vimrc = '.vimrc'

    "
    " It's possible that $VIMRUNTIME does not exist.
    " Let's see if there is a directory vimshare below where we were started
    "
    if isdirectory($VIMRUNTIME) == 0
        "
        " What was the name that we were called as?
        "
        let g:vimshare=substitute(fnamemodify($_, ':p'), '^\(.*[/]\).*$', '\1', '') . 'vimshare'
        if isdirectory(g:vimshare) == 1
            let $VIMRUNTIME=g:vimshare . '/vim' . substitute(v:version, '50', '5', '')
            let &helpfile=g:vimshare . '/vim' . substitute(v:version, '50', '5', '') . '/doc/help.txt'
        endif
    endif
endif

if !has('gui_running')
    if g:OS_name !=# 'windows'
        "set t_Cc=1
        "set t_pa=32767

        if &term =~# 'xterm'
            "general termcap options

            "must go before first shell execute command (e.g. execute !ls) from .vimrc
            "sets alternate screen mode
            let &t_ti="\e[?1049h"

            let &t_ts="\e]0;"
            let &t_fs="\007"

            "override terminfo setting to enable 256 colors
            let &t_Co=256
            "let &t_AB="'\e[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m'"
            "let &t_AF="'\e[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m'"
            let &t_AB="\e[4%p1%dm"
            let &t_AF="\e[3%p1%dm"
            let &t_mb="\e[5m"
            let &t_nd="\e[C"
            let &t_op="\e[39;49m"
            let &t_se="\e[27m"
            let &t_te="\e[?1049l"
            let &t_vi="\e[?25l"
            let &t_vs="\e[?12;25h"
            let &t_vb="\e[?5h$<100/>\e[?5l"
            let &t_ve="\e[?12l\e[?25h"
            let &t_ti="\e[?1049h"

            "not necessary, as t_AB,t_AF are used instead
            let &t_Sb="\e[4%?%p1%{1}%=%t4%e%p1%{3}%=%t6%e%p1%{4}%=%t1%e%p1%{6}%=%t3%e%p1%d%;m"
            let &t_Sf="\e[3%?%p1%{1}%=%t4%e%p1%{3}%=%t6%e%p1%{4}%=%t1%e%p1%{6}%=%t3%e%p1%d%;m"

            "see vim help -> :help xterm-function-keys

            set timeout timeoutlen=1000 ttimeoutlen=100

            "terminal detection (based on ^[[>c or in better form "\e[>c"), in screen surround query
            " string with \eP...\e\\ (as always, when we want to talk to terminal underneath screen)
            " the terminal's response is already stored in v:termresponse in Vim
            "
            "^[ is code for escape key (written as two character to not have
            " special keys directly in this .vimrc file)

            "Screen          "old versions???"                   (nothing)
            "Xterm           Xterm(278)                          ^[[>0;278;0c
            "Xterm           Xterm(317)                          ^[[>41;317;0c
            "Lxterminal      lxterminal (0.1.11-4ubuntu3)        ^[[>1;2802;0c
            "Cygwin                                              ^[[>77;10103;0c
            "PuTTY           0.62                                ^[[>0;136;0c
            "Screen          4.00.03 (FAU)                       ^[[>83;40003;0c
            "Screen          4.01.00devel (GNU) 2-May-06         ^[[>83;40100;0c
            "Gnome-terminal  GNOME Terminal 3.6.2                ^[[>1;3409;0c
            "Konsole         2.13.2                              ^[[>0;115;0c

            "see vim help v:termresponse
            "callback is called after response to t_RV reception -> TermResponse autocommand event
            "only then is can be used for terminal identification
            "echomsg "testing..." . v:termresponse
            "
            "for PuTTY answerback may be probably also used (based on ^E)
            "  query terminal via: echo -n -e "^E"
            "  PuTTY usually shows PuTTY as a result
            " beware ^E is really one keycode entered by typing CTRL+V + CTRL+E in terminal


            "TODO: implement somehow :-)

            "old xterm/lxterminal F1-F4 (used only for no mod case - e.g. ^[OP, ...)
            execute "set <F1>=\eO;*P"
            execute "set <F2>=\eO;*Q"
            execute "set <F3>=\eO;*R"
            execute "set <F4>=\eO;*S"
            execute "set <Home>=\eO;*H"
            execute "set <End>=\eO;*F"

            "konsole (universal case covers also the above for no mod case)
            execute "set <F1>=\eO*P"
            execute "set <F2>=\eO*Q"
            execute "set <F3>=\eO*R"
            execute "set <F4>=\eO*S"

            "new xterm (wildcard used to handle all alt,control,shift combinations)
            execute "set <xF1>=\e[1;*P"
            execute "set <xF2>=\e[1;*Q"
            execute "set <xF3>=\e[1;*R"
            execute "set <xF4>=\e[1;*S"
            execute "set <xHome>=\e[1;*H"
            execute "set <xEnd>=\e[1;*F"

            if v:version >= 700
                execute "set <zHome>=\e[;*H"
                execute "set <zEnd>=\e[;*F"
            endif

            execute "set <F17>=\eOE"

            "Todo: specify correct version for old/new xterm bindings (for now 278 - Ubuntu 13.04 timeframe is the limit)
            if s:term_program ==# 'gnome-terminal' && s:term_version < 5200 ||
                        \ s:term_program ==# 'xterm' && (s:term_version < 278 && s:term_version != 95) ||
                        \ s:term_program ==# 'lxterminal' && s:term_version < 5200
                "old xterm/lxterminal/gnome terminal (e.g. lxterminal in Lubuntu 13.04)
                execute "set <xF1>=\eO1;*P"
                execute "set <xF2>=\eO1;*Q"
                execute "set <xF3>=\eO1;*R"
                execute "set <xF4>=\eO1;*S"

                execute "set <F17>=\e[E"
            endif

            "Todo: is this necessary, or does Vim implicitely do this
            map <xF1> <F1>
            map! <xF1> <F1>
            map <xF2> <F2>
            map! <xF2> <F2>
            map <xF3> <F3>
            map! <xF3> <F3>
            map <xF4> <F4>
            map! <xF4> <F4>
            map <xHome> <Home>
            map! <xHome> <Home>
            map <xEnd> <End>
            map! <xEnd> <End>
            map <zHome> <Home>
            map! <zHome> <Home>
            map <zEnd> <End>
            map! <zEnd> <End>

            "del is set without modifiers support (by default in Vim) => let's change that
            execute "set <Del>=\e[3;*~"

            "cleanup of Vim's internal duplicate bindings
            execute 'set <S-Home>='
            execute 'set <S-Left>='
            execute 'set <S-Right>='
            execute 'set <S-End>='

            "newer xterm can do also right winmenu key (has no setting in Vim,
            " however something nonexistant on typical keyboard can be used - F13 for example)
            execute "set <F13>=\e[29;*~"

            "fake key mappings to enable keypad key 5 (Clear) with all modifiers as <F19>
            execute "set <F18>=\eO*u"
            execute "set <F19>=\e[1;*E"

            map <F17> <F19>
            map! <F17> <F19>
            map <S-F18> <S-F19>
            map! <S-F18> <S-F19>
            map <C-S-F18> <C-S-F19>
            map! <C-S-F18> <C-S-F19>
            map <M-S-F18> <M-S-F19>
            map! <M-S-F18> <M-S-F19>
            map <M-C-S-F18> <M-C-S-F19>
            map! <M-C-S-F18> <M-C-S-F19>

        elseif &term =~# 'rxvt'
            set t_Co=256 "override terminfo setting to enable 256 colors
            "rxvt (basic Fn are well covered in default Vim mappings)
            " first two are fixed in rxvt - S-F1 == F11 and S-F2 == F12
            execute "set <S-F3>=\e[25;*~"
            execute "set <S-F4>=\e[26;*~"
            execute "set <S-F5>=\e[28;*~"
            execute "set <S-F6>=\e[29;*~"
            execute "set <S-F7>=\e[31;*~"
            execute "set <S-F8>=\e[32;*~"
            execute "set <S-F9>=\e[33;*~"
            execute "set <S-F10>=\e[34;*~"
            execute "set <S-F11>=\e[23;*$"
            execute "set <S-F12>=\e[24;*$"
            "right windows menu key is equal to S-F6 (but not shift version)
            execute "set <S-F13>=\e[29;*$"

            execute "set <F19>=\eOu"

            execute "set <kHome>=\eOw"
            execute "set <kEnd>=\eOq"

            execute "set <kInsert>=\eOp"

            execute "set <xLeft>=\eOt"
            execute "set <xUp>=\eOx"
            execute "set <xRight>=\eOv"
            execute "set <xDown>=\eOr"

            execute "set <S-Insert>=\e[2$"
            execute "set <S-Del>=\e[3$"
            execute "set <S-Home>=\e[7$"
            execute "set <S-End>=\e[8$"
            "execute "set <S-PageUp>=\e[5$"
            "execute "set <S-PageDown>=\e[6$"
            "execute "set <C-Insert>=\e[2^"
            "execute "set <C-Del>=\e[3^"
            execute "set <C-Home>=\e[7^"
            execute "set <C-End>=\e[8^"
            "execute "set <C-PageUp>=\e[5^"
            "execute "set <C-PageDown>=\e[6^"
            execute "set <S-Up>=\e[a"
            execute "set <S-Down>=\e[b"
            execute "set <S-Left>=\e[d"
            execute "set <S-Right>=\e[c"
            "execute "set <C-Up>=\eOa"
            "execute "set <C-Down>=\eOb"
            execute "set <C-Left>=\eOd"
            execute "set <C-Right>=\eOc"
            "execute "set <A-Up>=\e\e[A"
            "execute "set <A-Down>=\e\e[B"
            "execute "set <A-Left>=\e\e[D"
            "execute "set <A-Right>=\e\e[C"
        endif

        "common mappings
        "enabling ctrl+space mapping (otherwise C-Space does nothing)
        map <C-@> <C-Space>
        map! <C-@> <C-Space>

        "ctrl+backspace mapping (otherwise C-BS does nothing)
        map <C-H> <C-BS>
        map! <C-H> <C-BS>

        "supported formating options for terminal are:
        " *bold* *underline* *undercurl*
        " *reverse*/*inverse* *italic* *standout*

        "bold should work by default (see your terminal emulator setting for picking drawing bold as a color/bold as a font or both)
        "works seamlessly from inside screen
        "let &t_md = "\e[1m"
        "let &t_me = "\e[m"

        "underline should work by default
        "works seamlessly from inside screen
        "let &t_us = "\e[4m"
        "let &t_ue = "\e[m"

        "strikethrough (needs terminal support - KiTTY/PuTTY terminals cannot do strikethrough):
        if v:version > 800 || (v:version == 800 && has('patch1038'))
            if s:in_screen || &t_Ts ==# ''
                let &t_Ts = s:ScreenEscape("\e[9m")
                let &t_Te = s:ScreenEscape("\e[29m")
            endif
        endif

        "reverse/inverse should work by default
        "works seamlessly from inside screen
        "let &t_mr = "\e[7m"

        "italic (italics is already enabled in wombat256 colorscheme) needs escaping from within screen
        " Vim will use &t_mr (reverse/inverse) or even &t_md (bold, if reverse is null) if sitm is not defined in the
        " terminfo (searched based on &term variable), check using `infocmp | grep sitm`
        if s:in_screen || &t_ZH ==# '' || &t_ZH ==# &t_mr || &t_ZH ==# &t_md
            let &t_ZH = s:ScreenEscape("\e[3m")
            let &t_ZR = s:ScreenEscape("\e[23m")
        endif

        "standout should work by default
        "works seamlessly from inside screen
        "let &t_so = "\e[7m"
        "let &t_se = "\e[27m"

        """ delete wait time after ESC key is pushed in insert mode
        ""let &t_SI .= "\e[?7727h"
        ""let &t_EI .= "\e[?7727l"
        ""inoremap <special> <Esc>O[ <Esc>

        "Todo: check somehow, whether terminal is capable of cursor shape changes
        "" changing cursor shape (works in xterm and from screen inside of xterm)
        "if $STY != ''
        "    let &t_SI .= "\eP\e[5 q\e\\"
        "    let &t_EI .= "\eP\e[2 q\e\\"
        "else
        "    let &t_SI .= "\e[5 q"
        "    let &t_EI .= "\e[2 q"
        "endif
        "
        "Todo: cursor colors
        "silent !echo -ne "\033]12;red\007"
        "silent !echo -ne "\033]12;gray\007"

        " Undercurl support (this does not really have terminfo spec so it cannot be learned based on &term)
        " Supported in gnome-terminal/VTE derivatives (since VTE 52.00) and kitty (GPU terminal)
        if v:version > 704 || (v:version == 704 && has('patch911'))
            if s:term_program ==# 'gnome-terminal' && s:term_version >= 5200
                let &t_Cs = s:ScreenEscape("\e[4:3m")
                let &t_Ce = s:ScreenEscape("\e[4:0m")
                set timeout timeoutlen=1000 ttimeoutlen=100
            endif
        endif

        if has('termguicolors')
            " 24-bit color support
            " TODO(akocis): check older terminals and disable where needed
            " set termguicolors
        endif
        if &t_ZH !=# ''
            " some colorschemes look at this environment variable to decide whether to use italics or not
            let $TERM_ITALICS='true'
            let g:nord_italic_comments=1
        endif

    endif
endif

let g:color_scheme = ''
if has('gui_running')
    if g:OS_name ==# 'windows'
        "colorscheme zenburn
        let g:molokai_original = 1
        let g:color_scheme = 'molokai'
        let g:airline_theme = 'molokai'
    else
        "colorscheme desert
        if &t_Co == 256
            let g:color_scheme = 'wombat256mod'
        else
            let g:color_scheme = 'wombat'
        endif
        let g:airline_theme = 'wombat'
    endif
else
    "no GUI - console mode
    if g:OS_name ==# 'windows'
        "8-color terminal in windows only, zellner looks OK
        let g:color_scheme = 'zellner'
        let g:airline_theme = 'dark'
    else
        if &t_Co == 256
            let g:color_scheme = 'wombat256mod'
        else
            let g:color_scheme = 'wombat'
        endif
        let g:airline_theme = 'wombat'
    endif
endif
set background=dark
"hi clear

filetype plugin indent on

"Todo: enable Eclim (by uncomenting following packadd and not defining disabled variable)
let g:EclimDisabled = 'defined'
"packadd! vim-eclim

if v:version < 704 || (v:version == 704 && !has('patch1578'))
    let g:loaded_youcompleteme = 1 "too old Vim => disable YouCompleteMe
    let g:loaded_numbers = 1
endif

if has('python3')
    let g:ycm_server_python_interpreter = 'python3.6'
else
    let g:ycm_server_python_interpreter = $HOME . '/toolchains/python2712/bin/python'
endif

" Use LSP clients (ALE and LanguageServer-neovim)
let g:use_lsp = 1

" Choose between clangd language server and the older libclang for C++ semantic parsing
" (requires libclang and/or clangd to be compiled into ycm)
let g:ycm_use_clangd = 1
" Let clangd fully control code completion (if set to 0)
let g:ycm_clangd_uses_ycmd_caching = 0
" " Use installed clangd, not YCM-bundled clangd which doesn't get updates.
" let g:ycm_clangd_binary_path = exepath("clangd")
let g:ycm_clangd_binary_path = $HOME . '/toolchains/llvm/bin/clangd'
" Extra args passed to clangd
" let g:ycm_clangd_args = []

let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
"Do not ask when starting vim
let g:ycm_confirm_extra_conf = 0

function! g:YCM_tagfiles()
    " full tags are too big for YCM
    if $CSCOPE_FILES_DIR !=# ''
        return [$CSCOPE_FILES_DIR . '/ycm.tags']
    else
        let s:fallback_ycm_tags = $HOME . '/tmp/ycm.tags'
        if filereadable(s:fallback_ycm_tags)
            return [s:fallback_ycm_tags]
        else
            return []
        endif
    endif
endfunction
let g:ycm_collect_identifiers_from_tags_files = 1

let g:ycm_add_preview_to_completeopt = 0
let g:ycm_key_invoke_completion = '<C-Space>'
let g:ycm_key_detailed_diagnostics = '<Leader><Leader>?'
let g:ycm_cache_omnifunc = 1  "takes simply too much memory in big projects (1GB of sources)

let g:ycm_always_populate_location_list = 1

let g:ycm_disable_for_files_larger_than_kb = 5000

if v:version >= 704
    let g:ycm_key_list_select_completion = ['<Down>']
    let g:ycm_key_list_previous_completion = ['<Up>']
    let g:ycm_filetype_blacklist = {
            \ 'tagbar' : 1,
            \ 'qf' : 1,
            \ 'notes' : 1,
            \ 'markdown' : 1,
            \ 'unite' : 1,
            \ 'text' : 1,
            \ 'vimwiki' : 1,
            \ 'pandoc' : 1,
            \ 'infolog' : 1,
            \ 'cfg' : 1,
            \ 'mail' : 1,
            \ 'tags' : 1,
            \}

    " disable semantic completion for these types
    " (to prevent YCM writting python exception to its errlog file)
    let g:ycm_filetype_specific_completion_to_disable = {
            \ 'gitcommit': 1,
            \ 'vim' : 1,
            \}
endif

function! g:VimWarningMsg(text)
    echohl WarningMsg
    echomsg a:text
    echohl None
endfunction

function! g:WinVarExists(winnr, variable_name)
    try
        let l:value =  getwinvar(a:winnr, a:variable_name)
        if type(l:value) != type('')
            return 1
        endif
        if l:value !=# ''
            return 1
        endif
    catch
    endtry
    return 0
endfunction

function! g:BalloonFormatTextLines(lines) abort
    if type(a:lines) !=# type([])
        let input_lines = [a:lines]
    else
        let input_lines = a:lines
    endif
    " split lines with embedded \n characters
    let l:lines = []
    for l:line in l:input_lines
        let l:split_lines = split(l:line, '\n')
        for l:split_line in l:split_lines
            call add(l:lines, l:split_line)
        endfor
    endfor
    return l:lines
endfunction

function! g:BalloonYcmHoverExpr() abort
    let l:cmds = youcompleteme#GetDefinedSubcommands()
    if index( l:cmds, 'GetHover' ) >= 0
        let l:ycm_hover = {
                    \ 'command': 'GetHover',
                    \ 'syntax': 'markdown',
                    \ }
    elseif index( l:cmds, 'GetDoc' ) >= 0
        let l:ycm_hover = {
                    \ 'command': 'GetDoc',
                    \ 'syntax': '',
                    \ }
    elseif index( l:cmds, 'GetType' ) >= 0
        let l:ycm_hover = {
                    \ 'command': 'GetType',
                    \ 'syntax': &syntax,
                    \ }
    else
        return ['']
    endif

    " Todo: consider async
    " call youcompleteme#GetCommandResponseAsync(
    "       \ function( 's:ShowHoverResult' ),
    "       \ 'GetType' )
    " try
        let l:hover_text = youcompleteme#GetCommandResponse(l:ycm_hover.command)
        return g:BalloonFormatTextLines(l:hover_text)
    " catch
    "     return ''
    " endtry
endfunction

function! g:BalloonCocHoverExpr() abort
    if !CocHasProvider('hover')
        return ['']
    endif
    let l:hover_text = CocAction('getHover')
    return g:BalloonFormatTextLines(l:hover_text)
endfunction

let s:balloon_text = []
let s:balloon_popup_winid = 0
let s:balloon_winid = 0
function! g:BalloonHoverExpr() abort
    " for inspiration look at: ale#balloon#MessageForPos, (v:beval_bufnr, v:beval_lnum, v:beval_col)

    let l:hover = ''
    " use COC hover if available
    if exists('*CocAction')
        let l:hover = 'coc'
    endif

    if l:hover ==# ''
        " support my custom lazy loading of YCM
        if !exists('*youcompleteme#GetDefinedSubcommands') && exists(':YcmCompleter')
            execute ':YcmCompleter LoadYouCompleteMe'
        endif

        if !exists('*youcompleteme#GetDefinedSubcommands')
            return ''
        endif
        let l:hover = 'ycm'
    endif

    " no hover command available
    if l:hover ==# ''
        return ''
    endif

    let l:mouse_pos = [v:beval_bufnr, v:beval_lnum, v:beval_col]
    let l:mouse_winnr = v:beval_winnr + 1  " why is the v:beval_winnr 0-based ?
    let l:mouse_winid = win_getid(l:mouse_winnr)
    let l:mouse_bufnr = winbufnr(l:mouse_winnr)
    let l:orig_pos = getpos('.')
    let l:orig_winnr = winnr()
    let l:orig_winid = win_getid(l:orig_winnr)

    if l:mouse_winnr != l:orig_winnr && !g:WinVarExists(l:mouse_winnr, 'mouse_scrolloff')
        " store existing scroll offset
        let l:mouse_scrolloff = getwinvar(l:mouse_winnr, '&l:scrolloff')
        call setwinvar(l:mouse_winnr, 'mouse_scrolloff', l:mouse_scrolloff)

        " force scroll offset to be 0 to prevent viewport jumps on mouse hover
        call setwinvar(l:mouse_winnr, '&scrolloff', 0)

        augroup reset_scrolloff
            execute "autocmd! CursorMoved <buffer=" . l:mouse_bufnr . ">"
            execute "autocmd CursorMoved <buffer=" . l:mouse_bufnr . ">"
                        \ " | if exists('w:mouse_scrolloff')"
                        \ " | let &l:scrolloff = w:mouse_scrolloff"
                        \ " | unlet w:mouse_scrolloff"
                        \ " | endif"
                        \ " | autocmd! reset_scrolloff CursorMoved <buffer=" . l:mouse_bufnr . ">"
        augroup END
    endif

    if !win_gotoid(l:mouse_winid)
        call g:VimWarningMsg('Unable to set cursor position to ' . l:mouse_pos . ' (winid: ' . l:mouse_winid . ')')
        return ''
    endif
    let l:result = setpos('.', l:mouse_pos)
    if l:result != 0
        call g:VimWarningMsg('Unable to set cursor position to ' . l:mouse_pos . ' (winid: ' . l:mouse_winid . ')')
        if !win_gotoid(l:orig_winid)
            call g:VimWarningMsg('Unable to revert back to original winid ' . l:orig_winid)
        endif
        return ''
    endif

    try
        " let l:currentoff = &l:scrolloff
        " let l:currentpos = getpos('.')
        " echomsg 'CUR ' . string(l:currentpos) . ' WIN ' . string(v:beval_winnr) . ' SO ' . l:currentoff
        if l:hover ==# 'coc'
            let s:balloon_text = g:BalloonCocHoverExpr()
        elseif l:hover ==# 'ycm'
            let s:balloon_text = g:BalloonYcmHoverExpr()
        endif

        if v:version > 801 || (v:version == 801 && has('patch1645'))
            if s:balloon_popup_winid && popup_getpos(s:balloon_popup_winid) != {}
                " previous popup window still shows
                if  v:beval_text == join(s:balloon_text, '\n')
                    " Still the same text, keep the existing popup
                    return ''
                endif
                call popup_close(s:balloon_popup_winid)
                let s:balloon_popup_winid = 0
            endif

            " Vim 8.2 popup instead of balloon
            if s:balloon_text ==# [] || s:balloon_text ==# ['']
                return ''
            endif
            let s:balloon_popup_winid = popup_beval(s:balloon_text, {'mousemoved': 'word', 'highlight': 'StatusLine'})
            return ''
        else
            " simple balloon
            return s:balloon_text
        endif
    finally
        if !win_gotoid(l:orig_winid)
            call g:VimWarningMsg('Unable to revert back to original winid ' . l:orig_winid)
        endif
        let l:result = setpos('.', l:orig_pos)
        if l:result != 0
            call g:VimWarningMsg('Unable to reset cursor position back to ' . l:orig_pos . ' (winid: ' . l:orig_winid . ')')
        endif
    endtry
endfunction

" setup ballon expressions in Vim to use the YcmHover to retrieve doc/type/... from the LSP server
" neovim does not support balloons
if !has('balloon_eval') && !has('balloon_eval_term')
    let g:ycm_auto_hover='CursorHold'
else
    let g:ycm_auto_hover=''
    if has('balloon_eval')
        set ballooneval
    endif
    if has('balloon_eval_term')
        set balloonevalterm
    endif
    set balloonexpr=g:BalloonHoverExpr()
endif

" Todo: remove these two global fuctions they are now obsolete, the plugin was changed to vim-select-multi
" these two must be global (needed for vim-multiple-cursors plugin)
function! g:Multiple_cursors_before()
    if exists('*youcompleteme#DisableCursorMovedAutocommands')
        call youcompleteme#DisableCursorMovedAutocommands()
    endif
    let b:ale_dont_show_cursor_detail = 1
    let b:ale_dont_run = 0
    " disable signature help
    if exists('g:LanguageClient_signatureHelpOnTextChangedI')
        let b:old_LanguageClient_signatureHelpOnTextChangedI=g:LanguageClient_signatureHelpOnTextChangedI
        let g:LanguageClient_signatureHelpOnTextChangedI=0
    endif
endfunction

function! g:Multiple_cursors_after()
    if exists('*youcompleteme#EnableCursorMovedAutocommands')
        call youcompleteme#EnableCursorMovedAutocommands()
    endif
    unlet! b:ale_dont_show_cursor_detail
    if exists('b:ale_dont_run')
        if b:ale_dont_run > 0
            unlet! b:ale_dont_run
            " Todo: run lint only if buffer was changed (see b:changedtick)
            ALELint
        else
            unlet! b:ale_dont_run
        endif
    endif
    " re-enable signature help
    if exists('b:old_LanguageClient_signatureHelpOnTextChangedI')
        let g:LanguageClient_signatureHelpOnTextChangedI=b:old_LanguageClient_signatureHelpOnTextChangedI
        unlet! b:old_LanguageClient_signatureHelpOnTextChangedI
    endif
endfunction

if has('autocmd')
"     autocmd! User visual_multi_start call g:Multiple_cursors_before()
"     autocmd! User visual_multi_exit call g:Multiple_cursors_after()
endif

let g:home_base_path=$HOME
let g:home_vim_folder = substitute(g:home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.vim'

" open files with the cursor at the last remembered position and also move change position to the end
" commit filetype buffers are ignored
" quickfix windows are ignored also (needed for ALE async lopen with linter errors during select-mode anomaly)
" ignore E663: At end of changelist
" ignore E664: changelist is empty
" ignore E19: Mark has invalid line number
function! g:JumpToLastPosition()
    if &filetype =~# 'commit' || &filetype =~# 'qf'
        return
    endif

    try
        keepjumps execute 'normal! 999g,'
        " if we have old changes and last of them is valid, then temporarily override g; with jump to latest change + unmap g;
        " this should help with first g; after buffer load to not go to the second last change
        nnoremap <silent> g; :<C-U>execute 'normal! g`.'<Bar>nunmap g;<CR>
    catch /:E663:\|:E664:\|:E19:/
    endtry
    try
        " if line("'\"") > 0 && line("'\"") <= line("$")
        execute 'normal! g`"'
        " endif
    catch /:E19:\|:E20:/
    endtry
endfunction

if has('autocmd')
    autocmd! BufReadPost * call g:JumpToLastPosition()
endif

set helplang=en
set langmenu=en

"set ttybuiltin "this is default
"  set notbi
"set ttymouse xterm2 "VIM autodetect from TERM env variable name (=~xterm => xterm2)

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set nobackup        " DON'T keep a backup file

set history=400     " keep 400 lines of command line history
set ruler           " show the cursor position all the time
set showcmd         " display incomplete commands
set incsearch       " do incremental searching
set tabstop=4

set number              " line numbers
if exists('+relativenumber')
    " overriden by insert/normal mode changes via numbers plugin
    set relativenumber      " relative line numbers
endif
if has('patch-8.1.1564')
    " set signcolumn=number
    set signcolumn=auto
endif
set cindent
set autoindent
if has('mouse')
    set mouse=a             " use mouse in xterm to scroll
endif
set scrolloff=5         " 5 lines before and after the current line when scrolling - overriden later
set ignorecase          " ignore case
set smartcase           " but don't ignore it, when search string contains uppercase letters
set hidden              " allow switching buffers, which have unsaved changes
set shiftwidth=4        " 4 characters for indenting
set showmatch           " showmatch: Show the matching bracket for the last ')'?

set nowrap              " don't wrap by default
syn on
set confirm

set hlsearch

set nostartofline
"set shiftround

set splitright
set splitbelow

"set autoread
"set display+=uhex
set display+=lastline

set formatoptions=tcq
if v:version > 703 || (v:version == 703 && has('patch552'))
    set formatoptions+=j
endif
set nrformats=hex
if v:version > 704 || (v:version == 704 && has('patch1027'))
    set nrformats+=bin
endif
set complete=.,w,b,u,t,i,kspell

if has('wildmenu')
    set wildmenu
endif

"set wildmode=longest:full,list:full
set wildmode=full

" set side scrolling
set sidescrolloff=8
set sidescroll=1

" always show status line (irregardless of number of shown windows)
set laststatus=2

" turn off visual paren/bracket matching (Vim official plugin - ~/apps/share/vim/vim80/plugin/matchparen.vim)
"let g:loaded_matchparen=1

" turn off vimball plugin (Vim official plugin - ~/apps/share/vim/vim80/plugin/vimballPlugin.vim)
 let g:loaded_vimballPlugin=1

"convenience mappings
nnoremap Q <nop>
"if has("user_commands")
"    command! -bang -nargs=? -complete=file E e<bang> <args>
"    command! -bang Wa wa<bang>
"endif
function! g:CommandModeAbbreviation(abbreviation, command, also_visual)
    if a:also_visual
        " TODO(akocis): check if end of first word and comma has been entered (will cover more visual range cases)
        let l:cmd = 'cabbrev ' . a:abbreviation . " <c-r>=(getcmdtype()==':' &&"
                    \ . " (getcmdpos()==1 \\|\\| getcmdline()[0:4]==#\"'<,'>\") ? '" . a:command . "' : '" . a:abbreviation . "')" . '<CR>'
        execute l:cmd
    else
        execute 'cabbrev ' . a:abbreviation . " <c-r>=(getcmdtype()==':' &&"
                    \ . " getcmdpos()==1 ? '" . a:command . "' : '" . a:abbreviation . "')" . '<CR>'
    endif
endfunction

" add abbreviations for common holding shift for too long typos for standart Vim commands
call g:CommandModeAbbreviation('E', 'e', 0)
call g:CommandModeAbbreviation('W', 'w', 0)
call g:CommandModeAbbreviation('Wq', 'wq', 0)
call g:CommandModeAbbreviation('WQ', 'wq', 0)
call g:CommandModeAbbreviation('Wa', 'wa', 0)
call g:CommandModeAbbreviation('WA', 'wa', 0)
call g:CommandModeAbbreviation('Q', 'q', 0)
call g:CommandModeAbbreviation('Qa', 'qa', 0)
call g:CommandModeAbbreviation('QA', 'qa', 0)
call g:CommandModeAbbreviation('X', 'x', 0)
call g:CommandModeAbbreviation('Xa', 'xa', 0)
call g:CommandModeAbbreviation('XA', 'xa', 0)

"no splash screen
set shortmess+=I

"visual block extension beyong line endings ($ still selects up to respective line end)
set virtualedit=block

if v:version >= 700
    set tabpagemax=25
endif

" improved search and replace (cgn operations)
" replaces
nnoremap c*  *Ncgn
nnoremap c#  #NcgN

" appends
nnoremap c>* *Ncgn<C-r>"
nnoremap c># #NcgN<C-r>"

" prepends
if v:version < 801 || (v:version == 801 && !has('patch1055'))
    " workaround for <C-g>U and <S-Left> bug in versions < 8.1.1055
    if v:version > 704 || (v:version == 704 && has('patch849'))
        " older versions than 7.4.849 cannot do the workaround based on <C-g>U in insert mode
        nnoremap <expr> c<* '*Ncgn<C-r>"'.repeat('<C-g>U<Left>',strlen(@"))
        nnoremap <expr> c<# '*NcgN<C-r>"'.repeat('<C-g>U<Left>',strlen(@"))
    endif
else
    nnoremap c<* *Ncgn<C-r>"<C-g>U<S-Left>
    nnoremap c<# #NcgN<C-r>"<C-g>U<S-Left>
endif

"function! Align()
"    '<,'>!column -t|sed 's#  \(\S\)# \1#g'
"    normal gv=
"endfunction
"
"xnoremap <silent> gQ :<C-u>silent call Align()<CR>

"needs to be after syn on (syntax on)
let g:colors_name=''
try
    exec 'colorscheme ' . g:color_scheme
    let g:colors_name = g:color_scheme
catch /:E185:/
    " E185 colorscheme not found
    " just ignore
endtry
let g:color_scheme_loaded = 1

"refresh airline after colorscheme load, if already loaded
if v:version >= 700 && exists('#airline')
    exe ':call airline#load_theme()'
else
    set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
endif

if has('cscope')
    set cscopetag
    set cscopetagorder=1
    set cscopepathcomp=0
    set cscopequickfix=s-,c-,d-,i-,t-,e-,f0,g0      " cscope will fill results into quickfix window (possible to open via :copen command, move with <F11><F12>)
    if v:version > 704 || (v:version == 704 && has('patch2033'))
        set cscopequickfix+=a-
    endif
endif

inoremap jk <Esc>

" follow visual lines (instead of lines) - comes into play when line wrapping is on
noremap <A-Down> gj
noremap <A-Up> gk
inoremap <A-Up> <C-o>gk
inoremap <A-Down> <C-o>gj

" few GNU readline like alt shortcuts (taken from rsi.vim plugin)
if has('gui_running') || has('nvim')
  noremap! <M-b> <S-Left>
  noremap! <M-f> <S-Right>
  noremap! <M-d> <C-O>dw
  " necessary workaround because Vim command line mode does not have delete forward word
  cnoremap <M-d> <S-Right><C-W>
  noremap! <M-n> <Down>
  noremap! <M-p> <Up>
  noremap! <M-BS> <C-W>
  noremap! <M-C-h> <C-W>
else
  silent! exe "set <F29>=\<Esc>b"
  silent! exe "set <F30>=\<Esc>f"
  silent! exe "set <F31>=\<Esc>d"
  silent! exe "set <F32>=\<Esc>n"
  silent! exe "set <F33>=\<Esc>p"
  silent! exe "set <F34>=\<Esc>\<C-?>"
  silent! exe "set <F35>=\<Esc>\<C-H>"
  noremap! <F29> <S-Left>
  noremap! <F30> <S-Right>
  noremap! <F31> <C-O>dw
  " necessary workaround because Vim command line mode does not have delete forward word
  cnoremap <F31> <S-Right><C-W>
  noremap! <F32> <Down>
  noremap! <F33> <Up>
  noremap! <F34> <C-W>
  noremap! <F35> <C-W>
endif

"reselect visual selection after <,> movements
vnoremap < <gv
vnoremap > >gv

" make Y behave like other capitals
noremap Y y$

" map u/U in visual mode to undo (instead of to lowercase/to uppercase)
vnoremap u <Esc>u
vnoremap U <Esc>U

"Todo: map <C-S> and <C-Q> to something interesting (first need to claim them from terminal)
noremap <C-S> :CtrlPTag<CR>
"noremap! <C-S> <C-o>:CtrlPTag<CR>
noremap <C-Q> :CtrlPBufTag<CR>
"noremap! <C-Q> <C-o>:CtrlPBufTag<CR>

" force saving files that require root permission
comm! -nargs=0 SudoWrite %!sudo tee > /dev/null %
call g:CommandModeAbbreviation('w!!', 'SudoWrite', 0)

" do not move cursor during yank in visual mode
vnoremap y ygv<Esc>

" used in vim-signify plugin (not anymore)
function! g:StoreSelectionMode()
    let l:reselect = 0
    if mode() ==? 'v' || mode() ==# "\<c-v>"
        let l:reselect = 1
    elseif mode() ==? 's' || mode() ==# "\<c-s>"
        let l:reselect = 2
    endif
    return l:reselect
endfunction

function! g:RestoreSelectionMode(reselect)
    if a:reselect > 0
        execute 'normal! gv'
        if a:reselect > 1
            execute "normal! \<c-g>"
        endif
    endif
endfunction

" used in cscope_maps.vim plugin
function! g:GetVisualSelection()
    " Why is this not a built-in Vim script function?!
    let [l:lnum1, l:col1] = getpos("'<")[1:2]
    let [l:lnum2, l:col2] = getpos("'>")[1:2]
    let l:lines = getline(l:lnum1, l:lnum2)
    if empty(l:lines)
        return ''
    endif
    let l:lines[-1] = l:lines[-1][: l:col2 - (&selection ==# 'inclusive' ? 1 : 2)]
    let l:lines[0] = l:lines[0][l:col1 - 1:]
    return join(l:lines, "\n")
endfunction

"apply macro on every line of a visually selected range
if v:version >= 700
    xnoremap @ :<C-u>call vimrc#ExecuteMacroOverVisualRange()<CR>
endif

" my approach based on heavy use of [{ and ]} - does not work well for namespaces in C++
" "Todo: add visual/operator mappings for custom section jumps (see MyParagraphJump as an example)
" nnoremap [[ :<C-U>call vimrc#My_PreSection(v:count1, "{", "bW", "w99[{")<CR>
" nnoremap ][ :<C-U>call vimrc#My_PreSection(v:count1, "}", "W", "b99]}")<CR>
" nnoremap ]] :<C-U>call vimrc#My_SectionJump(v:count1, "][", "[[")<CR>
" nnoremap [] :<C-U>call vimrc#My_SectionJump(v:count1, "[[", "][")<CR>

" " another approach based on function name heuristics (if,switch,... vs. other name)
" nnoremap <silent> ]m :<c-u>call vimrc#jumpmethod('{', 'W',  'n')<cr>
" nnoremap <silent> [m :<c-u>call vimrc#jumpmethod('{', 'Wb', 'n')<cr>
" nnoremap <silent> ]M :<c-u>call vimrc#jumpmethod('}', 'W',  'n')<cr>
" nnoremap <silent> [M :<c-u>call vimrc#jumpmethod('}', 'Wb', 'n')<cr>
"
" xnoremap <silent> ]m :<c-u>call vimrc#jumpmethod('{', 'W',  'n')<cr>
" xnoremap <silent> [m :<c-u>call vimrc#jumpmethod('{', 'Wb', 'n')<cr>
" xnoremap <silent> ]M :<c-u>call vimrc#jumpmethod('}', 'W',  'n')<cr>
" xnoremap <silent> [M :<c-u>call vimrc#jumpmethod('}', 'Wb', 'n')<cr>
"
" onoremap <silent> ]m :<c-u>call vimrc#jumpmethod('{', 'W',  'n')<cr>
" onoremap <silent> [m :<c-u>call vimrc#jumpmethod('{', 'Wb', 'n')<cr>
" onoremap <silent> ]M :<c-u>call vimrc#jumpmethod('}', 'W',  'n')<cr>
" onoremap <silent> [M :<c-u>call vimrc#jumpmethod('}', 'Wb', 'n')<cr>

" looks like the Vim integrated one is the best [m and ]m - nope, does not work for C/C++ reliably (requires namespace/class encapsulation)
nnoremap <silent> ]] ]m
nnoremap <silent> [[ [m
nnoremap <silent> ][ ]M
nnoremap <silent> [] [M

xnoremap <silent> ]] ]m
xnoremap <silent> [[ [m
xnoremap <silent> ][ ]M
xnoremap <silent> [] [M

onoremap <silent> ]] ]m
onoremap <silent> [[ [m
onoremap <silent> ][ ]M
onoremap <silent> [] [M

function! g:SetupCppFunctionJumps()
    nnoremap <silent> <buffer> [[ :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 0, 1)<CR>
    nnoremap <silent> <buffer> ][ :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 0, 1)<CR>
    nnoremap <silent> <buffer> [] :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 1, 1)<CR>
    nnoremap <silent> <buffer> ]] :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 1, 1)<CR>

    xnoremap <silent> <buffer> [[ :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 0, 1, visualmode())<CR>
    xnoremap <silent> <buffer> ][ :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 0, 1, visualmode())<CR>
    xnoremap <silent> <buffer> [] :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 1, 1, visualmode())<CR>
    xnoremap <silent> <buffer> ]] :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 1, 1, visualmode())<CR>

    onoremap <silent> <buffer> [[ :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 0, 1)<CR>
    onoremap <silent> <buffer> ][ :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 0, 1)<CR>
    onoremap <silent> <buffer> [] :<C-U>call vimrc#surrounding_function_search(v:count1, "{", 1, 1)<CR>
    onoremap <silent> <buffer> ]] :<C-U>call vimrc#surrounding_function_search(v:count1, "}", 1, 1)<CR>
endfunction

" inner function text object (in C/C++ function body is selected)
" vnoremap if :<C-U>silent! normal! [mv]M<CR>
vnoremap <silent> if :<C-U>call vimrc#ExtendVisualSelectionToSurroundingFunction(v:count1, 0)<CR>gv
" omap if :normal vif<CR>
omap <silent> if :execute 'keepjumps normal v' . v:count1 . 'if'<CR>

" around function text object (in C/C++ function name with args + function body is selected + empty lines below)
" vnoremap af :<C-U>silent! normal! [m(V]M<CR>/\S<CR><BS>:<C-U>let @/=""<CR>gv
" vnoremap af :<C-U>silent! normal! [m(v]M<CR>:call search('\S', 'Wz') \| call setpos("'>", getpos('.'))<CR>gv:<C-U>silent! normal! <BS>gv
" vnoremap af :<C-U>silent! normal! [m(v]M<CR>:<C-U>call g:ExtendEndOfVisualSelection('\S', 'W')<CR>gv
" vnoremap af :<C-U>silent! normal! [m<CR>:<C-U>call g:SearchStartOfVisualSelection()<CR>:<C-U>silent! normal! v]M<CR>:<C-U>call g:ExtendEndOfVisualSelection('\S', 'W')<CR>gv
vnoremap <silent> af :<C-U>call vimrc#ExtendVisualSelectionToSurroundingFunction(v:count1, 1)<CR>gv
" omap af :normal vaf<CR>
omap <silent> af :execute 'keepjumps normal v' . v:count1 . 'af'<CR>

nnoremap <silent> { :<C-U>call vimrc#MyParagraphJump(v:count1, 0)<CR>
nnoremap <silent> } :<C-U>call vimrc#MyParagraphJump(v:count1, 1)<CR>

onoremap <silent> { :<C-U>call vimrc#MyParagraphJump(v:count1, 0)<CR>
onoremap <silent> } :<C-U>call vimrc#MyParagraphJump(v:count1, 1)<CR>

vnoremap <silent> { :<C-U>call vimrc#MyParagraphJump(v:count1, 0, visualmode())<CR>
vnoremap <silent> } :<C-U>call vimrc#MyParagraphJump(v:count1, 1, visualmode())<CR>

set errorformat^=%-GIn\ file\ included\ from\ %f:%l:%c:,%-GIn\ file\ included\ from\ %f:%l:%c\\,,%-GIn\ file\ included\ from\ %f:%l:%c,%-GIn\ file\ included\ from\ %f:%l,%-G%*[\ ]from\ %f:%l:%c
set errorformat^=%-G%n:%l:%c%.%#\ Tar\'ing\ up\ changed\ files,%-GBuilding\ list\ of\ req'd\ files\ -\ starting\ at\ %s\ %n:%l:%c\ %.%#,%-GDone\ at\ %s\ %n:%l:%c\ %.%#,%-G%n:%l:%c\ %m\ Sending\ changed\ files\ to\ server,%-G%n:%l:%c\ %s\\,\ Remotely\ executing\ %.%#,%-G###\ %n:%l:%c%.%#\,\ Rsyncing\ files\ with\ \ server\ %.%#,%-G%.%#%n:%l:%c%.%#\,\ Remotely\ SSH\ executing\ %.%#

" let l:current_window = win_getid()
" ... do something that alters the current window and/or tab and now i want to go back
" call win_gotoid(l:current_window)

function! s:UpdateLastModification(force)
    let l:update_needed = a:force
    if l:update_needed == 0
        if &modifiable == 0
            " non-modifiable buffers are not interesting
            return
        endif
        if &filetype =~# 'netrw' || &filetype =~# 'commit' || &filetype =~# 'qf'
            " special filetypes that update themselves all the time
            return
        endif
        if !exists('b:my_changedtick')
            let b:my_changedtick = 0
        endif
        if b:my_changedtick != b:changedtick
            let b:my_changedtick = b:changedtick
            let l:update_needed = 1
        endif
    endif
    if l:update_needed
        let g:last_text_change_tab = tabpagenr()
        let g:last_text_change_winid = win_getid()
        let g:last_text_change_bufname = bufname('%')
    endif
endfunction

function! s:GoToLastModification()
    let l:searched_bufname = expand(g:last_text_change_bufname)

    if l:searched_bufname ==# ''
        " if last remembered bufname is empty or expands to empty string, then there
        " is no point in continuing
        return
    endif

    " find expanded last_text_change_bufname in all tabpages
    let l:bufmap = []
    for l:i in range(1, tabpagenr('$'))
        let l:tabpage_buflist = tabpagebuflist(l:i)
        call extend(l:bufmap, map(range(1, tabpagewinnr(l:i, '$')), '[bufname(l:tabpage_buflist[v:val - 1]), win_getid(v:val, l:i)]'))
    endfor
    " echo l:bufmap
    let l:result_list = filter(l:bufmap, 'v:val[0] =~ l:searched_bufname')

    " check for first/exact match through all windows showing the last_text_change_bufname
    let l:exact_window = 0
    let l:final_winid = 0
    for l:pair in l:result_list
        " echomsg l:pair[0] . " - " . l:pair[1]
        if l:pair[1] == g:last_text_change_winid
            " we have exact matching window with the same buffer (maybe different tab though)
            let l:final_winid = l:pair[1]
            let l:exact_window = 1
            break
        endif
        if l:final_winid == 0
            " we have non-exact first match (this a different tab/window containing the same buffer)
            let l:final_winid = l:pair[1]
            " continue searching for exact match
        endif
    endfor

    let l:win_jump_result = 0
    if l:final_winid > 0
        " we have existing winid target => go there
        " result of 0 means jump has failed
        let l:win_jump_result = win_gotoid(l:final_winid)
        if l:win_jump_result == 1
            " successful jump to window
            " if not exact window, then jump to last change, otherwise do not move
            if l:exact_window == 0
                execute 'normal! `.'
            endif
        endif
    else
        " echo "Buffer with name '" . l:searched_bufname . "' is not active (in any window)"
    endif

    if l:win_jump_result == 0
        if bufname(g:last_text_change_bufname) !=# ''
            " window identified by last_text_change_winid does not exist anymore
            " or jump was unsuccessful, but the buffer exists

            if g:last_text_change_tab <= tabpagenr('$')
                " if possible switch to last remembered tabpage
                execute 'tabnext '.g:last_text_change_tab
            endif

            " show the buffer
            execute 'buffer '.g:last_text_change_bufname

            " go to last change in the buffer
            " execute 'normal! 99g,'
            execute 'normal! `.'
        else
            echo "Buffer with name '" . l:searched_bufname . "' is not loaded"
            return
        endif
    endif

    " update saved last text change variables (we may be at different tab/window)
    call s:UpdateLastModification(1)
endfunction

function! g:ResetALEHighlightGroups()
    if g:color_scheme =~# 'solarized' && hlexists('CompilationError')
        highlight link ALEErrorSign CompilationError
        highlight link ALEError CompilationError
        highlight link ALEWarningSign CompilationWarning
        highlight link ALEWarning CompilationWarning
    else
        highlight link ALEErrorSign Error
        highlight link ALEError Error
        highlight link ALEWarningSign Todo
        highlight link ALEWarning Todo
    endif
    if g:color_scheme =~# 'solarized' && hlexists('CppMemberVariable')
        highlight! link LspCxxHlGroupEnumConstant CppEnumConstant
        highlight! link LspCxxHlGroupNamespace CppNamespace
        highlight! link LspCxxHlGroupMemberVariable CppMemberVariable
    else
        hi default LspCxxHlGroupEnumConstant ctermfg=Magenta guifg=#AD7FA8 cterm=none gui=none
        hi default LspCxxHlGroupNamespace ctermfg=Yellow guifg=#BBBB00 cterm=none gui=none
        hi default LspCxxHlGroupMemberVariable ctermfg=White guifg=White
    endif
    highlight link ALEInfoSign SpellCap
    highlight link ALEInfo SpellCap
    highlight link ALEStyleErrorSign SpellRare
    highlight link ALEStyleError SpellRare
    highlight link ALEStyleWarningSign SpellLocal
    highlight link ALEStyleWarning SpellLocal
endfunction

if v:version >= 700
    " set completion options
    set completeopt=menu,longest ",longest,preview

    " infers case of the match from the entered word (good for dictionary and thesaurus)
    set infercase
    " dictionary completion CTRL+X CTRL+K in insert mode
    set dictionary=/usr/share/dict/words
    " thesaurus synonyms completion CTRL+X CTRL+T in insert mode
    set thesaurus=~/.vim/plugin/mtopenoffice.txt
    "inoremap <C-X><C-T> <C-o>:setlocal isk+=-<CR><C-o>:setlocal isk+=32<CR><C-X><C-T>
    " spell checking (switchable by <Leader>s), CTRL+X CTRL+S in insert mode
    set nospell
    set spelllang=en
    set spellsuggest=5

    " add return to last tab page movement to g<Tab> keybinding
    if has('autocmd')
        if !exists('g:last_visited_tab')
            let g:last_visited_tab = tabpagenr()
        endif
        nnoremap <silent> g<Tab> :execute 'tabnext '.g:last_visited_tab<CR>
        autocmd! TabLeave * let g:last_visited_tab = tabpagenr()

        if exists('*win_getid()')
            if !exists('g:last_text_change_tab')
                let g:last_text_change_tab = tabpagenr()
                let g:last_text_change_winid = win_getid()
                let g:last_text_change_bufname = bufname('%')
            endif
            nnoremap <silent> z<Tab> :execute 'tabnext '.g:last_text_change_tab<CR>
            nnoremap <silent> z; :call <SID>GoToLastModification()<CR>
            " Todo: skip Startify, netrw explorer(ft=netrw) and other plugin windows when saving last text change stuff
            " autocmd! TextChanged * let g:last_text_change_tab = tabpagenr() | let g:last_text_change_winid = win_getid() | let g:last_text_change_bufname = bufname('%')
            " autocmd! TextChangedI * let g:last_text_change_tab = tabpagenr() | let g:last_text_change_winid = win_getid() | let g:last_text_change_bufname = bufname('%')
            autocmd! TextChanged * call s:UpdateLastModification(0)
            autocmd! TextChangedI * call s:UpdateLastModification(0)
        endif
    endif
endif

" ============================
" =       Window title       =
" ============================
"Xxx: this sets screen tab's caption
"let &t_ts="\ek"
"let &t_fs="\e\"
"don't reset screen tab's caption to flying...
"autocmd! VimLeave * let &t_ts="\ek\e\"

set title

if has('autocmd')
    "autocmd! BufEnter * let &titlestring= expand("%:t") . " (" . expand($REL) . "-" . expand($RELP) . " " . expand($VPLOAD) . expand($HOST_TAG) . " " . expand($SS) . " | " . expand($ROOT) . ")"
    if $REL ==# ''
        autocmd! BufEnter * let &titlestring= "%m%r" . expand("%:t")
    else
        if $VPLOAD !=# ''
            if $REL != $RELP
                autocmd! BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . "-" . $RELP . " " . $VPLOAD . $HOST_TAG . " " . $SS . " | " . $ROOT . ")"
            else
                autocmd! BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . " " . $VPLOAD . $HOST_TAG . " " . $SS . " | " . $ROOT . ")"
            endif
        else
            autocmd! BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . " " . $CURRENT_LOCATION . " | " . $ROOT . ")"
        endif
    endif
endif

" autocmd! BufEnter * let &titlestring = hostname() . "/" . expand("%:p")
"Here the window title is reset when the user enters a new buffer. It contains the hostname, a forward slash, then the full path of the current file - for an explanation of the %:p syntax see the Filename Modifiers section of the Executing External Commands recipe..
"
"Another example is to display the value of an environment variable in the window title along with the filename. For instance, Ruby on Rails developers could prefix the filename with the value of RAILS_ENV, which indicates whether the application is in development, production, staging, or testing mode:
"let &titlestring=expand($RAILS_ENV) . ": " . expand("%:t")
"One last trick is to embed the value of an external command in the window title using the %{system('command')} syntax. This could be used to display the name of the current branch, if using a version control system, or indicate whether the project's unit tests are passing or failing.

" ============================
" =          Folding         =
" ============================
if v:version > 600
    if has('folding')
        set nofoldenable
        " superslow method of folding from VIM 7.2.274a
        if v:version < 702
            set foldmethod=syntax
        else
        " another older version of folding (does not work with matching brackets in VIM7
            "syn region myFold start="{" end="}" transparent fold
            "syn sync fromstart
            "set foldlevel=5
        " older version of folding (only pure brackets)
            set foldmarker={,}
            set foldmethod=marker
        endif
    endif
endif

" =====================
" =Moving between tabs=
" =====================
if v:version >= 700
    " navigating multiple tabs - works only in graphical modes (gVim)
    nnoremap <C-Tab> :tabnext<Enter>
    nnoremap <C-S-Tab> :tabprev<Enter>
    inoremap <C-Tab> <C-o>:tabnext<Enter>
    inoremap <C-S-Tab> <C-o>:tabprev<Enter>
    vnoremap <C-Tab> <Esc>:tabnext<Enter>gv
    vnoremap <C-S-Tab> <Esc>:tabprev<Enter>gv
endif

function! g:GoToNeigborWindowOrTab(left)
    let l:original_tab = tabpagenr()
    let l:original_window = winnr()

    let l:left_win = 'wincmd h'
    let l:right_win = 'wincmd l'
    let l:left_tab = 'normal! gT'
    let l:right_tab= 'normal! gt'
    if a:left == 0
        " swap movements if movement to the right is requested
        let l:temp = l:left_win
        let l:left_win = l:right_win
        let l:right_win = l:temp
        let l:temp = l:left_tab
        let l:left_tab = l:right_tab
        let l:right_tab = l:temp
    endif

    execute l:left_win
    if winnr() == l:original_window
        execute l:left_tab
        if tabpagenr() == l:original_tab
            " nowhere to go (at the edge of Vim)
            return 0
        endif
        let l:current_window = -1
        while l:current_window != winnr()
            let l:current_window = winnr()
            execute l:right_win
        endwhile
    endif
endfunction

" ========================
" =Moving between windows=
" ========================
if v:version >= 700
    " CTRL+SHIFT+UP/DOWN works only in graphical modes
    nnoremap <C-S-Up> <C-w>W
    nnoremap <C-S-Down> <C-w>w
    inoremap <C-S-Up> <C-o><C-w>W
    inoremap <C-S-Down> <C-o><C-w>w
    vnoremap <C-S-Up> <C-w>Wgv
    vnoremap <C-S-Down> <C-w>wgv
endif

" simplified movement through windows
nmap <C-Up> <C-S-Up>
nmap <C-Down> <C-S-Down>
imap <C-Up> <C-S-Up>
imap <C-Down> <C-S-Down>
vmap <C-Up> <C-S-Up>
vmap <C-Down> <C-S-Down>

" do the same with g+arrows as with <C-w>+arrows (simplified window movement)
nnoremap <silent>g<Left> :call g:GoToNeigborWindowOrTab(1)<CR>
nnoremap <silent>g<Right> :call g:GoToNeigborWindowOrTab(0)<CR>
nnoremap g<Up> <C-w><Up>
nnoremap g<Down> <C-w><Down>
xnoremap <silent>g<Left> <Esc>:call g:GoToNeigborWindowOrTab(1)<CR>
xnoremap <silent>g<Right> <Esc>:call g:GoToNeigborWindowOrTab(0)<CR>
xnoremap g<Up> <C-w><Up>
xnoremap g<Down> <C-w><Down>

" ======================================
" =Windows editors selection short-cuts=
" ======================================
" Todo: improve insert mode (do without _ insertion and marks)
" word selection
nnoremap <S-Left> vbge<Space>
nnoremap <S-Right> vew<BS>
inoremap <S-Left> _<Esc>mz"_xv`z<BS>obge<Space>
inoremap <S-Right> _<Esc>my"_xi<Right><C-o><BS>_<Esc>mz"_xv`yo`z
vnoremap <S-Left> bge<Space>
vnoremap <S-Right> ew<BS>

" down/up selection
nnoremap <S-Down> v<Down>
nnoremap <S-Up> v<Up>
inoremap <S-Down> _<Esc>mz"_xv`zo`z<Down><Right><BS><BS>
inoremap <S-Up> _<Esc>mz"_xv`z<Up>o`z<BS>o
vnoremap <S-Down> <Down>
vnoremap <S-Up> <Up>

" home/end selection
nnoremap <S-Home> v<Home>
nnoremap <S-End> v<End>
inoremap <S-Home> _<Esc>mz"_s<C-o><Left><C-o>`z<Esc>v<Home>
inoremap <S-End> _<Esc>mz"_xv`zo<End>
vnoremap <S-Home> <C-S-Home>
vnoremap <S-End> <C-S-End>

" half page down/up selection (gVim only?)
nnoremap <S-PageDown> v<End><C-d><End>
nnoremap <S-PageUp> v<Home><C-u>
inoremap <S-PageDown> _<Esc>mz"_xv`zo<End><C-d><End>
inoremap <S-PageUp> _<Esc>mz"_xv`z<BS>o<Home><C-u>
vnoremap <S-PageDown> <End><C-d><End>
vnoremap <S-PageUp> <Home><C-u>

" word deletion
inoremap <C-BS> <C-w>
"imap <C-Del> _<Esc>mzew<BS>i<Del><Esc>v`z"_c
inoremap <C-Del> <C-o>de

" ========================
" =Visual mode operations=
" ========================
" indentation with Tab/S-Tab on selected blocks
xnoremap <Tab> >gv
xnoremap <S-Tab> <LT>gv

" indentation by one space with Space/Backspace on selected blocks
xnoremap <Backspace> <Esc>:let origsw=&sw<CR>:let &sw=1<CR>gv<<Esc>:let&sw=origsw<CR>gv
xnoremap <Space> <Esc>:let origsw=&sw<CR>:let &sw=1<CR>gv><Esc>:let&sw=origsw<CR>gv

" move selected lines
vnoremap <C-j> :m '>+1<CR>gv=gv
vnoremap <C-k> :m '<-2<CR>gv=gv
"vnoremap <C-S-j> :m '>+1<CR>gv
"vnoremap <C-S-k> :m '<-2<CR>gv

" duplicate (above) selected lines (leave selection intact)
vnoremap <C-d> :t .-1<CR>gv

nnoremap <silent>z_ :call vimrc#MySynonymLookup("n")<Enter>
vnoremap <silent>z_ <Esc>:call vimrc#MySynonymLookup("v")<Enter>

nnoremap z, :call vimrc#MoveToPrevTab()<CR>
nnoremap z. :call vimrc#MoveToNextTab()<CR>

" ============================
" =        Fx commands       =
" ============================
if v:version >= 703
    nmap <silent><S-F7> :call vimrc#ToggleUndoTree()<Enter>
    imap <silent><S-F7> <C-o>:call vimrc#ToggleUndoTree()<Enter>
    vmap <silent><S-F7> <Esc>:call vimrc#ToggleUndoTree()<Enter>gv
else
    nmap <silent><S-F7> :call vimrc#SophHelp()<Enter>
    imap <silent><S-F7> <C-o>:call vimrc#SophHelp()<Enter>
    vmap <silent><S-F7> <Esc>:call vimrc#SophHelp()<Enter>gv
endif

" F2 to save
nmap <silent><F2> :w<Enter>
imap <silent><F2> <C-o>:w<Enter>
vmap <silent><F2> <Esc>:w<Enter>gv

" F3 to toggle source/header
nmap <silent><F3> :call vimrc#Header_switch()<CR>
imap <silent><F3> <C-o>:call vimrc#Header_switch()<CR>

" S-F3 colorscheme toggle (between wombat and solarized light)
" nmap <silent> <S-F3> :call vimrc#ToggleColorTheme()<Enter>
" imap <silent> <S-F3> <C-o>:call vimrc#ToggleColorTheme()<Enter>
" vmap <silent> <S-F3> <Esc>:call vimrc#ToggleColorTheme()<Enter>v

" F4 to switch between hex and ASCII editing
nmap <silent><S-F4> :call vimrc#Fxxd()<Enter>
imap <silent><S-F4> <C-o>:call vimrc#Fxxd()<Enter>

" ignore whitespace differences is on by default (iwhite)
set diffopt=filler,context:6,foldcolumn:0,vertical,iwhite
" no character inside line diff by default (g:DiffModeSync)
let g:DiffModeSync = 0
let g:diffexecutable = 'git_2_13_3'
let g:difffixedargs = 'diff -U0 --no-color --no-ext-diff'
let g:diffnoindex = '--no-index'
" histogram with indent heuristic by default
let g:diffoptions = '--diff-algorithm=histogram --indent-heuristic'
if !exists('g:signify_vcs_cmds')
    let g:signify_vcs_cmds = {}
endif
let g:signify_vcs_cmds['git'] = g:diffexecutable . ' ' . g:difffixedargs . ' ' . g:diffoptions . ' -- %f'
let g:signify_sign_priority = 5
set diffexpr=vimrc#GitDiff()

if v:version >= 801
    if has('cursorshape')
        " Note: when it fails, the Vim needs to be killed from other window or terminal killed/closed
        " TODO AKO maybe also check set terminal and allow only terminals with bracketed mode support
        " (xterm, urxvt, iTerm2, gnome-terminal (and other terminals using libvte) are known to work)
        " Note: has problem in screen, when enabled in one window (e.g. in Vim) the reset of windows have it also turned on
        " TODO enable by default after bracketing/cursorshape is supported in screen (intergrate the patch)
        let g:toggle_cursor_auto_detect_paste_mode = 0
    endif
endif

nmap <silent><F8> :TagbarToggle<Enter>
imap <silent><F8> <C-o>:TagbarToggle<Enter>
vmap <silent><F8> <Esc>:TagbarToggle<Enter>gv

"nmap <silent><S-F8> :TlistToggle<Enter>
"imap <silent><S-F8> <C-o>:TlistToggle<Enter>
"vmap <silent><S-F8> <Esc>:TlistToggle<Enter>gv

nmap <silent><S-F6> :call vimrc#LoadSession()<Enter>
imap <silent><S-F6> <C-o>:call vimrc#LoadSession()<Enter>
vmap <silent><S-F6> <Esc>:call vimrc#LoadSession()<Enter>gv

nmap <silent><S-F5> :call vimrc#SaveSession()<Enter>
imap <silent><S-F5> <C-o>:call vimrc#SaveSession()<Enter>
vmap <silent><S-F5> <Esc>:call vimrc#SaveSession()<Enter>gv

" F10 to quit
nmap <silent><F10> :q<Enter>
imap <silent><F10> <C-o>:q<Enter>
vmap <silent><F10> <Esc>:q<Enter>gv
"map ^_ gf

nmap <silent><S-F10> :qa<Enter>
imap <silent><S-F10> <C-o>:qa<Enter>
vmap <silent><S-F10> <Esc>:qa<Enter>gv

" Quickfix window - prev/next line jumps
nmap <silent> <F11> :call vimrc#Quickfix_window_move("quickfix", "prev")<Enter>
imap <silent> <F11> <C-o>:call vimrc#Quickfix_window_move("quickfix", "prev")<Enter>
vmap <silent> <F11> <Esc>:call vimrc#Quickfix_window_move("quickfix", "prev")<Enter>v

nmap <silent> <F12> :call vimrc#Quickfix_window_move("quickfix", "next")<Enter>
imap <silent> <F12> <C-o>:call vimrc#Quickfix_window_move("quickfix", "next")<Enter>
vmap <silent> <F12> <Esc>:call vimrc#Quickfix_window_move("quickfix", "next")<Enter>v

" Location window - prev/next line jumps
nmap <silent> <S-F11> :call vimrc#Quickfix_window_move("location", "prev")<Enter>
imap <silent> <S-F11> <C-o>:call vimrc#Quickfix_window_move("location", "prev")<Enter>
vmap <silent> <S-F11> <Esc>:call vimrc#Quickfix_window_move("location", "prev")<Enter>v

nmap <silent> <S-F12> :call vimrc#Quickfix_window_move("location", "next")<Enter>
imap <silent> <S-F12> <C-o>:call vimrc#Quickfix_window_move("location", "next")<Enter>
vmap <silent> <S-F12> <Esc>:call vimrc#Quickfix_window_move("location", "next")<Enter>v

" these will jump to the nearest (to current cursor position) item in quickfix window/location list
nmap ]q :call vimrc#Quickfix_move_to_nearest_item(v:count1, 0, 0)<CR>
nmap [q :call vimrc#Quickfix_move_to_nearest_item(v:count1, 0, 1)<CR>
nmap ]l :call vimrc#Quickfix_move_to_nearest_item(v:count1, 1, 0)<CR>
nmap [l :call vimrc#Quickfix_move_to_nearest_item(v:count1, 1, 1)<CR>

" common leader mappings (TODO add vmap support in general to all toggles and diff options)
let g:mapleader = ','
map <Leader>n :call vimrc#ToggleNumbers()<CR>
map <Leader>N :call vimrc#ToggleNumberDisplayMode()<CR>

map <Leader>dw :call vimrc#ToggleDiffWhitespace()<CR>
map <Leader>da :call vimrc#ToggleDiffOptions()<CR>
" diffchar.vim <Leader>dc mapping will be overriden in lazy loading file
map <silent> <Leader>dc :call vimrc#ToggleWithinLineDiffCharAllLines()<CR>
map <silent> <Leader>dr :diffupdate<CR>

map <Leader>l :set invlist!<CR>
map <Leader>s :set spell!<CR>
map <Leader>F :call vimrc#ToggleSignifyFold()<CR>
map <Leader>w :set wrap!<CR>
map <Leader>p :set paste!<CR>

map <silent><Leader>C :call vimrc#ToggleColorTheme()<CR>

map <Leader>f :YcmCompleter FixIt<CR>
map <Leader>t :YcmCompleter GetType<CR>
map <Leader>T :YcmCompleter GetParent<CR>
"map <Leader>h :YcmCompleter GoToDeclaration<CR>
" rest of the Ycm mappings are in the cscope_maps.vim

" bind Shift+Tab key in normal mode to operation <C-O> - will be symmetrical to Tab key being bound to <C-I>
nnoremap <S-Tab> <C-O>

map <Leader>A :call vimrc#ALEGlobalToggle()<CR>
map <Leader>a :call vimrc#ALELocalToggle()<CR>
map <Leader>Y :call vimrc#YcmGlobalToggle()<CR>
map <Leader>y :call vimrc#YcmLocalToggle()<CR>
map <Leader>H :call vimrc#SemanticHighlightsGlobalToggle()<CR>
map <Leader>h :call vimrc#SemanticHighlightsLocalToggle()<CR>
map <silent><Leader>S :call vimrc#ContextToggle()<CR>

map <Leader>m :call vimrc#SwitchMouse()<CR>

" path leader mappings
"map <Leader>0 :let &path=g:default_search_path<CR>

" bind function to the tab key
imap <silent><Tab> <C-r>=vimrc#TabCompletion(0)<CR>
imap <silent><S-Tab> <C-r>=vimrc#TabCompletion(1)<CR>

" Todo: move code_complete plugin to autoload the plugin (when used from selection mode)
smap <Tab> <Esc>:call SwitchRegion(0)<CR>
smap <S-Tab> <Esc>:call SwitchRegion(1)<CR>

" bind ,a to grep word under cursor
" disabled " nnoremap <Leader>a :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

" bind \ to Rg - similar to /, just enter search string
" disabled " nnoremap \ :grep!<SPACE>

" ============================
" =        OS specific       =
" ============================
if g:OS_name ==# 'windows'
    set grepprg=findstr\ /R\ /S\ /N
else
    set grepprg=grep\ -nH\ $*\ /dev/null

    if executable('rg')
        " RipGrep
        set grepprg=rg\ --vimgrep
        let &g:grepformat='%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f  %l%m'
        let g:ag_prg = &g:grepprg
        let g:ag_file_list = '--files'
        let g:ag_working_path_mode = 'r'
    elseif executable('ag')
        " The Silver Searcher
        set grepprg=ag\ --vimgrep
        let &g:grepformat='%f:%l:%c:%m,%f:%l:%m,%f:%l%m,%f  %l%m'
        let g:ag_prg = &g:grepprg
        let g:ag_file_list = '-g'
        let g:ag_working_path_mode = 'r'
    endif

    "set equalprg=indent\ -gnu
    "set equalprg=indent\ -nbad\ -bap\ -nbc\ -bbo\ -bl\ -bli0\ -bls\ -ncdb\ -nce\ -cp1\ -cs\ -di16\ -ndj\ -nfc1\ -nfca\ -hnl\ -i4\ -ip5\ -lp\ -pcs\ -nprs\ -psl\ -saf\ -sai\ -saw\ -nsc\ -nsob\ -nut
    "set formatprg=par\ -w78j
endif

" =================
" = Autoload tags =
" =================
" reads tags from tags file in current folder and also from $CTAGS_FILE file and
" also from $CTAGS_PREFIX files
set tags=
if filereadable('tags')
    let &tags = &tags . getcwd() . g:OS_dir_separator . 'tags'
endif
if $CTAGS_FILE !=# ''
    set tags+=$CTAGS_FILE
elseif $CTAGS_PREFIX !=# ''
    let s:prefix = $CTAGS_PREFIX
    let s:bre=0
    for s:i in range(10)
        for s:j in range(10)
            let s:prefixnr = s:prefix.s:i.s:j
            "echo prefixnr
            if filereadable(s:prefixnr)
                if &tags !=# ''
                    let &tags.=','
                endif
                let &tags.=s:prefixnr
                " add .added file always (it may not exist yet - it will be
                " created after update_tags - <F1>)
                "if filereadable(prefixnr . ".added")
                    let &tags = s:prefixnr . '.added' . ',' . &tags
                "endif
            else
                "echo "file ".prefixnr." not found!"
                let s:bre=1
                break
            endif
        endfor
        if s:bre == 1
            break
        endif
    endfor
endif

"Note: This fixes strange behavior of jumping between Vim help tags (it simply does
" not work, when tags is empty), adding fake . is enough to make it work
if &tags ==# ''
    set tags=.
endif

" ============================
" =       Netrw plug-in      =
" ============================
" let g:netrw_altv          = 1
" let g:netrw_fastbrowse    = 2
let g:netrw_keepdir       = 0  " solves the copy file problem
" let g:netrw_liststyle     = 2
" let g:netrw_retmap        = 1
" let g:netrw_silent        = 1
" let g:netrw_special_syntax= 1

" ============================
" =      Tagbar plug-in      =
" ============================
let g:tagbar_ctags_bin = g:OS_ctags_command
let g:tagbar_left = 1
let g:tagbar_autofocus = 1
let g:tagbar_ctags_max_size_in_bytes = 1024 * 1024  "maximum ammount of ctags, that we will load (to not slow down too much)
let g:tagbar_max_backward_scanned_lines_for_nearby_tag_search = 16 * 1024 "functions should be less than 16K lines (otherwise abort nearest tag search)

" ============================
" =      TagList plug-in     =
" ============================
let g:Tlist_Ctags_Cmd = g:OS_ctags_command
let g:Tlist_Show_Menu = 0  " there is a bug in gVim with taglist show menu turned on (E792: Empty menu name)

" === targets.vim ===
let g:targets_gracious = 1

" ============================
" =   Code_Complete plug-in   =
" ============================
"let g:disable_codecomplete = 1
"""let g:completekey ='<C-B>'

" === numbers.vim ===
"let g:loaded_numbers = 1

" === wildfire.vim ===
" Note: tag Vim objects (like it, at are very slow on big files without tags => use only on html,xml,...)
" Note: consider paragraph objects ip, ap
let g:wildfire_objects = {
    \ '*' : ["i'", 'i"', 'i)', 'i]', 'i}', 'ip'],
    \ 'html,xml' : ["i'", 'i"', 'i)', 'i]', 'i}', 'at', 'it'],
    \ }

" ============================
" =    Clearcase plug-in     =
" ============================
"let g:loaded_ccase = 0  " set to 1 to abort loading ccase.vim plug-in
let g:ccaseUseDialog = 0   " sets usage of windows input dialog

" ============================
" =    ifdef.vim plug-in     =
" ============================
let g:c_no_if0=1
let g:c_no_if0_fold=1 "maybe unnecessary
let g:c_no_comment_fold=1

" === CTRL-P ===
function! g:CTRLP_tagfiles()
    " default tags (almost 1GB) are too big for fuzzy matching (10 sec load + 1 sec after keypress seaarch)
    if $CSCOPE_FILES_DIR !=# ''
        return [$CSCOPE_FILES_DIR . '/ctrlp.tags']
    else
        return [$HOME . '/tmp/ctrlp.tags']
    endif
endfunction

let g:ctrlp_user_command = 'ctrlp_find.sh %s'
let g:ctrlp_use_caching = 0

let g:ctrlp_lazy_update = 250  " refresh search 250ms after user has stopped typing
let g:ctrlp_open_multiple_files = 'tjr'  "potentially add r (to open first in multi-selection in current window/tab)

"nmap <C-M> :CtrlPMRU<CR> "cannot be used, as <Enter> is <C-M>
let g:ctrlp_mruf_max = 50
command! Mru :CtrlPMRU
call g:CommandModeAbbreviation('mru', 'Mru', 0)
call g:CommandModeAbbreviation('MRU', 'Mru', 0)

let g:ctrlp_match_func = {'match': 'cpsm#CtrlPMatch'}

" start Ctrl-P in VCS root or cwd
let g:ctrlp_working_path_mode = 'ra'  "for SR/SRLINUX projects it is overriden later

"let g:ctrlp_types = ['fil', 'buf', 'mru']  "can only filter the three basic types
"let g:ctrlpswitcher_mode = 1
"let g:ctrlp_extensions = ['tag', 'buffertag', 'switcher']
let g:ctrlp_extensions = ['tag', 'buffertag']

" === vim-commentary ===
"<C-/> is the same key as <C-_> in terminals
"Xxx: insert mode mapping does not work
"Todo: solve readonly file warning, when commenting in RO file (first change)
let g:commentary_no_mappings = 1 "disable all mappings
let g:commentary_map_backslash = 0

"switch to // comments in c/ccp/yang files
if has('autocmd')
    autocmd! FileType c set commentstring=//%s
    autocmd! FileType cpp set commentstring=//%s
    autocmd! FileType yang set commentstring=//%s
    if v:version < 801 || (v:version == 801 && !has('patch864'))
        autocmd! FileType qf set noscrollbind | set scrolloff=0
        autocmd! BufEnter * if &ft != 'qf' | set scrolloff=5 | else | set scrolloff=0 | endif
    else
        " since 8.1.864 the scrolloff if global-local variable, hence it does not need to be reset on every BufEnter
        autocmd! FileType qf set noscrollbind | setlocal scrolloff=0
    endif
endif

" === vim-surround ===
let g:surround_no_insert_mappings = 1 "disable insert mode mappings (unnecessary ?)
let g:surround_no_mappings = 1 "disable all mappings

" === CSApprox ===
let g:CSApprox_loaded = 1  "use only for schemes conversion (:CSApproxSnapshot <exported filename> from Vim 7.3+ or gVim)

" === EasyMotion ===
"Note: to add/change bindings use the lazy loading section at the end of .vimrc
let g:EasyMotion_do_mapping = 0 " Disable default mappings

" Turn on case insensitive feature
let g:EasyMotion_smartcase = 1

"" JK motions: Line motions
"map <Leader>j <Plug>(easymotion-j)
"map <Leader>k <Plug>(easymotion-k)

"hi link EasyMotionTarget ErrorMsg
hi link EasyMotionTarget Type
hi link EasyMotionShade  Comment
hi link EasyMotionTarget2First MatchParen
hi link EasyMotionTarget2Second MatchParen
hi link EasyMotionMoveHL Search

" === Airline ===
let g:airline#extensions#whitespace#max_lines = 50000
let g:airline#extensions#wordcount#max_lines = 100000
let g:airline_exclude_preview = 1
let g:airline_detect_spelllang = 0
let g:airline_symbols_ascii = 1
let g:airline_symbols#linenr = 'ln'
let g:airline_symbols#maxlinenr = ''
"let g:airline#extensions#ycm#error_symbol = 'x' "'E:'
"let g:airline#extensions#ycm#warning_symbol = '⚠' "'W:'
"let g:airline#extensions#ale#error_symbol = 'x'
"let g:airline#extensions#ale#warning_symbol = '⚠'

let g:airline#extensions#ale#show_line_numbers = 0
let g:airline#extensions#languageclient#show_line_numbers = 0
"let g:airline#extensions#whitespace#enabled = 0
"let g:airline#extensions#tagbar#enabled = 0
let g:airline#extensions#branch#use_git_directly = 1

"""let g:airline_extensions = ['branch', 'hunks', 'wordcount', 'ctrlp', 'undotree', 'ale', 'quickfix', 'netrw']
"let g:airline_extensions = ['branch', 'hunks', 'wordcount', 'ctrlp', 'undotree', 'ale', 'quickfix', 'netrw', 'whitespace']
"let g:airline_extensions = ['branch', 'hunks', 'wordcount', 'ctrlp', 'undotree', 'ale', 'quickfix', 'netrw', 'tagbar']
"let g:airline_extensions = ['hunks', 'wordcount', 'ctrlp', 'undotree', 'ale', 'quickfix', 'netrw', 'tagbar']

" === vim-asterisk ===
let g:asterisk#keeppos = 1

" === vim-startify ===
let g:startify_files_number = 10
let g:startify_bookmarks = [
            \ { 'w': '~/.sr_workspaces' },
            \ ]
let g:startify_commands = [
    \ {'m': ['Open modified files in tabs', 'call vimrc#OpenGitModifiedFiles("tabs","modified","normal")']},
    \ {'M': ['Open branch diverged and modified files in tabs', 'call vimrc#OpenGitModifiedFiles("tabs","branch","normal")']},
    \ {'d': ['Open modified files in tabs and show diff', 'call vimrc#OpenGitModifiedFiles("tabs","modified","diff")']},
    \ {'D': ['Open branch diverged files in tabs and show diff', 'call vimrc#OpenGitModifiedFiles("tabs","branch","diff")']},
    \ ]

"let g:startify_change_to_vcs_root = 1
"let g:startify_session_persistence = 1
let g:startify_change_to_dir = 0
let g:startify_session_delete_buffers = 1
let g:startify_session_dir = '~/.vim/sessions'
let g:ctrlp_reuse_window = 'startify'
let g:startify_list_order = [
            \ [ 'MRU' ], 'files', [ 'Sessions' ], 'sessions', [ 'Bookmarks' ],
            \ 'bookmarks', [ 'Commands' ], 'commands'
            \ ]

let g:startify_session_sort = 0  "sort session list alphabetically

set sessionoptions-=blank

" disable startify and lsp highlighting in man pager mode
if $MAN_PN ==# '1'
    let g:startify_disable_at_vimenter = 1
    let g:lsp_cxx_hl_loaded = 1
endif
" improve default K mapping by removing the need to press enter after quit from keywordprg
" nmap <silent>K :<C-U>silent exec "normal! " . (v:count ? v:count : '') . "K"<CR>:redraw!<CR>
nmap <silent>K :<C-U>call vimrc#ShowManPage(v:count)<Enter>

" === vim-easy-align ===

" === vim-vinegar ===
"let g:netrw_keepj=''

" === vim-flog
let g:flog_use_ansi_esc = 1

" === context.vim
" without no redraw setting is the context.vim drawing super slow in neovim
" (was added to fix neovim rendering artifacts, but it is not usable)
let g:context_nvim_no_redraw = 1

" === asyncrun.vim
let g:asyncrun_bell = 1

" === vim-rtags ===
let g:rtagsUseLocationList = 0
let g:rtagsInsertModeCompletion = 0

" === pydoc.vim ===
let g:pydoc_cmd = 'python -m pydoc'
let g:pydoc_perform_mappings = 0

" === vim-ALE ===
" let g:loaded_ale_dont_use_this_in_other_plugins_please = 1
let g:ale_lint_on_text_changed = 'normal'  " disable with 'never' - see :help ALE
let g:ale_lint_delay = 200
let g:ale_lint_on_insert_leave = 1
let g:ale_lint_on_filetype_changed = 1
let g:ale_lint_on_enter = 1
let g:ale_lint_on_save = 1
let g:ale_sign_column_always = 0
let g:ale_sign_error = '=>'
let g:ale_sign_warning = '->'
let g:ale_sign_info = 'i>'
let g:ale_sign_style_error = '= '
let g:ale_sign_style_warning = '- '
let g:ale_statusline_format = ['x %d', '⚠ %d', '✓ ok']
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0
let g:ale_open_list = 1
"let g:ale_set_balloons=0  " set the global variable to disable balloons usage in ALE to fix non-working mouse in old KiTTY/PuTTY in Windows
"let g:ale_keep_list_window_open = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_emit_conflict_warnings = 0  "do not complain about syntastic
let g:ale_linters = {
    \   'c': ['compilation'],
    \   'ccp': ['ccplint'],
    \   'cfg': ['setupteardownchecker'],
    \   'cpp': ['compilation', 'cpplint'],
    \   'json': ['jq'],
    \   'mail': ['grammarcheck'],
    \   'mib': ['mibcomp'],
    \   'perl': ['perl'],
    \   'proto': ['protoc'],
    \   'python': ['python', 'flake8'],
    \   'rst': [],
    \   'sh': ['shell', 'shellcheck'],
    \   'tcl': [],
    \   'vim': ['vint'],
    \   'yaml': ['fflagsyamllinter'],
    \   'yang': ['pyang'],
    \}

  let g:ale_fixers = {
    \   'c': ['clang-format'],
    \   'cpp': ['clang-format'],
    \   'python': ['autopep8', 'isort'],
    \}

" let g:c_clangformat_options = ''  " clang-format should get its per project setting from init file, so no need to do it here

let g:ale_pedantic_linting = 0  "can be controlled via <Leader>P
let g:ale_compilation_linting = 0  "can be controlled via <Leader>L

let g:ale_python_flake8_use_global = 1  "CAUTION: without this every execution of flake8 linter would traverse disk to find parent python environment (this causes huge slowdowns)
let g:ale_python_flake8_executable = 'flake8_linter.sh'
let g:ale_python_pylint_options = '--disable=C0111 --max-line-length=120'
let g:ale_vim_vint_executable = 'vint_linter.sh'
let g:ale_cmake_cmakelint_options = '--filter=-linelength'

let g:ale_c_compilation_base_flags = '--c --g'
let g:ale_cpp_compilation_base_flags = '--c++ --g++'
let g:ale_c_compilation_base_simple_flags = '--c'  "clang only
let g:ale_cpp_compilation_base_simple_flags = '--c++'  "clang only

" see output from pyang --list-errors (grep LEAFREF and UNUSED_IMPORT; import is reported in srlinux)
let g:ale_yang_pyang_args = '
            \ --ignore-error=LEAFREF_BAD_PREDICATE
            \ --ignore-error=LEAFREF_BAD_PREDICATE_PTR
            \ --ignore-error=LEAFREF_MULTIPLE_KEYS
            \ --ignore-error=LEAFREF_DEREF_NOT_LEAFREF
            \ --ignore-error=LEAFREF_NOT_LEAF
            \ --ignore-error=LEAFREF_TOO_MANY_UP
            \ --ignore-error=LEAFREF_BAD_CONFIG
            \ --ignore-error=LEAFREF_DEREF_NOT_KEY
            \ --ignore-error=LEAFREF_IDENTIFIER_BAD_NODE
            \ --ignore-error=LEAFREF_IDENTIFIER_NOT_FOUND
            \ --ignore-error=LEAFREF_NO_KEY
            \ --ignore-error=UNUSED_IMPORT
            \'

" set highlighting groups for ALE
call g:ResetALEHighlightGroups()

" next section fixes the bug with preview window messing with buffer highlights after closing it with dedicated function pclose or <C-W>z
command! -nargs=* -complete=file PClose wincmd P | wincmd q <args>
call g:CommandModeAbbreviation('pclose', 'PClose', 0)
nmap <C-W>z :PClose<Enter>
vmap <C-W>z <Esc>:PClose<Enter>gv

function! g:ALELintingStatusUpdate()
    "if exists(':SignifyRefresh') == 2
    "    "messes with visual selection (maybe not needed anymore, after vim-signify upgrade ?)
    "    execute 'SignifyRefresh'
    "endif
    if exists(':AirlineRefresh') == 2
        " unsilent echomsg reltimestr(reltime())
        execute 'AirlineRefresh'
    endif
endfunction

augroup ALEGroup
    autocmd!
    autocmd User ALEJobStarted call g:ALELintingStatusUpdate()
    autocmd User ALELintPost call g:ALELintingStatusUpdate()
    autocmd User ALEListClose call g:ALELintingStatusUpdate()
augroup END

" used in cscope_maps.vim plugin
function! g:Move_to_column_with_match(str)
    let l:saved_cursor = getcurpos()
    " echomsg "saved_cursor: " . saved_cursor[1] . ":" . saved_cursor[2]
    call cursor(l:saved_cursor[1], 1)
    " echomsg "searched str : " . a:str
    "turn on ignore case search \\c
    let l:found_line = search(a:str . "\\c", 'cWz')
    " echomsg "found line : " . l:found_line
    if l:found_line == l:saved_cursor[1]
        "nothing to do - match inside current line was found (cursor should be
        "at the start of the match
    else
        "no match inside line - go back to previous position
        call setpos('.', l:saved_cursor)
    endif
endfunction

" ==========================
" = Miscellaneous functions=
" ==========================
command! -nargs=? -complete=dir GenCTags :call vimrc#GenCTags(<f-args>)
command! -nargs=? -complete=dir GenTags :call vimrc#GenTags(<f-args>)

command! -range=% FormatXML <line1>,<line2>call vimrc#DoFormatXML()

"command! -bar -nargs=0 -range=% TrimSpaces <line1>,<line2>call TrimSpaces()
command! -range=% TrimSpaces <line1>,<line2>call vimrc#TrimSpaces("")
command! -range=% TrimSpacesConfirm <line1>,<line2>call vimrc#TrimSpaces("c")
nnoremap <Leader><Space> m`:%TrimSpacesConfirm<CR>
vnoremap <Leader><Space> :TrimSpaces<CR>

command! -nargs=1 -complete=buffer WinGo call vimrc#WinGo(<q-args>)

nnoremap <Leader>b :call git_misc#BetterBlame()<CR>

" ================
" = Experimental =
" ================
"backup to ~/.vim/
let g:user_backup_home = g:home_vim_folder . g:OS_dir_separator . 'backup'
if isdirectory(g:user_backup_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_backup_home
endif
let g:user_swap_home = g:home_vim_folder . g:OS_dir_separator . 'swap'
if isdirectory(g:user_swap_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_swap_home
endif
if has('nvim')
    let g:user_undo_home = g:home_vim_folder . g:OS_dir_separator . 'undonvim'
else
    let g:user_undo_home = g:home_vim_folder . g:OS_dir_separator . 'undo'
endif
if isdirectory(g:user_undo_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_undo_home
endif
"set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
"set backupskip=/tmp/*,/private/tmp/*
"set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

"TODO: improve with noundofile for specific files (like /tmp/* files)
"autocmd! BufWritePre /tmp/* setlocal noundofile

"double trailing slash instructs Vim to encode path into the filename using '%' as separators
let &backupdir=g:user_backup_home . g:OS_dir_separator . g:OS_dir_separator

let &directory=g:user_swap_home . g:OS_dir_separator . g:OS_dir_separator
set backup
set writebackup
if has('persistent_undo')
    let &undodir=g:user_undo_home . g:OS_dir_separator . g:OS_dir_separator
    set undofile
    set undolevels=1000
endif

if has('clipboard')
    if has('unnamedplus')
        set clipboard=unnamed,unnamedplus
    else
        set clipboard=unnamed
    endif
    "Note: in vim 7.3.74 and higher you can set clipboard=unnamedplus to alias unnamed register to the + register, which is the X Window clipboard.
    "
    "If having problems in X11, than install autocutsel-0.10.0.tar.gz package to
    "sync X11 clipboards between each other
    "
    "
    "Todo: add exclude pattern, when running with X forwarding through slow
    "connection
    "e.g set clipboard=autoselect,exclude:cons\\\|linux\\\|screen
    "    set clipboard=autoselect,exclude:.*
    "Warning: following line causes big problems with syntax highlighting and even crashed Vim on opening of Perl files (*.pl)
    "Note: should disable X-clipboard on slow connections (because Vim can
    " otherwise delay start for few seconds, by contacting X-server first and
    " only then starting
    "set clipboard+=exclude:.*
endif

" Copy text by sending string to the terminal clipboard using the OSC 52
" escape sequence, as specified in
" http://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h2-Operating-System-Commands,
" section 'Operating System Commands', Ps => 52.
"
" OSC stands for 'Operating System Commands'. (\x1b], <esc>])
" ST stands for 'String terminator'. (<esc>\)
"
" Format: \e]52;Pc;Pd\e\\
"
" \e]52; -> identifies this as a clipboard operation
" Pc       -> selection parameters for clipboard (it can be empty)
" Pd       -> selection data encoded in base64
" \e\\   -> string terminator
"
" References:
" - http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
" - https://chromium.googlesource.com/chromiumos/platform/assets/+/factory-3004.B/chromeapps/hterm/doc/faq.txt
" - https://chromium.googlesource.com/apps/libapps/+/HEAD/hterm/etc/osc52.sh
" - http://qiita.com/kefir_/items/515ed5264fce40dec522
" - https://www.iterm2.com/documentation-escape-codes.html
" - https://sunaku.github.io/tmux-yank-osc52.html
function! g:CopyUsingOsc52(text) abort
    let l:max_len = 567
    let l:len = strlen(a:text)
    if l:len > l:max_len
        let l:infomsg = 'Previously yanked text length is ' . l:len . ' characters (maximum allowed is ' . l:max_len . ')'
        echohl WarningMsg
        echomsg l:infomsg
        echohl None
        return
    endif
  let l:sequence = s:_osc52_sequence(a:text)
  silent call system(printf("printf '%s' > /dev/tty", l:sequence))
  redraw!
    let l:infomsg = 'Copied previously yanked text to system clipboard (' . l:len . ' characters)'
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction

function! s:_osc52_sequence(text) abort
  " let l:b64 = system('base64 -w0', a:text)
  let l:b64 = base64#Encode(a:text)
  " if s:in_tmux
  "   return printf("\ePtmux;\e\e]52;;%s\e\e\\\e\\", l:b64)
  " elseif s:in_screen
  "   return printf("\eP\e]52;;%s]\x07\e\\", l:b64)
  " else
  "   return printf("\e]52;;%s\e\\", l:b64)
  " endif
  " TODO(akocis): check with Tmux - if this works or the commented out variant is correct
  return s:ScreenEscape('\e]52;;' . l:b64 . '\x07')
endfunction

nnoremap \y :call g:CopyUsingOsc52(@0)<CR>

if has('mouse_sgr')
    " do not set ttymouse when using linux console directly (with gpm daemon for mouse support)
    if &term !=# 'linux'
        set ttymouse=sgr
    endif
else
    "if we have old vim or vim without mouse_sgr compiled, its better to not touch ttymouse setting
    "set ttymouse=xterm2
end

nmap <silent><C-]> :call vimrc#SophTag('', 'tag')<Enter>
imap <silent><C-]> <C-o>:call vimrc#SophTag('', 'tag')<Enter>
vmap <silent><C-]> <Esc>:call vimrc#SophTag(g:GetVisualSelection(), 'tag')<Enter>gv
nmap <silent>g<C-]> :call vimrc#SophTag('', 'tjump')<Enter>
vmap <silent>g<C-]> <Esc>:call vimrc#SophTag(g:GetVisualSelection(), 'tjump')<Enter>gv

nnoremap <silent>g<LeftMouse> <LeftMouse>:call vimrc#CscopeCtagsSearch("")<CR>
nnoremap <silent>g<RightMouse> <C-T>
nmap <C-LeftMouse> g<LeftMouse>
nmap <C-RightMouse> g<RightMouse>

nnoremap <X1Mouse> <C-O>
nnoremap <X2Mouse> <C-I>
nmap <RightMouse><LeftMouse> <X1Mouse>
"nmap <LeftMouse><RightMouse> <X2Mouse> "causes delay, when selecting text by dragging with LeftMouse pressed

"automatic copy after left button release (not sure about usefulness)
"vnoremap <LeftRelease> <LeftRelease>y

" moving through cscope/ctags
nnoremap <silent><C-S-Right> :call vimrc#CscopeCtagsSearch(expand("<cword>"))<Enter>
nnoremap <silent><C-S-Left> <C-T>
inoremap <silent><C-S-Right> <C-o>:call vimrc#CscopeCtagsSearch(expand("<cword>"))<Enter>
inoremap <silent><C-S-Left> <C-o><C-T>
vnoremap <silent><C-S-Right> <Esc>:call vimrc#CscopeCtagsSearch(g:GetVisualSelection())<Enter>
vnoremap <silent><C-S-Left> <Esc><C-T><Enter>


" when .vimrc is edited, reload it
if has('autocmd')
    execute 'autocmd! BufWritePost ' . g:OS_vimrc . ' source %'
endif

" autoclose last open location/quickfix/help windows on a tab
if has('autocmd')
    augroup AutoCloseAllQF
        autocmd!
        "autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" | q | endif
        autocmd WinEnter * nested call vimrc#QuitIfOnlyWindow()
    augroup END
endif

"Todo: check Vim startup time via: vim --startuptime /tmp/startup.txt
"Note: specific script exec profiling: vim --cmd 'profile start vimrc.profile' --cmd 'profile! file ~/.vimrc'
"Note: when running from within started vim: profile start vimrc.profile | profile! file ~/.vimrc | source ~/.vimrc
"Note: even better startup profiling:
" vim --cmd 'profile start profile.log' --cmd 'profile func *' --cmd 'profile file *' -c 'profdel func *' -c 'profdel file *' -c 'qa!'
"Note: to turn verbose for specific command only
"    :redir @a | 20verbose exec 'normal D' | redir END
"    :tabe
"    "ap
nnoremap <silent> <leader>DD :exe ":profile start profile.log"<cr>:exe ":profile func *"<cr>:exe ":profile file *"<cr>
nnoremap <silent> <leader>DP :exe ":profile pause"<cr>
nnoremap <silent> <leader>DC :exe ":profile continue"<cr>
nnoremap <silent> <leader>DQ :exe ":profile pause"<cr>:noautocmd qall!<cr>

""-----BEGIN-BENCHMARK--------------------
"let start = reltime()
"for i in range(1000000)
"endfor
"let time_vim = reltimestr(reltime(start))
"
"let start = reltime()
"python << EOF
"for i in range(1000000): pass
"EOF
"let time_py = reltimestr(reltime(start))
"
"echo 'Vim:   ' time_vim
"echo 'Python:' time_py
""-----END--------------------------------

" Todo: rewrite to register version - captures more output (e.g. redir @a | silent <args> | redir END)
command! -nargs=+ BufOut redir! => bufout | silent <args> | redir END | new | call append(0, split(bufout, '\n'))

" clipoard copy and paste functions
"Todo: only when xsel is installed (perhaps distribute with vi ?)
command! -range Cz :silent :<line1>,<line2>w !xsel -i -b
command! -range Cx :silent :<line1>,<line2>w !xsel -i -p
command! -range Cv :silent :<line1>,<line2>w !xsel -i -s
call g:CommandModeAbbreviation('cz', 'Cz', 0)
call g:CommandModeAbbreviation('cx', 'Cx', 0)
call g:CommandModeAbbreviation('cv', 'Cv', 0)

command! -range Pz :silent :r !xsel -o -b
command! -range Px :silent :r !xsel -o -p
command! -range Pv :silent :r !xsel -o -s
call g:CommandModeAbbreviation('pz', 'Pz', 0)
call g:CommandModeAbbreviation('px', 'Px', 0)
call g:CommandModeAbbreviation('pv', 'Pv', 0)

command! Wipeout :call vimrc#Wipeout()
call g:CommandModeAbbreviation('wipeout', 'Wipeout', 0)

command! XReconnect :call vimrc#XReconnect()
call g:CommandModeAbbreviation('xreconnect', 'XReconnect', 0)

command! DiffOrig :call vimrc#DiffOrig()

command! Matrix :call vimrc#Matrix()

command! RefreshAll :call vimrc#RefreshAll()
call g:CommandModeAbbreviation('refreshall', 'RefreshAll', 0)
noremap <Leader><C-L> :call vimrc#RefreshAll()<CR>

command! -nargs=+ -complete=file LoadCrashBacktrace :call vimrc#LoadCrashBacktrace(<f-args>)
call g:CommandModeAbbreviation('loadcrashbacktrace', 'LoadCrashBacktrace', 0)

command! -nargs=* -complete=file LoadBuildErrors :call vimrc#LoadBuildErrors(<f-args>)
call g:CommandModeAbbreviation('loadbuilderrors', 'LoadBuildErrors', 0)

command! -nargs=+ -complete=shellcmd RunBackgroundCommand call vimrc#RunBackgroundCommand(<q-args>)

command! Clang :call vimrc#Clang()
call g:CommandModeAbbreviation('clang', 'Clang', 0)

command! Gcc :call vimrc#Gcc()
call g:CommandModeAbbreviation('gcc', 'Gcc', 0)

call g:CommandModeAbbreviation('rg', 'Rg', 1)
call g:CommandModeAbbreviation('rgf', 'RgFolder', 1)
call g:CommandModeAbbreviation('rgm', 'RgModule', 1)

" TODO(akocis): finish integrating with FZF
" command! -bang Colors
"             \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

let g:fzf_command_prefix = 'Fzf'

command! -bang -nargs=* Ripgrep
            \ call fzf#vim#grep(
            \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
            \   <bang>0 ? fzf#vim#with_preview('up:60%')
            \           : fzf#vim#with_preview('right:50%:hidden', '?'),
            \   <bang>0)


" clang/llvm based tools
nmap <silent><F4> :call vimrc#ExpandCMacroAsync()<Enter>
imap <silent><F4> <C-o>:call vimrc#ExpandCMacroAsync()<Enter>
vmap <silent><F4> <Esc>:call vimrc#ExpandCMacroAsync()<Enter>gv

let g:clang_format_executable = 'clang-format'
let g:clang_format_code_style = 'Google'
let g:clang_format_style_options = {
            \ 'AccessModifierOffset' : '-2',
            \ 'BreakBeforeBraces' : 'Allman',
            \ 'ColumnLimit' : '120',
            \ 'AllowShortIfStatementsOnASingleLine' : 'false',
            \ 'AllowShortLoopsOnASingleLine' : 'false',
            \ 'AllowShortFunctionsOnASingleLine' : 'false',
            \ }

" see below the clang format autocmd

nmap <Leader>R :call vimrc#CodeRenameSymbolAtCursor()<CR>
nmap <Leader>i :call vimrc#CodeIncludeSymbolAtCursor('n')<CR>
vmap <Leader>i <Esc>:call vimrc#CodeIncludeSymbolAtCursor('v')<CR>gv
nmap <Leader>? :ALEDetail<cr>
nmap <Leader>P :call vimrc#TogglePedanticLinting()<cr>
nmap <Leader>L :call vimrc#ToggleGlobalLinting()<cr>

if has('autocmd')
    autocmd FileType c,cpp call g:SetupCppFunctionJumps()
endif

" === VCSCommands.vim ===
" for startup speed reasons disable non-existing versioning systems (otherwise
" the plugin searches whole $PATH for executable - this can take around 60ms)
" Todo: can be now removed due to lazy loading
let g:VCSCommandBZRExec = ''
let g:VCSCommandHGExec = ''
let g:VCSCommandSVKExec = ''
let g:VCSCommandSVNExec = ''

" disable all ,c<XYZ> mappings
let g:VCSCommandDisableMappings = 1
let g:VCSCommandDisableExtensionMappings = 1

let g:VCSCommandVCSTypePreference = 'git'
let g:VCSCommandEnableBufferSetup = 1

command! ConflictsResolve :call conflicts#ConflictsResolve()
call g:CommandModeAbbreviation('conflictsresolve', 'ConflictsResolve', 0)
command! ConflictsDiff :call conflicts#ChangeTo2WayDiffMode()
command! ConflictsShow3WayTab :call conflicts#ShowInvolvedFilesIn3WayDiffNewTab()
command! ConflictsShow2WayTabs :call conflicts#ShowInvolvedFilesIn2WayDiffNewTabs()
" Todo: Add ConflictsTakeLocal, ConflictsTakeRemote to replace output with local, remote version completely

" =========================================
" = Project/Versioning system integration =
" =========================================
" guess used versioning system and project based on environment variables/directories
let g:VCS_name=''
let g:PROJECT_name=''
if $PANOS !=# ''
    let g:VCS_name='cvs'
    let g:PROJECT_name='SR'
elseif $CLEARCASE_ROOT !=# ''
    let g:VCS_name='clearcase'
    let g:PROJECT_name='SGSN'
elseif $LSF_BINDIR !=# ''
    let g:VCS_name='ecms'
    let g:PROJECT_name='WMM'
elseif $SRLINUX !=# ''
    let g:VCS_name='srlinux'
    let g:PROJECT_name='SRLINUX'
endif

let s:viminfo_filename = '.viminfo'
if has('nvim')
    let s:viminfo_filename = '.nviminfo'
endif

" source .vimrc_local if present
let s:localrc = $HOME . g:OS_dir_separator . '.vimrc_local'
if filereadable(s:localrc)
    execute 'source ' . s:localrc
endif

call lsp_clients#init()

if g:PROJECT_name ==# 'SR'
    let s:project_specific_path = $PANOS . ',' . $GEN_PATH

    " tabs are forbidden in SR projects
    set expandtab

    "per project .viminfo
    let g:viminfo_project_dir = $PANOS . g:OS_dir_separator . '..' . g:OS_dir_separator . 'conf' . g:OS_dir_separator
    if isdirectory(g:viminfo_project_dir)
        execute 'set viminfo+=n' . g:viminfo_project_dir . s:viminfo_filename
    endif

    " start Ctrl-P in $PANOS folder
    let g:ctrlp_working_path_mode = 'pra'

    " YCM does a few transformations with these args (expects single dash
    " ~/.vim/pack/vundle/opt/YouCompleteMe/third_party/ycmd/ycmd/completers/cpp/clangd_completer.py
    let g:ycm_clangd_args = [
                \ '-log=verbose',
                \ '--pretty',
                \ '--compile-commands-dir=' . $CSCOPE_FILES_DIR . '/rtags',
                \ '--fallback-style=Microsoft',
                \ '--background-index',
                \ '--completion-style=bundled',
                \ '--header-insertion=iwyu',
                \ '-header-insertion-decorators',
                \ '--clang-tidy',
                \ '-j=2']
                " \ '--all-scopes-completion',
                " \ '--fallback-style="{BasedOnStyle: Microsoft, IndentWidth: 4}"',
                " \ '--suggest-missing-includes',  " obsolete (ignored)
                " \ '--clang-tidy-checks="*"',  " obsolete (ignored)

    nmap <silent><F1> :call vimrc#ConfirmRefreshTagsAsync("update")<CR>
    " imap <silent><F1> <C-o>:call vimrc#RefreshTagsAsync("update")<CR>
    " vmap <silent><F1> <Esc>:call vimrc#RefreshTagsAsync("update")<CR>gv

    " TODO AKO should iterate over all local buffers and run refresh l:enc (maybe use :bufdo ?)
    " (otherwise other windows will not have spell check enabled)
    " nmap <silent><S-F1> :call vimrc#RefreshTagsAsync("mibupdate")<CR>
    " imap <silent><S-F1> <C-o>:call vimrc#RefreshTagsAsync("mibupdate")<CR>
    " vmap <silent><S-F1> <Esc>:call vimrc#RefreshTagsAsync("mibupdate")<CR>gv

    " enable LSP client(s), by default all are disabled
    if v:version >= 800
        if g:ycm_use_clangd == 1
            " any other lsp to enable when clangd is enabled for YCM ?
            " TODO(akocis): enable pyls and others, but skip ccls (because we have clangd already)
        elseif g:use_lsp == 1
            " unlet g:lsp_loaded
            " unlet g:loaded_lsc

            " unlet g:languageclient_loaded
            " unlet g:ale_lsp_loaded

            unlet g:did_coc_loaded
        endif
    endif
elseif g:PROJECT_name ==# 'SRLINUX'
    let s:base_c_paths = '/usr/include,/opt/rh/devtoolset-7/root/usr/lib/gcc/x86_64-redhat-linux/7/include'
    let s:base_cpp_paths = '/opt/rh/devtoolset-7/root/usr/include/c++/7,/opt/rh/devtoolset-7/root/usr/include/c++/7/x86_64-redhat-linux'
    let s:base_srlinux_path = $SRLINUX . ',' . $GEN_PATH . g:OS_dir_separator . 'include'
    let s:base_srlinux_path .= ',' . $GEN_PATH . g:OS_dir_separator . 'protos' . ',' . $GEN_PATH . g:OS_dir_separator . 'sdk/service'
    let s:base_srlinux_path .= ',' . $GEN_PATH . g:OS_dir_separator . 'aaamgr'
    let s:base_srlinux_path .= ',' . $SRLINUX . g:OS_dir_separator . 'panos'
    let s:extra_packages_path = '/opt/srlinux/usr/include/'
    let s:project_specific_path = s:base_c_paths . ',' . s:base_cpp_paths . ',' . s:extra_packages_path . ',' . s:base_srlinux_path

    " tabs are forbidden in SR projects
    set expandtab

    "per project .viminfo
    let g:viminfo_project_dir = $SRLINUX . g:OS_dir_separator . '..' . g:OS_dir_separator . 'conf' . g:OS_dir_separator
    if isdirectory(g:viminfo_project_dir)
        execute 'set viminfo+=n' . g:viminfo_project_dir . s:viminfo_filename
    endif

    " start Ctrl-P in $SRLINUX folder
    let g:ctrlp_working_path_mode = 'pra'

    " let g:ycm_clangd_args = ['-log=verbose', '-pretty', '-compile-commands-dir=' . $GEN_PATH]
    " let g:ycm_clangd_args = ['-log=verbose', '-pretty', '-compile-commands-dir=' . $SRLINUX]
    let g:ycm_clangd_args = ['-log=verbose', '-pretty', '-compile-commands-dir=' . $SRLINUX . g:OS_dir_separator . '.clangd']

    """ nmap <silent><F1> :call vimrc#RefreshTagsAsync("update")<CR>
    """ imap <silent><F1> <C-o>:call vimrc#RefreshTagsAsync("update")<CR>
    """ vmap <silent><F1> <Esc>:call vimrc#RefreshTagsAsync("update")<CR>gv

    """ " TODO AKO should iterate over all local buffers and run refresh l:enc (maybe use :bufdo ?)
    """ " (otherwise other windows will not have spell check enabled)
    """ nmap <silent><S-F1> :call vimrc#RefreshTagsAsync("mibupdate")<CR>
    """ imap <silent><S-F1> <C-o>:call vimrc#RefreshTagsAsync("mibupdate")<CR>
    """ vmap <silent><S-F1> <Esc>:call vimrc#RefreshTagsAsync("mibupdate")<CR>gv

    """ nnoremap <silent><C-S-Right> :if rtags#IsRdmRunning() \| call rtags#JumpTo(g:SAME_WINDOW) \| else \| call vimrc#CscopeCtagsSearch("<cword>") \| endif<CR>
    """ nnoremap <silent><C-S-Left> :if rtags#IsRdmRunning() \| call rtags#JumpBack() \| else \| execute "normal! <C-T>" \| endif<CR>
    """ nnoremap <silent>g<LeftMouse> <LeftMouse>:if rtags#IsRdmRunning() \| call rtags#JumpTo(g:SAME_WINDOW) \| else \| call vimrc#CscopeCtagsSearch("<cword>") \| endif<CR>
    """ nnoremap <silent>g<RightMouse> :if rtags#IsRdmRunning() \| call rtags#JumpBack() \| else \| execute "normal! <C-T>" \| endif<CR>
    if v:version >= 801
        command! -nargs=* -complete=file DebugStartBreakHere :call vimrc#StartGdbDebugger(<f-args>)
        call g:CommandModeAbbreviation('debugstartbreakhere', 'DebugStartBreakHere', 0)
    endif

    " add python unit test output format to errorformat:

    " Traceback (most recent call last):
    "   File "/home/akocis/ws/srlinux/python/srlinux/mgmt/cli/plugins/test/test_annotate.py", line 48, in test__can_annotate_nodes
    "     self.expect_annotations('/node', ['text2'])
    "   File "/home/akocis/ws/srlinux/python/srlinux/mgmt/cli/plugins/test/test_annotate.py", line 35, in expect_annotations
    "     self.assertEqual(expected, self.get_annotations(path_string))
    set errorformat^=%*\\sFile\ %*[\"]%f%*[\"]\\,\ line\ %l\\,\ %m,%Z%*\\s%m

    " enable LSP client(s), by default all are disabled
    if v:version >= 800
        if g:ycm_use_clangd == 1
            " any other lsp to enable when clangd is enabled for YCM ?
            " TODO(akocis): enable pyls and others, but skip ccls (because we have clangd already)
        else
            unlet g:languageclient_loaded
            unlet g:ale_lsp_loaded
        endif
    endif
else " other projects
    let s:project_specific_path = g:OS_system_includes_dir . ',' . '**,../include/**,../src/**'

    " F1 to display help
    nmap <silent><F1> :call vimrc#SophHelp()<Enter>
    imap <silent><F1> <C-o>:call vimrc#SophHelp()<Enter>
    vmap <silent><F1> <Esc>:call vimrc#SophHelp()<Enter>gv
endif

" set reasonable default path (used for various commands like :find, include/tag searches, ...)
let g:default_search_path = substitute('./**,' . s:project_specific_path, '[\/]', g:OS_dir_separator, 'g')
let &path=g:default_search_path
"set suffixesadd=.h

""" "Todo: move somewhere else
""" "no versioning system (will be overriden by VCS bindings later)
""" nmap <silent><F5> :DiffOrig<Enter>
""" imap <silent><F5> <C-o>:DiffOrig<Enter>
""" vmap <silent><F5> <Esc>:DiffOrig<Enter>gv

call lsp_clients#start()

" clangd usage in YCM overrides
" use clangd for diagnostics (does it after every keypress - super slow in big 2MB files!
let g:ycm_show_diagnostics_ui = g:ycm_use_clangd
let g:airline#extensions#ycm#enabled = g:ycm_show_diagnostics_ui  "this is even by default, when it does not find :YcmDiags function

if g:ycm_show_diagnostics_ui == 1
    let g:ale_linters['c'] = []
    let g:ale_linters['cpp'] = ['cpplint']
endif

if exists('g:toggle_cursor_auto_detect_paste_mode') && g:toggle_cursor_auto_detect_paste_mode == 1
    " auto detect paste mode if on, nothing to be done here
else
    " auto detect paste mode if off, revert to the old F7 paste toggle
    set pastetoggle=<F7>
endif

if has('gui_running')
    call gui#GuiOptions()
endif

" lazily load all packages/plugins
if exists(':packadd') == 2
    packadd! lazyloader
else
    " for Vim versions < 8 setup runtimepath with pack/*/{start,opt}/* folders
    call oldvim#LoadPlugins()
endif
