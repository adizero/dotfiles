if &compatible | set nocompatible | endif " Avoid side effects if `nocp` already set
scriptencoding utf-8

"Xxx: this needs .term_detect script support in shell
let s:term_program=expand('$TERM_PROGRAM')
let s:term_version=expand('$TERM_VERSION')
if s:term_version ==# '$TERM_VERSION'
    let s:term_version = 0
endif
if s:term_program ==# 'lxterminal' || s:term_program ==# 'gnome-terminal' ||
            \ s:term_program ==# 'xterm' || s:term_program ==# 'Konsole' ||
            \ s:term_program ==# 'PuTTY' || s:term_program ==# 'Cygwin'
    let &term = 'xterm'
elseif s:term_program ==# 'rxvt' || s:term_program ==# 'urxvt'
    let &term = 'rxvt'
else
    "Todo: this is a hack for screen-bce/screen.rxvt to behave as xterm/rxvt in Vim
    if &term ==# 'screen-bce' || &term ==# 'screen'
        if expand('$STY') ==# '$STY'
            "ssh to devpc from inside of a screen (let's fake STY)
            let $STY = '0.dev'
        endif
        let &term = 'xterm'
    elseif &term ==# 'screen.rxvt'
        let &term = 'rxvt'
    elseif &term =~# 'rxvt'  "for urxvt and 256 color variants
        let &term = 'rxvt'
    endif
endif

command! -nargs=1 Silent
            \ | execute ':silent !'.<q-args>
            \ | execute ':redraw!'

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
else
    "if SHELL env variable is set incorrectly and VIM cannot start shell, then
    "  uncomment following line, that overrides SHELL env variable
    "set shell=/bin/sh

    let g:OS_name=system('uname -s')

    let g:OS_dir_separator = '/'
    let g:OS_cat_command = 'cat'
    let g:OS_mkdir_command = 'mkdir -p'
    let g:OS_ctags_command = 'ctags'
    let g:OS_system_includes_dir = '/usr/include'

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

            set t_Co=256 "override terminfo setting to enable 256 colors
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
            if s:term_program ==# 'lxterminal' || s:term_program ==# 'gnome-terminal' ||
                        \ s:term_program ==# 'xterm' && (s:term_version < 278 && s:term_version != 95)
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

        "bold should work by default (see your terminal emulator setting for "picking drawing bold as a color/bold as a font or both)
        "works seamlessly from inside screen
        "let &t_md = "\e[1m"
        "let &t_me = "\e[m"

        "underline should work by default
        "works seamlessly from inside screen
        "let &t_us = "\e[4m"
        "let &t_ue = "\e[m"

        "undercurl as strikethrough (needs terminal support - no KiTTY/PuTTY does strikethrough):
        if v:version > 704 || (v:version == 704 && has('patch911'))
            if expand('$STY') !=# '$STY'
                let &t_Cs = "\eP\e[9m\e\\"
                let &t_Ce = "\eP\e[29m\e\\"
            else
                let &t_Cs = "\e[9m"
                let &t_Ce = "\e[29m"
            endif
        endif

        "reverse/inverse should work by default
        "works seamlessly from inside screen
        "let &t_mr = "\e[7m"

        "italic (italics is already enabled in wombat256 colorscheme)
        "needs escaping from screen
        if expand('$STY') !=# '$STY'
            let &t_ZH = "\eP\e[3m\e\\"
            let &t_ZR = "\eP\e[23m\e\\"
        else
            let &t_ZH = "\e[3m"
            let &t_ZR = "\e[23m"
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
        "if expand("$STY") != "$STY"
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
hi clear

"check vundle installation, if installed, then make use of it
let g:vundle_readme=expand('~/.vim/bundle/Vundle.vim/README.md')
if v:version >= 702 && filereadable(g:vundle_readme)
"---VUNDLE---
    filetype off                  " required
    "set the runtime path to include Vundle and initialize
    set runtimepath+=~/.vim/bundle/Vundle.vim
    exe ':call vundle#begin()'
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')

    " let Vundle manage Vundle, required
    Plugin 'gmarik/Vundle.vim'

    "Plugin 'scrooloose/syntastic'
    Plugin 'w0rp/ale'

    "Plugin 'vim-scripts/OmniCppComplete'  "too slow - fully replaced with YouCompleteMe
    Plugin 'Valloric/YouCompleteMe'
    Plugin 'starcraftman/vim-eclim'
    Plugin 'terryma/vim-multiple-cursors'
    Plugin 'easymotion/vim-easymotion'

    Plugin 'ctrlpvim/ctrlp.vim'  "kien/ctrlp.vim is no longer maintained
    Plugin 'nixprime/cpsm'  "very fast c based fuzzy matcher to replace ctrlp's slow default
    Plugin 'jasoncodes/ctrlp-modified.vim'
    "Plugin 'ivan-cukic/vim-ctrlp-switcher'

    Plugin 'adizero/vim-togglecursor'
    "Plugin 'adizero/vim-clang-format'  "no longer needed - better implementation in function Code
    Plugin 'adizero/cscope_maps.vim'

    Plugin 'vim-scripts/vcscommand.vim'
    Plugin 'mikeage/ccase.vim'
    "Plugin 'chrisbra/vim-diff-enhanced'

    Plugin 'benjifisher/matchit.zip'
    "Plugin 'Firef0x/matchit'

    Plugin 'vim-scripts/diffchar.vim'
    Plugin 'AndrewRadev/linediff.vim'
    "Plugin 'AndrewRadev/splitjoin.vim'

    Plugin 'tpope/vim-surround'
    Plugin 'tpope/vim-abolish'
    Plugin 'tpope/vim-repeat'
    Plugin 'tpope/vim-unimpaired'
    Plugin 'tpope/vim-fugitive'
    Plugin 'tpope/vim-vinegar'
    "Plugin 'tpope/vim-commentary'
    Plugin 'wilywampa/vim-commentary'

    Plugin 'vim-scripts/QuickFixCurrentNumber'

    Plugin 'mhinz/vim-signify'

    Plugin 'vim-airline/vim-airline'
    Plugin 'vim-airline/vim-airline-themes'

    Plugin 'myusuf3/numbers.vim'

    "Plugin 'cohama/lexima.vim'
    "Plugin 'rstacruz/vim-closer'

    Plugin 'wellle/targets.vim'

    Plugin 'haya14busa/vim-asterisk'

    Plugin 'junegunn/vim-easy-align'

    "Plugin 't9md/vim-textmanip'
    "Plugin 'stefandtw/quickfix-reflector.vim'

    "Plugin 'vim-scripts/taglist.vim'
    Plugin 'majutsushi/tagbar'

    Plugin 'mbbill/code_complete'  "<Ctrl-B> function args completion and snippets
    Plugin 'mbbill/undotree'

    Plugin 'rking/ag.vim'
    "Plugin 'yegappan/mru'

    Plugin 'uguu-org/vim-matrix-screensaver'
    Plugin 'thinca/vim-fontzoom'

    Plugin 'godlygeek/csapprox'
    "Plugin 'hari-rangarajan/CCTree'

    Plugin 'vim-scripts/SpellCheck'

    "Plugin 'dbakker/vim-lint'
    Plugin 'syngan/vim-vimlint'
    Plugin 'ynkdir/vim-vimlparser'

    Plugin 'mhinz/vim-startify'

    Plugin 'jreybert/vim-largefile'

    " All of your Plugins must be added before the following line
    exe ':call vundle#end()'
    filetype plugin indent on    " required
"---VUNDLE---
else
    filetype plugin indent on
endif

"Todo: enable Eclim (by removing following line)
let g:EclimDisabled = 'defined'

if v:version < 704
    let g:loaded_youcompleteme = 1 "too old Vim => disable YouCompleteMe
    let g:loaded_numbers = 1
endif

"let g:ycm_python_binary_path = 'python2.7'  "used only for python completers - not ycmd server
let g:ycm_server_python_interpreter = expand('$HOME/toolchains/python2712/bin/python')

let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
"Do not ask when starting vim
let g:ycm_confirm_extra_conf = 0
"set tags += $HOME/tmp/ycm.tags
function! YCM_tagfiles()
    if expand('$CSCOPE_FILES_DIR') !=# '$CSCOPE_FILES_DIR'
        return [expand('$CSCOPE_FILES_DIR') . '/ycm.tags']
    else
        return [expand('$HOME') . '/tmp/ycm.tags']
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
endif

let b:old_ycm_status = 0

function! Multiple_cursors_before()
    call youcompleteme#DisableCursorMovedAutocommands()
    " if exists('b:ycm_largefile')
    "     let b:old_ycm_status = 0
    " else
    "     let b:old_ycm_status = 1
    "     let b:ycm_largefile = 1
    " endif
endfunction

function! Multiple_cursors_after()
    call youcompleteme#EnableCursorMovedAutocommands()
    " if b:old_ycm_status == 1
    "     if exists('b:ycm_largefile')
    "         unlet b:ycm_largefile
    "     endif
    " endif
endfunction

"""" this does not really trigger YCM, but omni cpp completion instead
"""" make YCM completion via ycm_key_invoke_completion work only after . or ->
"""" otherwise it is unusably slow (and breaks YCM altogether on huge source bases)
"""function! OmniConditionalComplete()
"""    "check if after . or ->, then allow, otherwise ignore
"""    "check filetype (ft) to prevent for c,c++ only, otherwise allow everywhere
"""    "(heavy search can be still cancelled by CTRL+C)
"""    if &ft == "c" || &ft == "cpp"
"""        let l:start = col('.')-3
"""        if l:start < 0
"""            let l:start = 0
"""        endif
"""        let l:part = strpart( getline('.'), l:start, col('.')-1 )
"""        if l:part =~ '.\.$' || part =~ '->$' || part =~ '::$'
"""            return "\<C-X>\<C-O>\<C-P>"
"""        else
"""            return ""
"""        endif
"""    else
"""        return "\<C-X>\<C-O>\<C-P>"
"""        "return ""
"""    endif
"""endfunction
"""
""""inoremap g:ycm_key_invoke_completion <C-r>=OmniConditionalComplete()<CR>
"""exe "inoremap ".g:ycm_key_invoke_completion." <C-r>=OmniConditionalComplete()<CR>"

let s:home_base_path=$HOME

" ============================
" =           Paths          =
" ============================
" replace all directory separators in runtimepath to OS specific
let &runtimepath=substitute(&runtimepath, '[\/]', g:OS_dir_separator, 'g')

" ============================
" =         Sessions         =
" ============================
" remove possible trailing slash before creating directory $HOME/.vim/sessions
let g:user_sessions_home = substitute($HOME, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'sessions'
let g:user_session_filename = 'session.vim'

function! SaveSession()
    if exists(':SSave')
        execute 'SSave'
    else
        if isdirectory(g:user_sessions_home) == 0
            "silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_sessions_home
            call system(g:OS_mkdir_command . ' ' . g:user_sessions_home)
        endif
        execute 'mksession! ' . g:user_sessions_home . g:OS_dir_separator . g:user_session_filename
    endif
endfunction
function! LoadSession()
    if exists(':SLoad')
        execute 'SLoad'
    else
        if v:version >= 700
            tabfirst
            tabonly
        endif
        if isdirectory(g:user_sessions_home) == 0
            call system(g:OS_mkdir_command . ' ' . g:user_sessions_home)
        endif
        execute 'source ' . g:user_sessions_home . g:OS_dir_separator . g:user_session_filename
    endif
endfunction

" open files with the cursor at the last remembered position
" commit filetype buffers are ignored
" quickfix windows are ignored also (needed for ALE async lopen with linter errors during select-mode anomaly)
if has('autocmd')
    autocmd! BufReadPost *
                \ if line("'\"") > 0 && line("'\"") <= line("$") && &ft !~# 'commit' && &ft !~# 'qf'
                \ |   execute "normal! g`\""
                \ | endif
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
    set relativenumber      " relative line numbers
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

"convenience mappings
nnoremap Q <nop>
"if has("user_commands")
"    command! -bang -nargs=? -complete=file E e<bang> <args>
"    command! -bang Wa wa<bang>
"endif
cabbrev E <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'e' : 'E')<CR>
cabbrev Wq <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'wq' : 'Wq')<CR>
cabbrev WQ <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'wq' : 'WQ')<CR>
cabbrev W <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'w' : 'W')<CR>
cabbrev Wa <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'wa' : 'Wa')<CR>
cabbrev WA <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'wa' : 'WA')<CR>
cabbrev Q <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'q' : 'Q')<CR>
cabbrev Qa <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'qa' : 'Qa')<CR>
cabbrev QA <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'qa' : 'QA')<CR>
cabbrev X <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'x' : 'X')<CR>
cabbrev Xa <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'xa' : 'Xa')<CR>
cabbrev XA <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'xa' : 'XA')<CR>

"no splash screen
set shortmess+=I

"visual block extension beyong line endings ($ still selects up to respective line end)
set virtualedit=block

if v:version >= 700
    set tabpagemax=25
endif

"function! Align()
"    '<,'>!column -t|sed 's#  \(\S\)# \1#g'
"    normal gv=
"endfunction
"
"xnoremap <silent> gQ :<C-u>silent call Align()<CR>

"needs to be after syn on (syntax on)
let g:colors_name = g:color_scheme
try
    exec 'colorscheme ' . g:color_scheme
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
cabbrev w!! <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'SudoWrite' : 'w!!')<CR>

" do not move cursor during yank in visual mode
vnoremap y ygv<Esc>

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

function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [l:lnum1, l:col1] = getpos("'<")[1:2]
    let [l:lnum2, l:col2] = getpos("'>")[1:2]
    let l:lines = getline(l:lnum1, l:lnum2)
    let l:lines[-1] = l:lines[-1][: l:col2 - (&selection ==# 'inclusive' ? 1 : 2)]
    let l:lines[0] = l:lines[0][l:col1 - 1:]
    return join(l:lines, "\n")
endfunction

" Yank selected text as an escaped search-pattern
map <silent><Plug>(visual-yank-plaintext)  :<C-U>call setreg(v:register, '\V' . escape(<SID>get_visual_selection(), '\/'))<CR>
"map <silent><Plug>(visual-yank-plaintext) :<C-U>call setreg('/',
"'\V'.escape(get_visual_selection(), '\/'))<CR>
"vmap <C-Q> <Plug>(visual-yank-plaintext)
"vmap <A-/> "/<Plug>(visual-yank-plaintext)n

"apply macro on every line of a visually selected range
if v:version >= 700
    xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
endif

function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

" search for visually selected text
"vnoremap // y/<C-R>"<CR>
"vnoremap ?? y?<C-R>"<CR>
"vmap // "/<Plug>(visual-yank-plaintext)n
"vmap ?? "/<Plug>(visual-yank-plaintext):let v:searchforward=0<CR>n

"better jumping to function beginning/end (does not require {,} to be in the
"first column of the file

function! My_PreSection(count, bracket_to_find, search_flags, move_to_execute)
    "Todo: maybe use :keepjumps instead
    normal m`

    "echomsg "count " . a:count . " " . line(".") . ":" . col(".")
    let i = a:count
    while i > 0
        """"normal "?{"  "did not work properly, replaced with search
        let pos_save = getpos('.')
        """let l = line(".")
        """let c = col(".")
        let b = search(a:bracket_to_find, a:search_flags)
        """let line = getline(".")
        """while (((a:search_flags == "bW") && (line(".") == l) && (col(".") != c)))
        """    "to skip over { } { lines in .tcl scripts
        """    let l = line(".")
        """    let c = col(".")
        """    let b = search(a:bracket_to_find, a:search_flags)
        """endwhile
        if b > 0
            exe "normal " . a:move_to_execute
            """if (a:search_flags == "W")
            """    "to skip over { } { lines in .tcl scripts
            """    let line = getline(".")
            """    let line_part = line[col(".")+1:]
            """    if (matchstr(line_part, "{") != "")
            """        let i = i + 1
            """    endif
            """endif
        else
            call setpos('.', pos_save)
            break
        endif
        let i = i - 1
    endwhile
endfunction

function! My_SectionJump(count, n_move, last_move)
    "Todo: maybe use :keepjumps instead
    normal m`

    let i = a:count
    let pos_save_orig = getpos('.')
    if a:last_move == "[["
        exe "normal " . "99]}"
        if getpos('.') == pos_save_orig
            let i = i - 1
        endif
        call setpos('.', pos_save_orig)
    endif
    exe "normal " . a:n_move
    let pos_save = getpos('.')
    "let pos_save2 = []
    if i > 0
        while i > 0
            exe "normal " . a:n_move
            let i = i - 1
        endwhile
        let pos_save2 = getpos('.')
    else
        let pos_save2 = pos_save_orig
    endif
    "echomsg pos_save[0] . ":" . pos_save[1]
    "echomsg pos_save2[0] . ":" . pos_save2[1]
    if pos_save != pos_save2
        exe "normal " . a:last_move
    else
        call setpos('.', pos_save_orig)
    endif
endfunction

"see :help map-operator
"nnoremap [[ :set opfunc=My_PreSection<CR>g@
"nnoremap [[ @=':call My_PreSection(v:count)'<CR>

"map [[ ?{<CR>w99[{
"map ][ /}<CR>b99]}
"map ]] j0[[%/{<CR>
"map [] k$][%?}<CR>

nnoremap [[ :<C-U>call My_PreSection(v:count1, "{", "bW", "w99[{")<CR>
nnoremap ][ :<C-U>call My_PreSection(v:count1, "}", "W", "b99]}")<CR>
nnoremap ]] :<C-U>call My_SectionJump(v:count1, "][", "[[")<CR>
nnoremap [] :<C-U>call My_SectionJump(v:count1, "[[", "][")<CR>
"Todo: add visual mappings for custom section jumps (see MyParagraphJump as an example)

function! MyParagraphJump(count, forward, ...)
    if a:0 > 0  "visual mode
        execute "normal! gv"
    endif

    "Todo: maybe use :keepjumps instead
    normal m`

    let l:search_flags = "bW"
    if a:forward == 1
        let l:search_flags = "W"
    endif

    let l:position = getpos("v")
    let l:saved_pos = getpos(".")
    let l:position[2] = 0  "will jump to column 0
    let l:i = a:count
    while l:i > 0
        let l:current_line_text = getline(".")
        if l:current_line_text =~ "^\\s*$"  "on empty/whitespace only line
            let l:found_line = search("^\\s*\\S.*$", l:search_flags)
        else
            let l:found_line = 1
        endif
        if l:found_line > 0
            let l:found_line = search("^\\s*$", l:search_flags)
        endif
        if l:found_line <= 0
            if a:forward == 1
                let l:found_line = line("$")
            endif
            let l:position[1] = l:found_line
            call setpos(".", l:position)
            break
        else
            let l:position[1] = l:found_line
            call setpos(".", l:position)
        endif
        let l:i = l:i - 1
    endwhile
    " jump to the original column after paragraph move
    execute "normal " . (l:saved_pos[2] + l:saved_pos[3]) . "|"
endfunction

nnoremap <silent> { :<C-U>call MyParagraphJump(v:count1, 0)<CR>
nnoremap <silent> } :<C-U>call MyParagraphJump(v:count1, 1)<CR>

onoremap <silent> { :<C-U>call MyParagraphJump(v:count1, 0)<CR>
onoremap <silent> } :<C-U>call MyParagraphJump(v:count1, 1)<CR>

vnoremap <silent> { :<C-U>call MyParagraphJump(v:count1, 0, visualmode())<CR>
vnoremap <silent> } :<C-U>call MyParagraphJump(v:count1, 1, visualmode())<CR>

set errorformat^=%-GIn\ file\ included\ from\ %f:%l:%c:,%-GIn\ file\ included\ from\ %f:%l:%c\\,,%-GIn\ file\ included\ from\ %f:%l:%c,%-GIn\ file\ included\ from\ %f:%l,%-G%*[\ ]from\ %f:%l:%c
set errorformat^=%-G%n:%l:%c%.%#\ Tar\'ing\ up\ changed\ files,%-GBuilding\ list\ of\ req'd\ files\ -\ starting\ at\ %s\ %n:%l:%c\ %.%#,%-GDone\ at\ %s\ %n:%l:%c\ %.%#,%-G%n:%l:%c\ %m\ Sending\ changed\ files\ to\ server,%-G%n:%l:%c\ %s\\,\ Remotely\ executing\ %.%#,%-G###\ %n:%l:%c%.%#\,\ Rsyncing\ files\ with\ \ server\ %.%#,%-G%.%#%n:%l:%c%.%#\,\ Remotely\ SSH\ executing\ %.%#

set laststatus=2

if v:version >= 700
    " set completion options
    set completeopt=menu,longest ",longest,preview

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
        if !exists('g:lasttab')
            let g:lasttab = 1
        endif
        nnoremap g<Tab> :exe "tabn ".g:lasttab<CR>
        autocmd! TabLeave * let g:lasttab = tabpagenr()
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
    if $REL == ""
        autocmd! BufEnter * let &titlestring= "%m%r" . expand("%:t")
    else
        if $VPLOAD != ""
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
nnoremap g<Left> <C-w><Left>
nnoremap g<Right> <C-w><Right>
nnoremap g<Up> <C-w><Up>
nnoremap g<Down> <C-w><Down>
xnoremap g<Left> <C-w><Left>
xnoremap g<Right> <C-w><Right>
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

" thesaurus lookup
function! MySynonymLookup(mode)
    let l:isk_orig = &isk
    set isk+=-
    set isk+='
    "set isk+=.
    set isk+=32  "does not change anything (space probably cannot be part of keyword)
    let v_s = getpos("'<")
    let v_e = getpos("'>")
    if a:mode != "v"
        let l:word = expand("<cword>")
    else
        let l:word = <SID>get_visual_selection()
    endif

    " Note: currently comma must be used as a separator
    " Todo: improve to nonalpha,non-,non',non<space>,non<dot> to support different thesauruses
    let l:grep_thesaurus_word_separator = "[,]"

    if &ignorecase == 1
        let l:grep_ic_flag = " -i "
    else
        let l:grep_ic_flag = ""
    endif

    "escape . character - we using grep
    let l:grep_word = substitute(l:word, '\.', '\\.', 'g')

    let l:thesaurus_list = split(&thesaurus, ",")
    let l:all_synonyms = []
    let l:display_synonyms = []
    for l:thesaurus in l:thesaurus_list
        let l:thesaurus_line = system('grep ' . l:grep_ic_flag . ' "^' . l:grep_word . l:grep_thesaurus_word_separator . '"' . ' ' . l:thesaurus . ' | tr -d "\n"')
        let l:synonyms = split(l:thesaurus_line, ",")
        if len(l:synonyms) > 0
            "remove the word under cursor (first ony in the list)
            call remove(l:synonyms, 0)
            call extend(l:all_synonyms, l:synonyms)
        else
            "no synonyms found
        endif
    endfor

    "add number to items in the list
    let l:syn_index = 1
    while l:syn_index <= len(l:all_synonyms)
        let l:synonym = l:all_synonyms[l:syn_index - 1]

        if &infercase == 1
            if l:word[0:0] ==# toupper(l:word[0:0])
                "original input starts with upper case => inferring
                "upper case start of replacement
                let l:synonym = toupper(l:synonym[0:0]) . l:synonym[1:]
                let l:all_synonyms[l:syn_index - 1] = l:synonym
            endif
        endif

        call add(l:display_synonyms, l:syn_index . " \"" . l:synonym . "\"")
        let l:syn_index = l:syn_index + 1
    endwhile

    "check if we have any synonyms and not too many (probably a bug, when more than 1024 synonyms)
    if len(l:all_synonyms) > 0 && len(l:all_synonyms) < 1024
        "insert header
        call insert(l:all_synonyms, "DUMMY", 0)
        call insert(l:display_synonyms, "Change \"" . l:word . "\" to (thesaurus):", 0)


        "refuse multiline visual
        if a:mode != "v" || v_s[1] == v_e[1]
            "present the list to user
            let l:chosen_number = inputlist(l:display_synonyms)
            if l:chosen_number > 0 && l:chosen_number < len(l:display_synonyms)
                let l:replacement = l:all_synonyms[l:chosen_number]

                let l:current_line = getline(".")

                let saved_cursor = getcurpos()

                "find the start of visual/current word
                let l:found_line = search(l:word, "bcW")
                if l:found_line == saved_cursor[1]
                    let match_cursor = getcurpos()
                    if match_cursor[2] - 1 > 0
                        let l:updated_line = l:current_line[:(match_cursor[2] - 1 - 1)] .  l:replacement . l:current_line[(match_cursor[2] - 1 + strlen(l:word)):]
                    else
                        let l:updated_line = l:replacement . l:current_line[(match_cursor[2] - 1 + strlen(l:word)):]
                    endif
                    "replace line
                    call setline(".", l:updated_line)
                    if v_e[2] >= v_s[2]
                        let v_e[2] = v_e[2] - strlen(l:word) + strlen(l:replacement)
                    else
                        let v_s[2] = v_s[2] - strlen(l:word) + strlen(l:replacement)
                    endif
                else
                    "not found
                endif

                call setpos(".", saved_cursor)
            else
                "substitution aborted by user
            endif
        else
            "multiline visual => do nothing
        endif
    else
        "no synonyms were found
    endif

    let &isk=l:isk_orig

    if a:mode == "v"
        "adjust improve former visual boundaries to the replaced word (before reselection)
        call setpos("'<", v_s)
        call setpos("'>", v_e)
        execute "normal! gv"
    endif
endfunction

nnoremap <silent>z_ :call MySynonymLookup("n")<Enter>
vnoremap <silent>z_ <Esc>:call MySynonymLookup("v")<Enter>

let s:noquiting = 0
" Todo: do not try to move special windows like tagbar,undotree (when they close buffer ceases to
" exist, hence no b <number> command is possible)
function! MoveToPrevTab()
    "there is only one window
    if tabpagenr('$') == 1
        if winnr('$') == 1
            echomsg "Single window - no move allowed"
            return
        endif
    endif
    let l:buftype = getbufvar(winbufnr(winnr()), "&buftype")
    if l:buftype == "quickfix" || l:buftype == "help"
        echomsg "Special window - no move allowed"
        return
    endif
    let s:noquiting = 1
    "preparing new window
    let l:tab_nr = tabpagenr('$')
    let l:cur_buf = bufnr('%')
    let l:cur_tab = tabpagenr()
    if l:cur_tab != 1
        close!
        if l:cur_tab < tab_nr
            tabprev
        elseif l:tab_nr == tabpagenr('$')
            "nwhole tab was not closed => move to prev tab to make split
            tabprev
        endif
        vertical botright sp
    else
        close!
        exe "0tabnew"
    endif
    "opening current buffer in new window
    exe "b".l:cur_buf
    let s:noquiting = 0
endfunc

function! MoveToNextTab()
    "there is only one window
    if tabpagenr('$') == 1
        if winnr('$') == 1
            echomsg "Single window - no move allowed"
            return
        endif
    endif
    let l:buftype = getbufvar(winbufnr(winnr()), "&buftype")
    if l:buftype == "quickfix" || l:buftype == "help"
        echomsg "Special window - no move allowed"
        return
    endif
    let s:noquiting = 1
    "preparing new window
    let l:tab_nr = tabpagenr('$')
    let l:cur_buf = bufnr('%')
    let l:cur_tab = tabpagenr()
    if l:cur_tab < tab_nr
        close!
        if l:tab_nr == tabpagenr('$')
            "whole tab was not closed => move to next tab to make split
            tabnext
        endif
        vert topleft sp
    else
        close!
        tabnew
    endif
    "opening current buffer in new window
    exe "b".l:cur_buf
    let s:noquiting = 0
endfunc

nnoremap z, :call MoveToPrevTab()<CR>
nnoremap z. :call MoveToNextTab()<CR>

" ============================
" =        Fx commands       =
" ============================
" resolves even words enclosed with |{word}|, e.g. diff-diffexpr vs. |diff-diffexpr|
function! SophHelp()
    if &buftype=="help" && match( strpart( getline("."), col(".")-1,1), "\\S")<0
        bw
    else
        try
            let l:cww=substitute(expand("<cWORD>"), '[^A-Za-z_:]', '', 'ga')
            "echo l:cww
            exec "help ".l:cww
            "exec "help ".expand("<cWORD>")
        catch /:E149:\|:E661:/
            " E149 no help for <subject>
            " E661 no <language> help for <subject>
            " E488 trailing characters
            " E492 not a command word
            try
                exec "help ".expand("<cword>")
            catch /:E149:\|:E661:/
                echohl WarningMsg
                echo "Sorry, no help for ".expand("<cWORD>")." or ".expand("<cword>")
                echohl None
            endtry
        endtry
    endif
endfunction

if v:version >= 703
    nmap <silent><S-F7> :UndotreeToggle<Enter>
    imap <silent><S-F7> <C-o>:UndotreeToggle<Enter>
    vmap <silent><S-F7> <Esc>:UndotreeToggle<Enter>gv
else
    nmap <silent><S-F7> :call SophHelp()<Enter>
    imap <silent><S-F7> <C-o>:call SophHelp()<Enter>
    vmap <silent><S-F7> <Esc>:call SophHelp()<Enter>gv
endif

" F2 to save
nmap <silent><F2> :w<Enter>
imap <silent><F2> <C-o>:w<Enter>
vmap <silent><F2> <Esc>:w<Enter>gv

" F3 to toggle source/header
let g:header_source_flip_search_path = substitute('.,**,../include/**,../src/**,' . expand("$ROOT") . '/panos,', '[\/]', g:OS_dir_separator, 'g')
" switch editing between .c* and .h* files
function! Mosh_Flip_Ext()
    " Since .h file can be in a different dir, calling find
    let oldpath = &path
    try
        "file search path will be fixed
        "set path=.,**,../include/**,../src/**
        let &path = g:header_source_flip_search_path
        if match(expand("%"),'\.c') > 0
            "let s:flipname = substitute(expand("%"),'\.c\(.*\)','.h\1',"")
            let s:flipname = expand("%:t:r")
            try
                exe ":find " . s:flipname . ".h"
            catch /^Vim\%((\a\+)\)\=:E345/
                try
                    exe ":find " . s:flipname . ".hh"
                catch /^Vim\%((\a\+)\)\=:E345/
                    exe ":find " . s:flipname . ".hpp"
                endtry
            endtry
        elseif match(expand("%"),"\\.h") > 0
            "let s:flipname = substitute(expand("%"),'\.h\(.*\)','.c\1',"")
            let s:flipname = expand("%:t:r")
            try
                exe ":find " . s:flipname . ".cc"
            catch /^Vim\%((\a\+)\)\=:E345/
                try
                    exe ":find " . s:flipname . ".c"
                catch /^Vim\%((\a\+)\)\=:E345/
                    exe ":find " . s:flipname . ".cpp"
                endtry
            endtry
        endif
    finally
        let &path = oldpath
    endtry
endfun

function! Header_switch()
    if match(expand("%:e"),"^c") >= 0
        exe "normal \<C-P>" . expand("%:t:r") . ".h"
    elseif match(expand("%:e"),"^h") >= 0
        exe "normal \<C-P>" . expand("%:t:r") . ".c"
    else
        exe "normal \<C-P>" . expand("%:t:r")
    endif
endfunction

map <silent><F3> :call Header_switch()<CR>
"imap <F3> <C-o>:call Mosh_Flip_Ext()<CR>
"vmap <F3> <Esc>:call Mosh_Flip_Ext()<CR>gv

" F4 to switch between hex and ASCII editing
function! Fxxd()
    let c=getline(".")
    if c =~ '^[0-9a-f]\{8}:'
        :%!xxd -r
    else
        :%!xxd -g4
    endif
endfunction

nmap <silent><S-F4> :call Fxxd()<Enter>
imap <silent><S-F4> <C-o>:call Fxxd()<Enter>
vmap <silent><S-F4> <Esc>:call Fxxd()<Enter>gv

function! s:ConvertToNormalDiff(list) "{{{2
  " Convert unified diff into normal diff
  let result=[]
  let start=1
  let hunk_start = '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\)\%(,\(\d\+\)\)\? @@.*$'
  let last = ''
  for line in a:list
    if start && line !~# '^@@'
      continue
    else
      let start=0
    endif
    if line =~? '^+'
      if last is# 'old'
        call add(result, '---')
        let last='new'
      endif
      call add(result, substitute(line, '^+', '> ', ''))
    elseif line =~? '^-'
      let last='old'
      call add(result, substitute(line, '^-', '< ', ''))
    elseif line =~? '^ ' " skip context lines
      continue
    elseif line =~? hunk_start
      let list = matchlist(line, hunk_start)
      let old_start = list[1] + 0
      let old_len   = list[2] + 0
      let new_start = list[3] + 0
      let new_len   = list[4] + 0
      let action    = 'c'
      let before_end= ''
      let after_end = ''
      let last = ''

      if list[2] is# '0'
        let action = 'a'
      elseif list[4] is# '0'
        let action = 'd'
      endif

      if (old_len)
        let before_end = printf(',%s', old_start + old_len - 1)
      endif
      if (new_len)
        let after_end  = printf(',%s', new_start + new_len - 1)
      endif
      call add(result, old_start.before_end.action.new_start.after_end)
    endif
  endfor
  return result
endfunction

function! s:SysList(cmd)
  if exists('*systemlist')
    return systemlist(a:cmd)
  endif
  return split(system(a:cmd), '\n')
endfunction

"almost the same as without setting diffexpr (but can be easily changed in the future)
"produces some artifacts on command line after execution
function! MyDiff()
    let l:diffargs = ''
    if &diffopt =~# 'icase'
        let l:diffargs = l:diffargs . '-i'
    endif
    if &diffopt =~# 'iwhite'
        "let l:diffargs = l:diffargs . '-b'  "ignore whitespace change
        let l:diffargs = l:diffargs . '-w'
    endif
    if exists('g:diffoptions')
        if g:diffoptions !=# ''
            let l:diffargs = l:diffargs . '-d'  "only minimal algorithm supported in basic diff
        endif
    endif
    "silent execute '!diff -a --binary ' . l:diffargs . ' ' . v:fname_in . ' ' . v:fname_new . ' > ' . v:fname_out
    call system('diff -a --binary ' . l:diffargs . ' ' . v:fname_in . ' ' .  v:fname_new . ' > ' . v:fname_out)
endfunction

" Note: this function is called twice during any diff operation in Vim (once to check validity with two one line files)
function! GitDiff()
    let l:diffargs = []
    if &diffopt =~# 'iwhite'
        call add(l:diffargs, '-w')
    endif

    if !exists('g:gitdiff_exists')
        let g:gitdiff_exists = executable(g:diffexecutable)
    endif

    if g:gitdiff_exists
        if g:diffoptions !=# ''
            call add(l:diffargs, g:diffoptions)
        endif
        let l:diffcmd = g:diffexecutable . ' ' . g:difffixedargs . ' ' .  g:diffnoindex
    else
        if g:diffoptions !=# ''
            call add(l:diffargs, '-d')  "minimal algorithm for basic linux diff
        endif
        let l:diffcmd = 'diff -a --binary'
    endif

    call add(l:diffargs, v:fname_in)
    call add(l:diffargs, v:fname_new)

    " echomsg l:diffcmd . ' ' . join(l:diffargs, ' ')

    let l:difflist=s:SysList(l:diffcmd . ' ' . join(l:diffargs, ' '))

    " if unified diff...
    " do some processing here
    if !empty(l:difflist) && l:difflist[0] !~# '\m\C^\%(\d\+\)\%(,\d\+\)\?[acd]\%(\d\+\)\%(,\d\+\)\?'
        " transform into normal diff
        let l:difflist=s:ConvertToNormalDiff(l:difflist)
        call writefile(l:difflist, v:fname_out)
    elseif empty(l:difflist)
        call writefile([''], v:fname_out)
        " it is too late to abort here - the split is already open (how to improve ?)
        "echohl InfoMsg
        "redraw! | echomsg 'There is no difference'
        "echohl None
        "diffoff!
        "wincmd p
        "wincmd q
    else
        call writefile(l:difflist, v:fname_out)
    endif
endfunction

function! ToggleDiffWhitespace()
    if &diffopt =~# 'iwhite'
        set diffopt-=iwhite
    let l:infomsg = 'diff mode changed to evaluate whitespace changes'
    else
        set diffopt+=iwhite
        let l:infomsg = 'diff mode changed to ignore whitespace changes'
    endif
    execute "normal! zz"
    execute "normal! \<c-e>"
    execute "normal! \<c-y>"
    " redraw!
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction

function! ToggleDiffOptions()
    if !exists('g:gitdiff_exists')
        let g:gitdiff_exists = executable(g:diffexecutable)
    endif

    if g:gitdiff_exists
        if g:diffoptions ==# ''
            let g:diffoptions = '--diff-algorithm=histogram --indent-heuristic'
            let l:infomsg = 'diff mode changed to histogram with indent heuristic'
        elseif g:diffoptions ==# '--diff-algorithm=histogram --indent-heuristic'
            let g:diffoptions = '--diff-algorithm=histogram'
            let l:infomsg = 'diff mode changed to histogram'
        else
            let g:diffoptions = ''
            let l:infomsg = 'diff mode changed to basic myers algorithm'
        endif
    else
        if g:diffoptions ==# ''
            let g:diffoptions = '-d'
            let l:infomsg = 'diff mode changed to minimal algorithm'
        else
            let g:diffoptions = ''
            let l:infomsg = 'diff mode changed to basic myers algorithm'
        endif
    endif
    diffupdate
    execute "normal! zz"
    execute "normal! \<c-e>"
    execute "normal! \<c-y>"
    if exists(':SignifyRefresh')
        let g:signify_vcs_cmds['git'] = g:diffexecutable . ' ' . g:difffixedargs . ' ' . g:diffoptions . ' -- %f'
        "call sy#util#refresh_windows()
        execute 'SignifyRefresh'
    endif
    " redraw!
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction

function! ToggleWithinLineDiffCharAllLines()
    if g:DiffModeSync == 0
        let g:DiffModeSync = 1
    else
        let g:DiffModeSync = 0
    endif
    if &diff
        execute "normal \<Plug>ToggleDiffCharAllLines"
    endif
    echohl ModeMsg
    echomsg 'diff mode changed to ' . (g:DiffModeSync ? 'show' : 'hide') . ' exact character diffs within changed line'
    echohl None
endfunction

" ignore whitespace differences is on by default (iwhite)
set diffopt=filler,context:6,foldcolumn:0,vertical,iwhite
" no character inside line diff by default (g:DiffModeSync)
let g:DiffModeSync = 0
let g:diffexecutable = 'git_2_13_3'
let g:difffixedargs = 'diff -U0 --no-color --no-ext-diff'
let g:diffnoindex = '--no-index'
" histogram with indent heuristic by default
let g:diffoptions = '--diff-algorithm=histogram --indent-heuristic'
let g:signify_vcs_cmds = {}
let g:signify_vcs_cmds['git'] = g:diffexecutable . ' ' . g:difffixedargs . ' ' . g:diffoptions . ' -- %f'
set diffexpr=GitDiff()
" =========
" = Signs =
" =========
" not really used (could be used in future, with debugger integration)
if has('signs')
    "defines sign type information
    sign define information text=!> texthl=Error linehl=Warning
    "places sign type information with ID 123 on current line
    "exe ":sign place 123 line=" . line(".") . " name=information file=" . expand("%:p")
    "remove sign with ID 123 from current file
    "exe ":sign unplace 123 file=" . expand("%:p")

    "nmap <F7> :exe ":sign place 123 line=" . line(".") . " name=information file=" . expand("%:p")<CR>
    "nmap <S-F7> :exe ":sign unplace 123 file=" . expand("%:p")<CR>
endif

set pastetoggle=<F7>

nmap <silent><F8> :TagbarToggle<Enter>
imap <silent><F8> <C-o>:TagbarToggle<Enter>
vmap <silent><F8> <Esc>:TagbarToggle<Enter>gv

"nmap <silent><S-F8> :TlistToggle<Enter>
"imap <silent><S-F8> <C-o>:TlistToggle<Enter>
"vmap <silent><S-F8> <Esc>:TlistToggle<Enter>gv

nmap <silent><S-F6> :call LoadSession()<Enter>
imap <silent><S-F6> <C-o>:call LoadSession()<Enter>
vmap <silent><S-F6> <Esc>:call LoadSession()<Enter>gv

nmap <silent><S-F5> :call SaveSession()<Enter>
imap <silent><S-F5> <C-o>:call SaveSession()<Enter>
vmap <silent><S-F5> <Esc>:call SaveSession()<Enter>gv

" F10 to quit
nmap <silent><F10> :q<Enter>
imap <silent><F10> <C-o>:q<Enter>
vmap <silent><F10> <Esc>:q<Enter>gv
"map ^_ gf

nmap <silent><S-F10> :qa<Enter>
imap <silent><S-F10> <C-o>:qa<Enter>
vmap <silent><S-F10> <Esc>:qa<Enter>gv

"comm! -nargs=? -bang A call AlternateFile("n<bang>", <f-args>)
"abbreviate/iabbrev/cabbrev

function! Quickfix_window_move(type, direction)
    """ignore error E553: no more items and jump to first/last one
    ""try
    ""    if a:type == "quickfix"
    ""        if a:direction == "prev"
    ""            try
    ""                execute "cprev"
    ""            catch /:E553:/
    ""                execute "cfirst"
    ""            endtry
    ""        else
    ""            try
    ""                execute "cnext"
    ""            catch /:E553:/
    ""                execute "clast"
    ""            endtry
    ""        endif
    ""    else
    ""        if a:direction == "prev"
    ""            try
    ""                execute "lprev"
    ""            catch /:E553:/
    ""                execute "lfirst"
    ""            endtry
    ""        else
    ""            try
    ""                execute "lnext"
    ""            catch /:E553:/
    ""                execute "llast"
    ""            endtry
    ""        endif
    ""    endif
    ""catch
    ""    "silently discard other errors
    ""endtry
    let l:bufferQflist = a:type != "quickfix" ? getloclist(0) : getqflist()
    let l:len = len(l:bufferQflist)
    if l:len == 0
        echohl WarningMsg
        if a:type == "quickfix"
            echomsg "Quickfix list is empty"
        else
            echomsg "Location list for current window is empty"
        endif
        echohl None
        return
    endif

    if a:type == "quickfix"
        if a:direction == "prev"
            try
                execute "cprev"
            catch /:E553:/
                execute "cfirst"
            endtry
        else
            try
                execute "cnext"
            catch /:E553:/
                execute "clast"
            endtry
        endif
        " if a:direction == "prev"
        "     normal [q
        " else
        "     normal ]q
        " endif
    else
        if a:direction == "prev"
            try
                execute "lprev"
            catch /:E553:/
                execute "lfirst"
            endtry
        else
            try
                execute "lnext"
            catch /:E553:/
                execute "llast"
            endtry
        endif
        " if a:direction == "prev"
        "     normal [l
        " else
        "     normal ]l
        " endif
    endif
endfunction

" Quickfix window - prev/next line jumps
nmap <silent> <F11> :call Quickfix_window_move("quickfix", "prev")<Enter>
imap <silent> <F11> <C-o>:call Quickfix_window_move("quickfix", "prev")<Enter>
vmap <silent> <F11> <Esc>:call Quickfix_window_move("quickfix", "prev")<Enter>v

nmap <silent> <F12> :call Quickfix_window_move("quickfix", "next")<Enter>
imap <silent> <F12> <C-o>:call Quickfix_window_move("quickfix", "next")<Enter>
vmap <silent> <F12> <Esc>:call Quickfix_window_move("quickfix", "next")<Enter>v

" Loc<silent> ation window - prev/next line jumps
nmap <silent> <S-F11> :call Quickfix_window_move("location", "prev")<Enter>
imap <silent> <S-F11> <C-o>:call Quickfix_window_move("location", "prev")<Enter>
vmap <silent> <S-F11> <Esc>:call Quickfix_window_move("location", "prev")<Enter>v

nmap <silent> <S-F12> :call Quickfix_window_move("location", "next")<Enter>
imap <silent> <S-F12> <C-o>:call Quickfix_window_move("location", "next")<Enter>
vmap <silent> <S-F12> <Esc>:call Quickfix_window_move("location", "next")<Enter>v

function! ToggleNumbers()
    let l:relative = 0
    if exists("+relativenumber")
        let l:relative = &l:rnu
    endif
    if &l:nu || l:relative
        let w:stored_nu = &l:nu
        let &l:nu = 0
        if exists("+relativenumber")
            let w:stored_rnu = &l:rnu
            let &l:rnu = 0
        endif
    else
        if exists(w:stored_nu)
            let &l:nu = w:stored_nu
            if exists("+relativenumber")
                let &l:rnu = w:stored_rnu
            endif
        else
            let &l:nu = 1
            if exists("+relativenumber")
                let &l:rnu = 1
            endif
        endif
    endif
    echohl ModeMsg
    echomsg 'numbers are turned ' . (&l:nu ? 'on' : 'off')
    echohl None
endfunction

function! ToggleNumberDisplayMode()
    if exists("+relativenumber")
        if &l:rnu == 1
            let &l:nu = 1
            let &l:rnu = 0
        else
            let &l:nu = 1
            let &l:rnu = 1
        endif
        echohl ModeMsg
        echomsg 'relative numbers are turned ' . (&l:rnu ? 'on' : 'off')
        echohl None
    endif
endfunction

" common leader mappings (TODO add vmap support in general to all toggles and diff options)
let g:mapleader = ','
map <Leader>n :call ToggleNumbers()<CR>
map <Leader>N :call ToggleNumberDisplayMode()<CR>

map <Leader>dw :call ToggleDiffWhitespace()<CR>
map <Leader>da :call ToggleDiffOptions()<CR>
map <silent> <Leader>dc :call ToggleWithinLineDiffCharAllLines()<CR>
map <silent> <Leader>dr :diffupdate<CR>

map <Leader>l :set invlist!<CR>
map <Leader>s :set spell!<CR>
map <Leader>H :set hls!<CR>
" TODO rework - it conflicts with setup/teardown window (also ,f)
map <Leader>F :set foldenable!<CR>
map <Leader>w :set wrap!<CR>
map <Leader>p :set paste!<CR>

map <Leader>f :YcmCompleter FixIt<CR>
map <Leader>t :YcmCompleter GetType<CR>
map <Leader>T :YcmCompleter GetParent<CR>
"map <Leader>h :YcmCompleter GoToDeclaration<CR>

" bind Shift+Tab key in normal mode to operation <C-O> - will be symmetrical to Tab key being bound to <C-I>
nnoremap <S-Tab> <C-O>

function! ALEGlobalToggle()
    if g:ale_enabled == 1
        ALEDisable
    else
        ALEEnable
    endif
    let l:infomsg = 'ALE (asynchronous linting) is turned ' . ((g:ale_enabled == 0) ? 'off' : 'on') . ' globally'
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction
function! ALELocalToggle()
    if !exists('b:ale_enabled') || b:ale_enabled == 1
        let b:ale_enabled = 0
        call ale#engine#Cleanup(bufnr('%'))
        " Remove highlights for the current buffer now.
        if g:ale_set_highlights
            call ale#highlight#UpdateHighlights()
        endif

        if g:ale_set_balloons
            call ale#balloon#Disable()
        endif
    else
        unlet b:ale_enabled
        ALELint
    endif
    let l:infomsg = 'ALE (asynchronous linting) is turned ' . (exists('b:ale_enabled') ? 'off' : 'on') . ' for current buffer'
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction
map <Leader>a :call ALELocalToggle()<CR>
map <Leader>A :call ALEGlobalToggle()<CR>

" YouCompleteMe automatic code completion global toggle
function! YcmGlobalToggle()
    if !exists('g:ycm_largefile')
        let g:ycm_largefile = 1
        "let g:ycm_auto_trigger = 0 "use this to toggle automatic(as you type) completion and semantic triggers (., ::, ->) as well
        "let g:ycm_min_num_of_chars_for_completion = 99 "use this instead to keep semantic triggers
        let l:infomsg = "YouCompleteMe automatic completion is turned off globally"
    else
        unlet g:ycm_largefile
        "let g:ycm_auto_trigger = 1 "use this to toggle automatic(as you type) completion and semantic triggers (., ::, ->) as well
        "let g:ycm_min_num_of_chars_for_completion = 2 "use this instead to keep semantic triggers
        let l:infomsg = "YouCompleteMe automatic completion is turned on globally"
    endif
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction
map <Leader>Y :call YcmGlobalToggle()<CR>

" YouCompleteMe automatic code completion buffer toggle
function! YcmLocalToggle()
    if !exists('b:ycm_largefile') || b:ycm_largefile == 0
        let b:ycm_largefile = 1
        let l:infomsg = "YouCompleteMe automatic completion is turned off for current buffer"
    else
        unlet b:ycm_largefile
        let l:infomsg = "YouCompleteMe automatic completion is turned on for current buffer"
    endif
    echohl ModeMsg
    echomsg l:infomsg
    echohl None
endfunction
map <Leader>y :call YcmLocalToggle()<CR>

" mouse integration switching
function! SwitchMouse()
    if &mouse =~ "a"
        set mouse=
    else
        set mouse=a
    endif
    echohl ModeMsg
    echomsg 'mouse is turned ' . (&mouse == 'a' ? 'on' : 'off')
    echohl None
endfunction
map <Leader>m :call SwitchMouse()<CR>

" path leader mappings
"map <Leader>0 :let &path=g:default_search_path<CR>

" ============================
" =        GUI options       =
" ============================
if has("gui_running")
    if v:version >= 700
        function! FoldSpellBalloon()
            let foldStart = foldclosed(v:beval_lnum )
            let foldEnd = foldclosedend(v:beval_lnum)
            let lines = []
            " Detect if we are in a fold
            if foldStart < 0
                " Detect if we are on a misspelled word
                let lines = spellsuggest( spellbadword(v:beval_text)[ 0 ], 5, 0 )
            else
                " we are in a fold
                let numLines = foldEnd - foldStart + 1
                " if we have too many lines in fold, show only the first 14
                " and the last 14 lines
                if ( numLines > 31 )
                    let lines = getline( foldStart, foldStart + 14 )
                    let lines += [ '-- Snipped ' . ( numLines - 30 ) . ' lines --' ]
                    let lines += getline( foldEnd - 14, foldEnd )
                else
                    "less than 30 lines, lets show all of them
                    let lines = getline( foldStart, foldEnd )
                endif
            endif
            return join( lines, has( "balloon_multiline" ) ? "\n" : " " )
        endfunction
        set balloonexpr=FoldSpellBalloon()
        set ballooneval

        " contains for,endfor and hence it is not working in VIM6 at startup
        function! InfoGuiTooltip()
            "get window count
            let wincount = tabpagewinnr(tabpagenr(),'$')
            let bufferlist=''
            "get name of active buffers in windows

            "for i in tabpagebuflist() - for is defined only in VIM7+, in VIM6
            "this script causes error by start
                let bufferlist .= '['.fnamemodify(bufname(i),':t').'] '
            "endfor - defined only in VIM7+
            return bufname($).' windows: '.wincount.' '.bufferlist.' '
        endfunction
        set guitabtooltip=%!InfoGuiTooltip()
    endif

    if g:OS_name ==# 'windows'
        "set guifont=Lucida_Console:h8:cEASTEUROPE
        "set guifont=Dina:h8:cANSI
        silent! set guifont=Envy\ Code\ R:h11:cEASTEUROPE
        if &guifont !=# 'Envy Code R:h11:cEASTEUROPE'
            silent! set guifont=Lucida_Console:h11:cEASTEUROPE
        endif
        set guioptions="aegmrLtT

        " maximize window on start
        if has('autocmd')
            autocmd! GUIEnter * simalt ~X
        endif
    else
        silent! set guifont=Envy\ Code\ R\ 11
        if &guifont !=# 'Envy Code R 11'
            silent! set guifont=Dejavu\ Sans\ Mono\ 11
        endif

        set guioptions="aegimrLtT

        " maximize window on start (still not good enough - it's not truly
        " maxed)
        set guiheadroom=0
        "set lines=999 columns=999

        set lines=50 columns=210
    endif
endif


" simple code completion - works correctly only in graphical modes (gVim) - XXX collides with cscope special stuff - CTRL+SPACE
"imap <C-Space> <C-n><C-p><Down>
"imap <C-S-Space> <C-p><C-n><Up>

"imap <C-Space> <C-r>=CleverTabCompletion()<CR>

" ============================
" =       Super S-TAB        =
" ============================
"function! CleverTabCompletion()
"   " do we have omni completion available
"   if &omnifunc != ''
"      "use omni-completion 1. priority
"      return "\<C-X>\<C-O>"
"   elseif &dictionary != ''
"      " no omni completion, try dictionary completion
"      return "\<C-X>\<C-K>"
"   else
"      "use omni completion or dictionary completion
"      "use known-word completion
"      return "\<C-N>"
"  endif
"endfunction
"
"function! CleverShiftTabCompletion()
"    "check if at beginning of line or after a space
"    if strpart( getline('.'), 0, col('.')-1 ) =~ '\t\+\s*$'
"        let save_cursor = getcurpos()
"        execute "normal F\<C-I>"
"        normal x
"        let save_cursor[2] -= 1
"        call setpos('.', save_cursor)
"        return ""
"    elseif strpart( getline('.'), col('.')-1 ) =~ '^\s*\t\+'
"        let save_cursor = getcurpos()
"        execute "normal f\<C-I>"
"        normal x
"        call setpos('.', save_cursor)
"        return ""
"    elseif strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
"        execute "normal \<LT>\<LT>"
"        return ""
"    else
"        if pumvisible()
"            return "\<C-P>"
"        else
"            "return "\<S-Tab>"
"            return CleverTabCompletion()
"        endif
"    endif
"endfunction

function! TabCompletion(shift)
    let l:storedpumvisible = pumvisible()
    let l:result = ''
    " we do not want function completions, when completion menu is already open
    " templates are still evaluated
    let l:completion = CodeComplete(!l:storedpumvisible)
    let l:result = l:completion[1]
    if l:result ==# ''
        " no expansion found
        " try jumping to first/next marker
        let l:result = SwitchRegion(a:shift)
        if l:result ==# ''
            " no marker found either
            if pumvisible()
                if l:storedpumvisible
                    " completion menu was already visible
                    " move to next item in the menu
                    if a:shift
                        return "\<C-P>"
                    else
                        return "\<C-N>"
                    endif
                else
                    " completion menu was newly opened
                    " multiple completions were found
                    " do nothing extra - stay on the first item (or go to last if shift)
                    if a:shift
                        return "\<C-P>\<C-P>"
                    else
                        return ''
                    endif
                endif
            else
                " just insert the plain old key
                if a:shift
                    return "\<S-Tab>"
                else
                    return "\<Tab>"
                endif
            endif
        else
            " jump to found marker
            return l:result
        endif
    else
        " function args expansion or template expansion found
        " jump to first marker (if any)
        "return l:result . "\<C-R>=" . SwitchRegion() . "\<CR>"
        let l:final = "\<C-R>=" ."Multiple_cursors_before()\<CR>\<BS>"
        let l:final .= l:result
        let l:final .= "\<C-R>=" ."Multiple_cursors_after()\<CR>\<BS>"
        let l:final .= "\<C-R>=" . 'SwitchRegion(' . a:shift . ')' . "\<CR>"
        return l:final
    endif
endfunction

" bind function to the tab key
imap <Tab> <C-r>=TabCompletion(0)<CR>
imap <S-Tab> <C-r>=TabCompletion(1)<CR>

smap <Tab> <Esc>:call SwitchRegion(0)<CR>
smap <S-Tab> <Esc>:call SwitchRegion(1)<CR>

" bind ,a to grep word under cursor
" disabled " nnoremap <Leader>a :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

" bind \ to Ag - similar to /, just enter search string
" disabled " nnoremap \ :grep!<SPACE>

" ============================
" =        OS specific       =
" ============================
if g:OS_name ==# 'windows'
    set grepprg=findstr\ /R\ /S\ /N
else
    set grepprg=grep\ -nH\ $*\ /dev/null

    " The Silver Searcher
    if executable('ag')
      " Use ag over grep
      set grepprg=ag\ --nogroup\ --nocolor
      "\ --column
      let g:ag_working_path_mode = 'r'
      " disabled " nmap <Leader>a :Ag "\b<C-R><C-W>\b"<CR>:cw<CR>
      " disabled " nmap \ :Ag<SPACE>
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
if filereadable("tags")
    set tags+=tags
endif
if $CTAGS_FILE != ""
    "if &tags != ""
    "   set tags+=,
    "endif
    set tags+=$CTAGS_FILE
elseif $CTAGS_PREFIX != ""
    "echo "tst"
    let prefix = $CTAGS_PREFIX
    let bre=0
    for i in range(10)
        for j in range(10)
            let prefixnr = prefix.i.j
            "echo prefixnr
            if filereadable(prefixnr)
                if &tags != ""
                    let &tags.=","
                endif
                let &tags.=prefixnr
                " add .added file always (it may not exist yet - it will be
                " created after update_tags - <F1>)
                "if filereadable(prefixnr . ".added")
                    let &tags = prefixnr . ".added" . "," . &tags
                "endif
            else
                "echo "file ".prefixnr." not found!"
                let bre=1
                break
            endif
        endfor
        if bre == 1
            break
        endif
    endfor

    "if filereadable($CTAGS_PREFIX)
    "   "comma separator is added automatically via += construct
    "   "if &tags != ""
    "   "   set tags+=,
    "   "endif
    "   set tags+=$CTAGS_PREFIX
    "endif
endif

"Note: This fixes strange behavior of jumping between Vim help tags (it simply does
" not work, when tags is empty), adding fake . is enough to make it work
if &tags==""
    set tags=.
endif

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
let Tlist_Ctags_Cmd = g:OS_ctags_command
let Tlist_Show_Menu = 0  " there is a bug in gVim with taglist show menu turned on (E792: Empty menu name)

" ============================
" =   Code_Complete plug-in   =
" ============================
"let g:disable_codecomplete = 1
"""let g:completekey ='<C-B>'

" === numbers.vim ===
"let g:loaded_numbers = 1

" ============================
" =    Clearcase plug-in     =
" ============================
"let g:loaded_ccase = 0  " set to 1 to abort loading ccase.vim plug-in
let g:ccaseUseDialog = 0   " sets usage of windows input dialog

" ============================
" =    ifdef.vim plug-in     =
" ============================
let c_no_if0=1
let c_no_if0_fold=1 "maybe unnecessary
let c_no_comment_fold=1

" ============================
" =     Clang Formatter      =
" ============================
"""" autodetects from l:shiftwidth \ "IndentWidth" : "4",
"""" autodetects from l:expandtab \ "UseTab" : "false",
"""" autoselects based on clang_format#code_style \ "BasedOnStyle" : "Google",
""""Todo: autoselect Braces formatting based on the edited file surrounding context (default to Allman)
"""let g:clang_format#code_style = "Google"
"""
""""even with following custom config the typedef enum/extern "C" missing break
""""bug is still there in clang-formatter (3.8.1 - regression from 3.7.x):
""""https://llvm.org/bugs/show_bug.cgi?id=26626
""""https://llvm.org/bugs/show_bug.cgi?id=26689
""""            \ "BreakBeforeBraces" : "Custom",
""""            \ "BraceWrapping" : {
""""            \       "AfterClass" : "true",
""""            \       "AfterControlStatement" : "true",
""""            \       "AfterEnum" : "true",
""""            \       "AfterFunction" : "true",
""""            \       "AfterNamespace" : "true",
""""            \       "AfterObjCDeclaration" : "true",
""""            \       "AfterStruct" : "true",
""""            \       "AfterUnion" : "true",
""""            \       "BeforeCatch" : "true",
""""            \       "BeforeElse" : "true",
""""            \ },
""""
""""            \ "BreakBeforeBraces" : "Allman",
""""
""""solution is for now to use clang-formatter 3.7.1 (with everything else 3.8.1)
"""let g:clang_format#style_options = {
"""            \ "BreakBeforeBraces" : "Allman",
"""            \ "ColumnLimit" : "120",
"""            \ "AllowShortIfStatementsOnASingleLine" : "false",
"""            \ "AllowShortLoopsOnASingleLine" : "false",
"""            \ "AllowShortFunctionsOnASingleLine" : "Empty",
"""            \ }
"""let g:clang_format#auto_formatexpr = 1
"""let g:clang_format#no_operator = 1
"""
"""function! MyFormat()
"""    let pos_save = getpos('.')
"""    let sel_save = &l:selection
"""    ""let &l:selection = "inclusive"
"""    "let [save_g_reg, save_g_regtype] = [getreg('g'), getregtype('g')]
"""    try
"""        pyf ~/bin/clang-format-from-vim.py
"""    finally
"""        "call setreg('g', save_g_reg, save_g_regtype)
"""        let &l:selection = sel_save
"""        call setpos('.', pos_save)
"""    endtry
"""endfunction
"""
""""""map gQ :pyf ~/toolchains/llvm/share/clang/clang-format.py<cr>
"""""map gQ :pyf ~/bin/clang-format-from-vim.py<cr>
"""
"""let g:loaded_clang_format = 1 "turned off
""""if !exists("g:clang_format#autocommands_loaded")
""""    augroup plugin-clang-format-auto-format
""""        autocmd!
""""        autocmd FileType c,cpp,objc,java,javascript,typescript setlocal formatexpr=MyFormat()<CR>
""""    augroup END
""""    let g:clang_format#autocommands_loaded = 1
""""endif

" ============================
" =        UltiSnips         =
" ============================
"Todo: enable (by removing following lines)
let did_UltiSnips_plugin="defined"
let did_UltiSnips_after="defined"

" === CTRL-P ===
"   if !isdirectory('.git')
"       " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
"       let g:ctrlp_user_command = 'ag %s -l --nocolor -g "" -p ~/.agignore'
"       ""--ignore *gen/work/ --ignore *gen/agent/ti-mibs/'
"       " ag is fast enough that CtrlP doesn't need to cache (better to cache anyhow)
"       let g:ctrlp_use_caching = 1
"   else
"       " Even faster method, but only for git repositories - no caching needed
"       let g:ctrlp_user_command = 'git ls-files --others --cached --exclude-standard -- %s'
"       let g:ctrlp_use_caching = 0
"   endif
function! CTRLP_tagfiles()
"   default tags  (almost 1G) - it is too big for fuzzy matching (10 sec load + 1 sec after keypress seaarch)
"    let result = []
"    call add(result , &tags)
"    return result
    if expand("$CSCOPE_FILES_DIR") != "$CSCOPE_FILES_DIR"
        return [expand("$CSCOPE_FILES_DIR") . '/ctrlp.tags']
    else
        return [expand("$HOME") . '/tmp/ctrlp.tags']
    endif
endfunction

let g:ctrlp_user_command = 'ctrlp_find.sh %s'
let g:ctrlp_use_caching = 0

let g:ctrlp_lazy_update = 0
let g:ctrlp_open_multiple_files = 'tjr'  "potentially add r (to open first in multi-selection in current window/tab)

"nmap <C-M> :CtrlPMRU<CR> "cannot be used, as <Enter> is <C-M>
let g:ctrlp_mruf_max = 50
command! Mru :CtrlPMRU<CR>
cabbrev mru <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Mru' : 'mru')<CR>
cabbrev MRU <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Mru' : 'MRU')<CR>

let g:ctrlp_match_func = {'match': 'cpsm#CtrlPMatch'}

let g:ctrlp_working_path_mode = 'ra'  "for SR projects it is overriden later

"let g:ctrlp_types = ['fil', 'buf', 'mru']  "can only filter the three basic types
"let g:ctrlpswitcher_mode = 1
"let g:ctrlp_extensions = ['tag', 'buffertag', 'switcher']
let g:ctrlp_extensions = ['tag', 'buffertag']

" === diffchar.vim ===
"Todo: enable diffchar.vim
" first fix bug:
" Error detected while processing function <SNR>41_UpdateDiffChar..<SNR>41_ResetDiffChar..<SNR>41_ResetDiffCharPair:
" line    2:
" E803: ID not found: 142
"let g:loaded_diffchar = "defined"
let g:DiffUpdate = 1
"nmap <silent> <Leader>dc <Plug>ToggleDiffCharAllLines
"nmap <silent> <Leader>dC <Plug>ToggleDiffCharCurrentLine
nmap <silent><Plug>(toggle-diff-char-all-lines) <Plug>ToggleDiffCharAllLines
nmap <silent><Plug>(toggle-diff-char-current-line) <Plug>ToggleDiffCharCurrentLine

if !exists('*gettabvar')  " fallback for Vim 7.2 and earlier releases -> turn off diffchar
    let g:DiffModeSync = 0
endif

" === vim-commentary ===
"Xxx: insert mode mapping does not work
"Xxx: <C-/> is the same key as <C-_> in terminals
"Todo: solve readonly file warning, when commenting in RO file (first change)
let g:commentary_map_backslash = 0

nmap <C-_> gc
"comment a line
nmap <C-_><C-_> gcc

"not really useful
"nmap <C-_><C-_><C-_> :set commentstring=/*%s*/<CR>gcgc

"does not work properly
""imap <C-_> <C-o>gc<Right>

"reselects after commenting, beware of uppercasing with keypress `u` in visual mode
vmap <C-_> gcgv
"switch to // comments in c/ccp files
if has('autocmd')
    autocmd! FileType c set commentstring=//%s
    autocmd! FileType cpp set commentstring=//%s
    autocmd! FileType qf set noscrollbind | set scrolloff=0
    autocmd! BufEnter * if &ft != 'qf' | set scrolloff=5 | else | set scrolloff=0 | endif
endif

" === quickfix-reflector
let g:qf_join_changes = 1
let g:qf_write_changes = 0

" === MRU ===
"let g:MRU_Open_File_Use_Tabs = 1 "does not work as it should (use t from MRU window)

" === vim-surround ===
let g:surround_no_insert_mappings = 1 "disable insert mode mappings (unnecessary ?)
let g:surround_no_mappings = 1 "disable all mappings

nmap dS  <Plug>Dsurround
nmap cS  <Plug>Csurround
nmap yS  <Plug>Ysurround
nmap ySS <Plug>Yssurround
xmap S   <Plug>VSurround
xmap gS  <Plug>VgSurround

" === CSApprox ===
let g:CSApprox_loaded = 1  "use only for schemes conversion (:CSApproxSnapshout <exported filename> from gVim)

" === CCTree ===
"let g:CCTreeCscopeDb = "/akocis/0.0_opt/cscope/Linux.64bit.0.0_opt.cscope.out.part00"
"let g:CCTreeCscopeDb = "cscope.out"  "does not work with huge tag files !!!!
let g:loaded_cctree = 1  "good idea, but lacks jumps to reverse callers' call line directly (only jumps to tag)

" === EasyMotion ===
let g:EasyMotion_do_mapping = 0 " Disable default mappings

"Jump to anywhere you want with minimal keystrokes, with just one key
"binding.
"" `s{char}{label}`
"nmap s <Plug>(easymotion-overwin-f)
"" or
"" `s{char}{char}{label}`
"" Need one more keystroke, but on average, it may be more comfortable.
nmap s <Plug>(easymotion-overwin-f2)
xmap s <Plug>(easymotion-f2)
omap s <Plug>(easymotion-f2)

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

" === Syntastic ===
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 3  "value of 1 - autoclose and autoopen clashes with YCM
" let g:syntastic_check_on_open = 0
" let g:syntastic_check_on_wq = 0
"
" let g:syntastic_yang_pyang_args = "--ignore-error=LEAFREF_IDENTIFIER_BAD_NODE --ignore-error=UNUSED_IMPORT"
" " --ignore-error=LEAFREF_IDENTIFIER_NOT_FOUND --ignore-error=BAD_VALUE"  "only for pyang-1.7 and higher (does not work 100% even then)
"
" let g:syntastic_enable_perl_checker = 1  "Perl is a bit special (this can be dangerous: perl -c execing current file)
" let g:syntastic_perl_checkers = ["perl"]
"
" "let g:syntastic_debug_file = "~/syntastic.log"
" "let g:syntastic_debug = 33
"
" "following diffsplit override is needed to make Syntastic understand that
" "particular window is going to be diff windows and hence not extra Syntastic
" "window should be displayed
" command! -nargs=* -complete=file Diffsplit let &diff=1 | diffsplit <args>
" cabbrev diffsplit <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Diffsplit' : 'diffsplit')<CR>
"
" """ "TODO enable nagelfar, when source-ing of .tcl script is resolved (otherwise too many errors are shown)
" """ let g:syntastic_tcl_checkers = []
" """ "Pygments package not found
" """ let g:syntastic_rst_checkers = []
" let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [ ], 'passive_filetypes': [ "tcl", "vim", "rst" ] }

" === Airline ===
let g:airline#extensions#whitespace#max_lines = 50000
let g:airline#extensions#wordcount#max_lines = 100000
let g:airline#extensions#ycm#enabled = 1
let g:airline_symbols_ascii = 1
let g:airline_symbols#linenr = 'ln'
let g:airline_symbols#maxlinenr = ''
"let g:airline#extensions#ycm#error_symbol = 'x' "'E:'
"let g:airline#extensions#ycm#warning_symbol = '⚠' "'W:'
"let g:airline#extensions#ale#error_symbol = 'x'
"let g:airline#extensions#ale#warning_symbol = '⚠'

" === vim-asterisk ===
let g:asterisk#keeppos = 1

map *   <Plug>(asterisk-*)
map #   <Plug>(asterisk-#)
map g*  <Plug>(asterisk-g*)
map g#  <Plug>(asterisk-g#)
map z*  <Plug>(asterisk-z*)
map gz* <Plug>(asterisk-gz*)
map z#  <Plug>(asterisk-z#)
map gz# <Plug>(asterisk-gz#)

" === vim-startify ===
let g:startify_files_number = 10
let g:startify_bookmarks = [
            \ { 'w': '~/.sr_workspaces' },
            \ ]
let g:startify_commands = [
    \ {'m': ['Open modified files in tabs', 'call OpenGitModifiedFiles("tabs","modified","normal")']},
    \ {'M': ['Open branch diverged and modified files in tabs', 'call OpenGitModifiedFiles("tabs","branch","normal")']},
    \ {'d': ['Open modified files in tabs and show diff', 'call OpenGitModifiedFiles("tabs","modified","diff")']},
    \ {'D': ['Open branch diverged files in tabs and show diff', 'call OpenGitModifiedFiles("tabs","branch","diff")']},
    \ ]

"let g:startify_change_to_vcs_root = 1
"let g:startify_session_persistence = 1
let g:startify_session_delete_buffers = 1
let g:startify_session_dir = "~/.vim/sessions"
let g:ctrlp_reuse_window = 'startify'
let g:startify_list_order = [
            \ [ 'MRU' ], 'files', [ 'Sessions' ], 'sessions', [ 'Bookmarks' ],
            \ 'bookmarks', [ 'Commands' ], 'commands'
            \ ]

let g:startify_session_sort = 0  "sort session list alphabetically

set sessionoptions-=blank

" disable startify in man pager mode
if expand('$MAN_PN') ==# '1'
    let g:startify_disable_at_vimenter = 1
endif

" === vim-easy-align ===
map ga <Plug>(EasyAlign)

" === VCSCommands.vim ===
" for startup speed reasons disable non-existing versioning systems (otherwise
" the plugin searches whole $PATH for executable - this can take around 60ms)
let g:VCSCommandBZRExec = ""
let g:VCSCommandHGExec = ""
let g:VCSCommandSVKExec = ""
let g:VCSCommandSVNExec = ""

" disable all ,c<XYZ> mappings
let g:VCSCommandDisableMappings = 1
let g:VCSCommandDisableExtensionMappings = 1

" === vim-vinegar ===
"let g:netrw_keepj=""
nmap _ <Plug>VinegarUp

" === vim-ALE ===
let g:ycm_show_diagnostics_ui = 0  "disable YCM syntax checking (not needed with ALE)
"let g:loaded_ale_dont_use_this_in_other_plugins_please = 1
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
highlight link ALEErrorSign Error
highlight link ALEError Error
highlight link ALEWarningSign Todo
highlight link ALEWarning Todo
highlight link ALEInfoSign SpellCap
highlight link ALEInfo SpellCap
highlight link ALEStyleErrorSign SpellRare
highlight link ALEStyleError SpellRare
highlight link ALEStyleWarningSign SpellLocal
highlight link ALEStyleWarning SpellLocal
let g:ale_statusline_format = ['x %d', '⚠ %d', '✓ ok']
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0
let g:ale_open_list = 1
"let g:ale_keep_list_window_open = 1
let g:ale_echo_msg_error_str = 'E'
let g:ale_echo_msg_warning_str = 'W'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_emit_conflict_warnings = 0  "do not complain about syntastic
let g:ale_linters = {
    \   'c': ['compilation'],
    \   'ccp': ['ccplint'],
    \   'cfg': ['setupteardownchecker'],
    \   'cpp': ['compilation'],
    \   'mail': ['grammarcheck'],
    \   'mib': ['mibcomp'],
    \   'perl': ['perl'],
    \   'python': ['python', 'flake8'],
    \   'rst': [],
    \   'sh': ['shell', 'shellcheck'],
    \   'tcl': [],
    \   'vim': ['vint'],
    \   'yaml': [],
    \   'yang': ['pyang'],
    \}

let g:ale_pedantic_linting = 0  "can be controlled via <Leader>P

let g:ale_python_flake8_use_global = 1  "CAUTION: without this every execution of flake8 linter would traverse disk to find parent python environment (this causes huge slowdowns)
let g:ale_python_flake8_executable = 'flake8_linter.sh'
let g:ale_vim_vint_executable = 'vint_linter.sh'

" see output from pyang --list-errors (grep LEAFREF + UNUSED_IMPORT)
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
            \ --ignore-error=UNUSED_IMPORT'

" next section fixes the bug with preview window messing with buffer highlights after closing it with dedicated functin pclose or <C-W>z
command! -nargs=* -complete=file PClose wincmd P | wincmd q <args>
cabbrev pclose <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'PClose' : 'pclose')<CR>
nmap <C-W>z :PClose<Enter>
vmap <C-W>z <Esc>:PClose<Enter>gv

function! ALELintingFinished()
    if exists(':SignifyRefresh')
        execute 'SignifyRefresh'
    endif
    if exists(':AirlineRefresh')
        execute 'AirlineRefresh'
    endif
endfunction

augroup ALEGroup
    autocmd!
    autocmd User ALELint call ALELintingFinished()
augroup END

" ==========================
" = Miscellaneous functions=
" ==========================
" Generates ctags and cscope tags for specified folder (without args used currently opened file's folder)
function! GenCTags(...)
    let l:fdir = ""
    if a:0 > 0
        let l:fdir = a:1
    endif

    if l:fdir == ""
        let l:path = resolve(expand("%:p:h"))
    else
        let l:path = resolve(expand(l:fdir))
    endif

    silent! execute "!" . g:OS_ctags_command . " --languages=C,C++,Tcl -R --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+fq --tag-relative=yes --totals=yes --sort=foldcase " . l:path

    if &tags != ""
        let &tags=l:path . g:OS_dir_separator . "tags" . "," . &tags
    else
        let &tags=l:path . g:OS_dir_separator . "tags"
    endif

    execute "redraw!"
endfunction

command! -nargs=? -complete=dir GenCTags :call GenCTags(<f-args>)
"cabbrev genctags <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'GenCTags' : 'genctags')<CR>

" Generates ctags and cscope tags for specified folder (without args used currently opened file's folder)
function! GenTags(...)
    let l:fdir = ""
    if a:0 > 0
        let l:fdir = a:1
    endif

    if l:fdir == ""
        let l:path = resolve(expand("%:p:h"))
    else
        let l:path = resolve(expand(l:fdir))
    endif

    echomsg "fdir = " . l:path

    let l:temp_file_list = system("echo /tmp/cf.\$USER.\$RANDOM")


    silent! execute "!" . "find " . l:path . " \\( -name \"*.h\" -o -name \"*.hh\" -o -name \"*.hpp\" -o -name \"*.c\" -o -name \"*.cc\" -o -name \"*.cpp\" -o -name \"*.java\" -o -name \"*.mk\" -o -name \"*.db\" -o -name \"*.sh\" -o -name \"*.cfg\" -o -name \"*.mib\" -o -name \"*.tcl\" -o -name \"*.yang\" \\) | grep -v \"/obj/\" > " . l:temp_file_list
    silent! execute "!" . "ctags --languages=C,C++,Tcl --fields=+ia --extra=+fq --tag-relative=yes -f " . l:path . "/tags --totals=yes --sort=foldcase -L " . l:temp_file_list
    "Note: cscope needs to be away from the folder we are indexing (otherwise it duplicates references)
    silent! execute "!" . "cd /tmp ; " . "cscope -k -b -q -u -f " . l:path .  "/cscope.out" . " -i " . l:temp_file_list " ; " . "cd -"

    silent! execute "!" . "rm " . l:temp_file_list


    try
        execute "cs add ". l:path . "/" . "cscope.out"
    catch /:E568:/
        " E568 cscope problem: database already added
    endtry

    if &tags != ""
        let &tags=l:path . "/" . "tags" . "," . &tags
    else
        let &tags=l:path . "/" . "tags"
    endif

    try
        cs reset
    catch /:E568:/
        " E568 cscope problem: database already added
    endtry

    execute "redraw!"
endfunction

command! -nargs=? -complete=dir GenTags :call GenTags(<f-args>)
"cabbrev gentags <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'GenTags' : 'gentags')<CR>

" XML formatter (works with selected ranges) - uses xmllint internally
function! DoFormatXML() range
    " Save the file type
    let l:origft = &ft

    " Clean the file type
    set ft=

    " Add fake initial tag (so we can process multiple top-level elements)
    let l:beforeFirstLine= a:firstline - 1
    if l:beforeFirstLine < 0
        let l:beforeFirstLine=0
    endif
    exe a:lastline . "put ='</PrettyXML>'"
    exe l:beforeFirstLine . "put ='<PrettyXML>'"
    let l:newLastLine= a:lastline + 2
    if l:newLastLine > line('$')
        let l:newLastLine=line('$')
    endif

    " Remove XML header
    exe ":" . a:firstline . "," . a:lastline . "s/<\?xml\\_.*\?>\\_s*//e"

    " Recalculate last line of the edited code
    let l:newLastLine=search('</PrettyXML>')

    " Execute external formatter
    exe ":silent " . a:firstline . "," . l:newLastLine . "!xmllint --noblanks --format --recover -"

    " Recalculate first and last lines of the edited code
    let l:newFirstLine=search('<PrettyXML>')
    let l:newLastLine=search('</PrettyXML>')

    " Get inner range
    let l:innerFirstLine=l:newFirstLine+1
    let l:innerLastLine=l:newLastLine-1

    " Remove extra unnecessary indentation
    exe ":silent " . l:innerFirstLine . "," . l:innerLastLine "s/^  //e"

    " Remove fake tag
    exe l:newLastLine . "d"
    exe l:newFirstLine . "d"

    " Put the cursor at the first line of the edited code
    exe ":" . l:newFirstLine

    " Restore the file type
    exe "set ft=" . l:origft
endfunction
command! -range=% FormatXML <line1>,<line2>call DoFormatXML()

"nmap <silent> <leader>x :%FormatXML<CR>
"vmap <silent> <leader>x :FormatXML<CR>

function! ShowSpaces(...)
    let @/='\v(\s+$)|( +\ze\t)'
    let oldhlsearch=&hlsearch
    if !a:0
        let &hlsearch=!&hlsearch
    else
        let &hlsearch=a:1
    end
    return oldhlsearch
endfunction

function! TrimSpaces(confirm) range
    let oldlist=&list
    set list
    let oldhlsearch=ShowSpaces(1)
    execute a:firstline.",".a:lastline."substitute ///ge" . a:confirm
    let &hlsearch=oldhlsearch
    let &list=oldlist
endfunction

"command! -bar -nargs=0 -range=% TrimSpaces <line1>,<line2>call TrimSpaces()
command! -range=% TrimSpaces <line1>,<line2>call TrimSpaces("")
command! -range=% TrimSpacesConfirm <line1>,<line2>call TrimSpaces("c")
nnoremap <Leader><Space> m`:%TrimSpacesConfirm<CR>
vnoremap <Leader><Space> :TrimSpaces<CR>

" ================
" = Experimental =
" ================
"backup to ~/.vim/
let g:user_backup_home = substitute(s:home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'backup'
if isdirectory(g:user_backup_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_backup_home
endif
let g:user_swap_home = substitute(s:home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'swap'
if isdirectory(g:user_swap_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_swap_home
endif
let g:user_undo_home = substitute(s:home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'undo'
if isdirectory(g:user_undo_home) == 0
    silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_undo_home
endif
"set backupdir=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp
"set backupskip=/tmp/*,/private/tmp/*
"set directory=~/.vim-tmp,~/.tmp,~/tmp,/var/tmp,/tmp

"TODO: improve with noundofile for specific files (like /tmp/* files)
"autocmd! BufWritePre /tmp/* setlocal noundofile

"VIM BUG: unfortunately VIM does not support double trailing slash in
" backupdir specification (does store path into filename) - see https://code.google.com/p/vim/issues/detail?id=179
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

if has("mouse_sgr")
    set ttymouse=sgr
else
    "if we have old vim or vim without mouse_sgr compiled, its better to not touch ttymouse setting
    "set ttymouse=xterm2
end

function! Move_to_column_with_match(str)
    let saved_cursor = getcurpos()
    " echomsg "saved_cursor: " . saved_cursor[1] . ":" . saved_cursor[2]
    call cursor(saved_cursor[1], 1)
    " echomsg "searched str : " . a:str
    "turn on ignore case search \\c
    let l:found_line = search(a:str . "\\c", "cWz")
    " echomsg "found line : " . l:found_line
    if l:found_line == saved_cursor[1]
        "nothing to do - match inside current line was found (cursor should be
        "at the start of the match
    else
        "no match inside line - go back to previous position
        call setpos('.', saved_cursor)
    endif
endfunction

" resolves even with :: in the cWORD, but without following (), ->, ., , e.g. DbgwController::getPort vs. DbgwController::getPort()
function! s:get_tag_internal(str, type)
        "Func(...)
        "let args=a:000
        "for a in args
        "   echo a
        "endfor
        "first make sure we do not do double work (with cst all :tag commands
        "use also cscope - order depends on differnt variable: csto)
        let l:str = a:str

        let l:saved_cst = &cst
        set nocst
        for i in [0,1]
            if &csto == i
                let search_cmd="cscope find g "
            else
                if a:type == "tag"
                    let search_cmd = "tag "
                elseif a:type == "tjump"
                    let search_cmd = "tjump "
                else
                    echohl WarningMsg
                    echo "Wrong ctags search type chosen: " . a:type
                    echohl None
                endif
            endif

            "escape dash (-) symbols (tag is interpreting them as regexp options)
            ""let l:str=substitute(l:str, '[-]', '\-', 'ga')
            if l:str != ""
                try
                    "echomsg search_cmd.l:str
                    exec search_cmd.l:str
                    call Move_to_column_with_match(l:str)
                    let &cst = l:saved_cst
                    return 0  " search no more, result found
                catch /:E325:/
                    " ATTENTION when opening file
                    call Move_to_column_with_match(l:str)
                    let &cst = l:saved_cst
                    return 0
                catch /:E562:\|:E567:\|:E257:\|:E259:\|:E499:\|:E560:\|:E426:\|:E433:\|:E434:\|:E435:/
                    " we will continue with cWORD and cword searches
                endtry
            endif

            let l:cww=substitute(expand("<cWORD>"), '[^A-Za-z_:]', '', 'ga')
            "escape dash (-) symbols (tag is interpreting them as regexp options)
            ""let l:cww=substitute(l:cww, '[-]', '\-', 'ga')
            if l:cww != l:str
                try
                    "echomsg search_cmd.l:cww
                    exec search_cmd.l:cww
                    call Move_to_column_with_match(l:cww)
                    let &cst = l:saved_cst
                    return 0  " search no more, result found
                catch /:E325:/
                    " ATTENTION when opening file
                    call Move_to_column_with_match(l:str)
                    let &cst = l:saved_cst
                    return 0
                catch /:E562:\|:E567:\|:E257:\|:E259:\|:E499:\|:E560:\|:E426:\|:E433:\|:E434:\|:E435:/
                    " E562 bad usage for cstag - obviously cWORD contains special characters
                    " E567 no cscope connections
                    " E257 cstag tag not found
                    " E259 no matches found for cscope query
                    " E426 tag not found
                    " E433 no tags file
                    " E499 Empty file name for '%' or '#', only works with :p:h
                    " E560 Usage cs[cope] find a|c|d|e|f|g|i|s|t name (also uppercase letters)
                endtry
            endif

            let l:cww2=expand("<cword>")
            "escape dash (-) symbols (tag is interpreting them as regexp options)
            ""let l:cww2=substitute(l:cww2, '[-]', '\-', 'ga')
            if l:cww2 != l:str && l:cww2 != l:cww
                try
                    "echomsg search_cmd.l:cww2
                    exec search_cmd.l:cww2
                    call Move_to_column_with_match(l:cww2)
                    let &cst = l:saved_cst
                    return 0  " search no more, result found
                catch /:E325:/
                    " ATTENTION when opening file
                    call Move_to_column_with_match(l:str)
                    let &cst = l:saved_cst
                    return 0
                catch /:E562:\|:E567:\|:E257:\|:E259:\|:E499:\|:E560:\|:E426:\|:E433:\|:E434:\|:E435:/
                    " not found
                endtry
            endif
        endfor
        echohl WarningMsg
        if l:str != ""
            echo "Sorry, no tag generated for ".l:str." or ".expand("<cWORD>")." or ".expand("<cword>")
        else
            echo "Sorry, no tag generated for ".expand("<cWORD>")." or ".expand("<cword>")
        endif
        echohl None
        let &cst = l:saved_cst
endfunction

" PauseALE and ResumeALE are longer needed after Bram's inputlist fix ?
function! PauseALE()
    let l:buf = bufnr('%')
    if !exists('b:ale_enabled') || b:ale_enabled == 1
        let l:enabled = 1
    else
        let l:enabled = 0
    endif
    if l:enabled == 1
        let b:ale_enabled = 0
    endif
    let l:ale_is_linting = ale#engine#IsCheckingBuffer(l:buf)
    if l:ale_is_linting
        call ale#engine#Cleanup(l:buf)
    endif
    return [l:buf, l:enabled, l:ale_is_linting ]
endfunction

function! ResumeALE(previous_state)
    call setbufvar(a:previous_state[0], 'ale_enabled', a:previous_state[1])
    if a:previous_state[2] == 1
        ALELint
    endif
endfunction

function! SophTag(str, type)
    if v:version > 704 || (v:version == 704 && has('patch957'))
        let l:tagcase_saved=&tagcase
        let &tagcase='match'
    endif
    " echomsg "searched str [" . a:str . "]"
    try
        "if a:type ==# 'tjump'
        "    let l:ale_previous_state = PauseALE()
        "endif
        call <SID>get_tag_internal(a:str, a:type)
        "if a:type ==# 'tjump'
        "    call ResumeALE(l:ale_previous_state)
        "endif
    finally
        if v:version > 704 || (v:version == 704 && has('patch957'))
            let &tagcase=l:tagcase_saved
            unlet l:tagcase_saved
        endif
    endtry
endfunction

nmap <silent><C-]> :call SophTag('', 'tag')<Enter>
imap <silent><C-]> <C-o>:call SophTag('', 'tag')<Enter>
vmap <silent><C-]> <Esc>:call SophTag(<SID>get_visual_selection(), 'tag')<Enter>gv
nmap <silent>g<C-]> :call SophTag('', 'tjump')<Enter>
vmap <silent>g<C-]> <Esc>:call SophTag(<SID>get_visual_selection(), 'tjump')<Enter>gv

function! CscopeCtagsSearch(word)
    let l:csto_saved=&csto
    let &csto=0
    try
        call SophTag(a:word, 'tag')
    finally
        let &csto=l:csto_saved
        unlet l:csto_saved
    endtry
endfunction

function! CtagsCscopeSearch(word)
    let l:csto_saved=&csto
    let &csto=1
    try
        call SophTag(a:word, 'tag')
    finally
        let &csto=l:csto_saved
        unlet l:csto_saved
    endtry
endfunction

nnoremap <silent>g<LeftMouse> <LeftMouse>:call CscopeCtagsSearch("")<CR>
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
nnoremap <silent><C-S-Right> :call CscopeCtagsSearch(expand("<cword>"))<Enter>
nnoremap <silent><C-S-Left> <C-T>
inoremap <silent><C-S-Right> <C-o>:call CscopeCtagsSearch(expand("<cword>"))<Enter>
inoremap <silent><C-S-Left> <C-o><C-T>
vnoremap <silent><C-S-Right> <Esc>:call CscopeCtagsSearch(<SID>get_visual_selection())<Enter>
vnoremap <silent><C-S-Left> <Esc><C-T><Enter>


" when .vimrc is edited, reload it
if has('autocmd')
    execute "autocmd! BufWritePost " . g:OS_vimrc . " source %"
endif

" s:NextNormalWindow() {{{2
function! s:NextNormalWindow() abort
    for i in range(1, winnr('$'))
        let buf = winbufnr(i)

        " skip unlisted buffers
        if !buflisted(buf)
            continue
        endif

        " skip temporary buffers with buftype set
        if getbufvar(buf, '&buftype') != ''
            continue
        endif

        " skip the preview window
        if getwinvar(i, '&previewwindow')
            continue
        endif

        " skip current window
        if i == winnr()
            continue
        endif

        return i
    endfor

    return -1
endfunction

" s:QuitIfOnlyWindow() {{{2
function! s:QuitIfOnlyWindow() abort
    let l:buftype = getbufvar(winbufnr(winnr()), "&buftype")
    if s:noquiting == 1 || l:buftype != "quickfix" && l:buftype != "help"
        return
    endif

    " Check if there is more than one window
    if s:NextNormalWindow() == -1
        " Check if there is more than one tab page
        if tabpagenr('$') == 1
            " Before quitting Vim, delete the special buffer so that
            " the '0 mark is correctly set to the previous buffer.
            " Also disable autocmd on this command to avoid unnecessary
            " autocmd nesting.
            if winnr('$') == 1
                if has('autocmd')
                    noautocmd bdelete
                endif
            endif
            quit
        else
            " Note: workaround for the fact that in new tab the buftype is set
            " too late (and sticks during this WinEntry autocmd to the old -
            " potentially quickfix/help buftype - that would automatically
            " close the new tab and open the buffer in copen window instead
            " New tabpage has previous window set to 0
            if tabpagewinnr(tabpagenr(), '#') != 0
                let l:last_window = 0
                if winnr('$') == 1
                    let l:last_window = 1
                endif
                close
                if l:last_window == 1
                    " Note: workaround for the same bug, but w.r.t. Airline
                    " plugin (it needs to refresh buftype and status line after
                    " last special window autocmd close on a tab page
                    if exists(':AirlineRefresh')
                        execute "AirlineRefresh"
                    endif
                endif
            endif
        endif
    endif
endfunction

" autoclose last open location/quickfix/help windows on a tab
if has('autocmd')
    augroup AutoCloseAllQF
        autocmd!
        "au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" | q | endif
        autocmd WinEnter * nested call s:QuitIfOnlyWindow()
    augroup END
endif

"Todo: check Vim startup time via: vim --startuptime /tmp/startup.txt
"
nnoremap <silent> <leader>DD :exe ":profile start profile.log"<cr>:exe ":profile func *"<cr>:exe ":profile file *"<cr>
nnoremap <silent> <leader>DP :exe ":profile pause"<cr>
nnoremap <silent> <leader>DC :exe ":profile continue"<cr>
nnoremap <silent> <leader>DQ :exe ":profile pause"<cr>:noautocmd qall!<cr>

" clipoard copy and paste functions
"Todo: only when xsel is installed (perhaps distribute with vi ?)
command! -range Cz :silent :<line1>,<line2>w !xsel -i -b
command! -range Cx :silent :<line1>,<line2>w !xsel -i -p
command! -range Cv :silent :<line1>,<line2>w !xsel -i -s
cabbrev cz <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Cz' : 'cz')<CR>
cabbrev cx <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Cx' : 'cx')<CR>
cabbrev cv <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Cv' : 'cv')<CR>

command! -range Pz :silent :r !xsel -o -b
command! -range Px :silent :r !xsel -o -p
command! -range Pv :silent :r !xsel -o -s
cabbrev pz <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Pz' : 'pz')<CR>
cabbrev px <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Px' : 'px')<CR>
cabbrev pv <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Pv' : 'pv')<CR>

"function to clean all non-visible buffers
function! Wipeout()
    " list of *all* buffer numbers
    let l:buffers = range(1, bufnr('$'))

    " what tab page are we in?
    let l:currentTab = tabpagenr()

    let buflist = []
    for i in range(tabpagenr('$'))
        call extend(buflist, tabpagebuflist(i + 1))
    endfor

    for buf in buflist
        let idx = index(l:buffers, buf)
        if idx != -1
            call remove(l:buffers, idx)
        endif
    endfor

    try
        " if there are any buffers left, delete them
        if len(l:buffers)
            "echomsg "number:".len(l:buffers)
            try
                execute 'bwipeout' join(l:buffers)
            catch /:E517:/
                "nothing was wiped out
            endtry
        endif
    finally
        " go back to our original tab page
        execute 'tabnext' l:currentTab
    endtry
endfunction

command! Wipeout :call Wipeout()
cabbrev wipeout <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Wipeout' : 'wipeout')<CR>

function! DiffOrig()
    if &diff
        diffoff!
        wincmd o
    else
        let ftype = &filetype
        let actualfilename=expand('%:p')
        topleft vert new
        setlocal bt=nofile
        r #
        let &titlestring = "saved copy" . " <-> " . actualfilename
        0d_
        exe "setlocal filetype=" . ftype
        diffthis | wincmd p | diffthis
    endif
endfunction

function! XReconnect()
    let display_file = substitute(s:home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.display_variable'
    let displist = readfile(display_file, '', 1)
    exe "xrestore " . displist[0]
endfunction

command! XReconnect :call XReconnect()
cabbrev xreconnect <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'XReconnect' : 'xreconnect')<CR>

function! RefreshAll()
    echomsg "Refresh of everything..."
    "execute "sign unplace * file=" . expand('%:p')
    if has('signs')
        execute "sign unplace * buffer=" . bufnr('%')
    endif
    if exists(':SignifyRefresh')
        "call sy#util#refresh_windows()
        execute "SignifyRefresh"
    endif
    if exists('*ale#highlight#UpdateHighlights')
        call ale#highlight#UpdateHighlights()
    endif
    if exists(':YcmRestartServer')
        execute "YcmRestartServer"
    endif
    if exists(':MultipleCursorsReset')
        execute "MultipleCursorsReset"
    endif
    if exists('*ToggleCursorRefresh')
        call ToggleCursorRefresh()
    else
        execute "redraw!"
    endif
    if exists(':AirlineRefresh')
        execute "AirlineRefresh"
    endif
    execute "redrawstatus!"
endfunction

command! RefreshAll :call RefreshAll()
cabbrev refreshall <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'RefreshAll' : 'refreshall')<CR>

noremap <Leader><C-L> :call RefreshAll()<CR>

function! LoadCrashBacktrace(symbol_file, ...)
    let crash_dump_file="bt"
    let silent_mode = 0
    if filereadable(expand(a:symbol_file))
        if a:0 > 0  "input file was specified
            let crash_dump_file = a:1
            if filereadable(expand(crash_dump_file))
                let silent_mode = 1
            endif
        endif

        let tmp_file = expand("/tmp/${USER}_" . localtime() . "_crash_resolved.txt")

        echomsg "silent_mode = " . silent_mode

        let gdbtb_cmd = "!" . "gdbtb" ." " . a:symbol_file . " " . crash_dump_file
        if silent_mode == 0
            silent! execute gdbtb_cmd . " | tee " . tmp_file
        else
            silent! execute gdbtb_cmd . " > " . tmp_file
        endif

        let old_efm = &l:efm
        let &l:efm = 'Line %l of "%f" %m'
        execute "cfile " . tmp_file
        let &l:efm = old_efm

        silent! execute "!" . "rm" . " " . tmp_file
        execute "redraw!"
    else
        echohl WarningMsg
        echomsg "Symbol file " . a:symbol_file . " is not existing/not readable"
        echohl None
    endif
endfunction

command! -nargs=+ -complete=file LoadCrashBacktrace :call LoadCrashBacktrace(<f-args>)
cabbrev loadcrashbacktrace <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'LoadCrashBacktrace' : 'loadcrashbacktrace')<CR>

function! OpenGitModifiedFiles(opentype, whatfiles, diffstyle)
    echohl ModeMsg
    echomsg 'Opening all ' . (a:whatfiles == 'modified' ? 'modified' : 'branch modified') . ' files ' . (a:diffstyle == 'diff' ? 'and showing the diffs' : '')
    echohl None
    let l:file_list = []
    if a:whatfiles == "modified"
        let l:file_list = split(system("list_git_modified_files.sh -r"), "\n")
    elseif a:whatfiles == "branch"
        let l:file_list = split(system("list_git_modified_files.sh -r"), "\n")
        let l:file_list += split(system("list_git_branch_modified_files.sh"), "\n")
    endif

    if len(l:file_list) > 0
        silent execute "cd! " . l:file_list[0]
        call remove(l:file_list, 0)
    endif

    let l:type = a:opentype
    let l:count = 0
    for l:item in l:file_list
        if l:count == 0 && (&ft == "" || &ft == "startify")
            silent execute "e " . l:item
        else
            if l:type == "tabs"
                silent execute "tabe " . l:item
            elseif l:type == "splits"
                silent execute "botright split " . l:item
            elseif l:type == "vsplits"
                silent execute "botright vsplit " . l:item
            elseif l:type == "bufs"
                silent execute "badd " . l:item
            endif
        endif
        if a:diffstyle == "diff"
            if a:opentype == "tabs"
                if exists(':VCSVimDiff')
                    let l:git_branching_point = system("get_git_upstream_branching_point.sh | tr -d '\n'")
                    silent execute "VCSVimDiff " . l:git_branching_point
                endif
            endif
        endif
        let l:count = l:count + 1
        if l:count == &tabpagemax
            echomsg "Opened maximum " . l:count . " files (there are more modified files - opening them in buffers)"
            let l:type = "bufs"
        endif
    endfor
    if l:count == 0
        echomsg "No modified files"
    else
        if a:opentype == "tabs"
            tabfirst
        elseif a:opentype == "splits"
            1wincmd w
        elseif a:opentype == "vsplits"
            1wincmd w
        elseif a:opentype == "bufs"
            bfirst
        endif
    endif
    "cexpr l:file_list
endfunc

" This callback will be executed when the entire command is completed
function! BackgroundCommandClose(channel)
    " Read the output from the command into the quickfix window
    execute 'cfile! ' . g:backgroundCommandOutput
    " Open the quickfix window
    copen
    unlet g:backgroundCommandOutput
endfunction

function! RunBackgroundCommand(command)
    " Make sure we're running VIM version 8 or higher.
    if v:version < 800
        echoerr 'RunBackgroundCommand requires VIM version 8 or higher'
        return
    endif

    if exists('g:backgroundCommandOutput')
        echo 'Already running task in background'
    else
        echo 'Running task in background'
        " Launch the job.
        " Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
        " will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or?
        let g:backgroundCommandOutput = tempname()
        call job_start(a:command, {'close_cb': 'BackgroundCommandClose', 'out_io': 'file', 'out_name': g:backgroundCommandOutput})
    endif
endfunction

" So we can use :BackgroundCommand to call our function.
command! -nargs=+ -complete=shellcmd RunBackgroundCommand call RunBackgroundCommand(<q-args>)

" function! ExpandCMacro()
"     "get current info
"     let l:macro_file_name = "__macroexpand__" . tabpagenr()
"     let l:file_row = line(".")
"     let l:file_name = expand("%")
"     let l:file_window = winnr()
"
"     let l:tmp_file = expand("%:h") . "/cscope." . l:macro_file_name . ".cpp"
"     let l:preprocessed_file = "/tmp" . "/cscope." . l:macro_file_name . ".cpp"
"     silent! execute "w! " . l:tmp_file
"     "open tiny window ... check if we have already an open buffer for macro
"     if bufwinnr( l:macro_file_name ) != -1
"         execute bufwinnr( l:macro_file_name) . "wincmd w"
"         setlocal modifiable
"         silent! execute "normal! gg\"_dG"
"     else
"         execute "bot 10split " . l:macro_file_name
"         execute "setlocal filetype=cpp"
"         execute "setlocal buftype=nofile"
"         nnoremap <buffer> q :q!<CR>
"     endif
"     "silent! execute "r!compilation.py -e " . l:tmp_file . " -f " . "-" . " 2>/dev/null"
"     "create mark
"     silent! execute "!sed -i '" . l:file_row . "i\ int " . l:macro_file_name . ";' " . l:tmp_file
"     "process file with gcc
"     "echomsg "tmp: " . l:tmp_file
"     "echomsg "pre: " . l:preprocessed_file
"     silent! execute "!compilation.py -e " . l:tmp_file . " -f " .  l:preprocessed_file . " 2>/dev/null"
"     silent! execute "!rm -f " . l:tmp_file
"     "read result into tiny window
"     silent! execute "r " . l:preprocessed_file
"     "keep only specific macro line
"     silent! execute "normal! ggV/int " . l:macro_file_name . ";$\<CR>\"_d"
"     silent! execute "normal! j\"_dG"
"     "indent
"     "execute "%!indent -st -kr"
"     "execute "normal! gg=G"
"     execute "normal! gggqG"
"     "resize window
"     execute "normal! G"
"     let l:macro_end_row = line(".")
"     execute "resize " . l:macro_end_row
"     execute "normal! gg"
"     "no modifiable
"     setlocal nomodifiable
"     "return to origin place
"     execute l:file_window . "wincmd w"
" """    execute l:file_row
" """    execute "normal!u"
" """    execute "w"
"     "highlight origin line
"     let @/ = getline('.')
"     redraw!
" endfunction
"
" map <leader>e :call ExpandCMacro()<CR>
"
" function! ExpandCMacro2()
"     "get current info
"     let l:macro_file_name = "__macroexpand__" . tabpagenr()
"     let l:file_row = line(".")
"     let l:file_name = expand("%")
"     let l:tmp_file = expand("%:h") . "/." . expand("%:t:r") . "." . expand("%:e")
"     let l:preprocessed_file = "/tmp" . "/" . expand("$USER") . "." .  expand("$RANDOM") . "." . l:macro_file_name
"     silent! execute "w! " . l:tmp_file
"     "execute 'match Search /\%'.line('.').'l/'
"     silent! execute "!code_expand_macro.sh " . l:tmp_file . " " . l:file_row . " " . l:preprocessed_file
"     "execute 'match none'
"     silent! execute "!rm -f " . l:tmp_file
"     "read result into tiny window
"     "echomsg "done"
"     silent! execute ":pedit " . l:preprocessed_file
"     "store syntax to set the same for preview
"     let l:syntax = &syntax
"     "recalculate file_window
"     let l:file_window = bufwinnr("%")
"     "echomsg "win:" . l:file_window
"     silent! execute "wincmd P"
"     "set no modifiable for preview
"     setlocal nomodifiable
"     let &syntax=l:syntax
"     "resize window
"     let l:expand_lines = line('$')
"     let l:winheight = winheight('%')
"     if l:expand_lines < l:winheight
"         execute "resize " . l:expand_lines
"     elseif l:expand_lines > l:winheight
"         if l:expand_lines > &previewheight
"             let l:expand_lines = &previewheight
"         endif
"         execute "resize " . l:expand_lines
"     endif
"     "return to origin place
"     redraw
"     silent! execute l:file_window . "wincmd w"
"     "highlight origin line
"     "Todo: add slash escapes (make it work - works only after searching was
"     "already used at least once in current buffer/vim ?
"     "let @/ = "\\V" . getline('.')
"     redraw!
" endfunction

function! ExpandCMacroAsyncCommandClose(channel)
    """" Read the output from the command into the quickfix window
    """execute "cfile! " . g:backgroundCommandOutput
    """" Open the quickfix window
    """copen

    unlet g:backgroundCommandOutput
    call delete(g:tmp_file)
    "read result into tiny window
    "echomsg "done"

    " TODO after async job finished when in 'c' or 'r' modes the window is garbled
    " start a timer and wait until mode != 'c' && mode != 'r', then finish
    "
    " if mode() !=# 'n'
    "     return
    " endif

    let l:sm = g:StoreSelectionMode()
    " preview window once again does something special - selection is not saved
    " unless the preview window is closed before opening with new content
    silent! execute 'wincmd z'

    "silent! execute "bot 10split " . g:preprocessed_file
    silent! execute ':pedit ' . g:preprocessed_file
    call delete(g:preprocessed_file)
    "store syntax to set the same for preview
    let l:syntax = &syntax
    "recalculate file_window
    let l:file_window = bufwinnr('%')
    "echomsg "win:" . l:file_window
    silent! execute 'wincmd P'
    "set no modifiable for preview
    setlocal nomodifiable
    let &syntax=l:syntax
    "resize window
    let l:expand_lines = line('$')
    let l:winheight = winheight('%')
"    if l:expand_lines < l:winheight
"        execute "resize " . l:expand_lines
"    elseif l:expand_lines > l:winheight
"        if l:expand_lines > &previewheight
"            let l:expand_lines = &previewheight
"        endif
"        execute "resize " . l:expand_lines
"    endif
    "return to origin place
    "redraw
    silent! execute l:file_window . 'wincmd w'
    "highlight origin line
    "Todo: add slash escapes (make it work - works only after searching was
    "already used at least once in current buffer/vim ?
    "let @/ = "\\V" . getline('.')
    "redraw!

    call g:RestoreSelectionMode(l:sm)
    execute '2match none'
endfunction

function! ExpandCMacroAsync()
    "get current info
    let l:file_name = expand('%')
    if !filereadable(l:file_name)
        echohl WarningMsg
        echo 'Can be used only on regular file (not on ' . l:file_name . ')'
        echohl None
        return
    endif

    if &filetype !=# 'c' && &filetype !=# 'cpp'
        echohl WarningMsg
        echo 'Can be used only on c/cpp filetypes (not on filetype ' . &filetype . ')'
        echohl None
        return
    endif

    execute '2match Search /\%'.line('.').'l/'
    let l:macro_file_name = '__macroexpand__' . tabpagenr()
    let l:file_row = line('.')
    let g:tmp_file = expand('%:h') . '/.' . expand('%:t:r') . '.' . expand('%:e')
    let l:rnd = localtime() % 0x10000
    let g:preprocessed_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:macro_file_name

    "silent! execute "w! " . g:tmp_file
    " this does not trigger buffer write autocmds (like linting)
    call writefile(getline(1,'$'), g:tmp_file, 'b')

    let l:async_command = 'supernice code_expand_macro.sh ' . g:tmp_file . ' ' . l:file_row . ' ' . g:preprocessed_file
    " Make sure we're running VIM version 8 or higher.
    if v:version < 800
        echomsg 'Async expand C macro requires VIM version 8 or higher (running sync version)'
        let g:backgroundCommandOutput = 1
        call system(l:async_command)
        call ExpandCMacroAsyncCommandClose(0)
        redraw!
        return
    endif

    if exists('g:backgroundCommandOutput')
        let l:infomsg = 'Already running expand C macro in background'
    else
        let l:infomsg = 'Running expand C macro in background'
        " Launch the job.
        " Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
        " will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or?
        "let g:backgroundCommandOutput = tempname()
        "call job_start(l:async_command, {'close_cb':
        "'ExpandCMacroAsyncCommandClose', 'out_io': 'file', 'out_name': g:backgroundCommandOutput})
        let g:backgroundCommandOutput = 1
        "echo "async: " . l:async_command
        call job_start(l:async_command, {'close_cb': 'ExpandCMacroAsyncCommandClose'})
        """ call job_start('sleep 2', {'close_cb': 'ExpandCMacroAsyncCommandClose'})
    endif

    echo l:infomsg
endfunction

nmap <silent><F4> :call ExpandCMacroAsync()<Enter>
imap <silent><F4> <C-o>:call ExpandCMacroAsync()<Enter>
vmap <silent><F4> <Esc>:call ExpandCMacroAsync()<Enter>gv

function! RefreshTagsAsyncCommandClose(channel)
    if g:refreshTagsCommandVar ==# 'mibupdate'
        let &l:enc=&l:enc
    else
        cs reset
    endif
    echo 'Finished refresh tags in background'
    unlet g:refreshTagsCommandVar
endfunction

function! RefreshTagsAsync(subcommand)
    let l:async_command = 'supernice sr_cscope.sh ' . a:subcommand
    " Make sure we're running VIM version 8 or higher.
    if v:version < 800
        echomsg 'Async refresh tags requires VIM version 8 or higher (running sync version)'
        let g:refreshTagsCommandVar = a:subcommand
        silent! execute '!' . l:async_command
        call RefreshTagsAsyncCommandClose(0)
        redraw!
        return
    endif

    if exists('g:refreshTagsCommandVar')
        echo 'Already running refresh tags in background'
    else
        echo 'Running refresh tags in background'
        " Launch the job.
        " Notice that we're only capturing out, and not err here. This is because, for some reason, the callback
        " will not actually get hit if we write err out to the same file. Not sure if I'm doing this wrong or?
        "let g:refreshTagsCommandOutput = tempname()
        "call job_start(l:async_command, {'close_cb': 'RefreshTagsAsyncCommandClose', 'out_io': 'file', 'out_name': g:refreshTagsCommandOutput})
        let g:refreshTagsCommandVar = a:subcommand
        "echo "async: " . l:async_command
        call job_start(l:async_command, {'close_cb': 'RefreshTagsAsyncCommandClose'})
    endif
endfunction

function! CodeRenameSymbolAtCursor()
    let l:file_name = expand('%')
    if !filereadable(l:file_name)
        echohl WarningMsg
        echo 'Can be used only on regular file (not on ' . l:file_name . ')'
        echohl None
        return
    endif

    if &filetype !=# 'c' && &filetype !=# 'cpp'
        echohl WarningMsg
        echo 'Can be used only on c/cpp filetypes (not on filetype ' . &filetype . ')'
        echohl None
        return
    endif

    " Note: offset calculation  makes it hard to do visual selection rename - because of line2byte (still could be done with getpos("'<"))
    let l:offset = line2byte(line('.'))+col('.') - 2
    let l:current_symbol = expand('<cword>')

    let l:new_symbol = input('Enter new symbol name:', l:current_symbol)
    if l:new_symbol ==# ''
        return
    endif

    let l:input_file = expand('%:h') . '/.' . expand('%:t:r') . '.' . expand('%:e')
    let l:output_file_name = '__coderenamesymbol__' . tabpagenr()
    let l:ed_script_file_name = '__edscript__' . tabpagenr()
    let l:rnd = localtime() % 0x10000
    let l:output_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:output_file_name
    let l:ed_script_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:ed_script_file_name

    " write input_file based on current buffer's content in current buffer's directory with the same extension (to allow clang-rename to work properly)
    "silent! execute 'w! ' . l:input_file
    " this does not trigger buffer write autocmds (like linting)
    call writefile(getline(1,'$'), l:input_file, 'b')

    " rename symbol and store result in output_file
    let l:sync_command = 'code_rename_symbol.sh ' . l:input_file . ' ' . l:output_file . ' ' . l:new_symbol . ' ' . l:offset
    "silent! execute '!' . l:sync_command | let l:shell_error = v:shell_error
    call system(l:sync_command) | let l:shell_error = v:shell_error
    "let l:job = job_start(l:sync_command) | while job_status(l:job) ==# 'run' | sleep 10m | endwhile | let l:shell_error = job_info(l:job).exitval

    if l:shell_error == 0
        " produce ed script via diff command (direct redirection is failing via job_start, but works via job_start(['sh', '-c', l:diffcommand]))
        let l:diff_command = 'diff -e ' . l:input_file . ' ' . l:output_file . ' ' . ' >' . l:ed_script_file
        "silent! execute '!' . l:diff_command | let l:shell_error = v:shell_error
        call system(l:diff_command) | let l:shell_error = v:shell_error
        "let l:job = job_start(['sh', '-c', l:diff_command]) | while job_status(l:job) ==# 'run' | sleep 10m | endwhile | let l:shell_error = job_info(l:job).exitval

        let l:was_in_diff_mode = 0
        if &diff
            " source ed script does not work while in diff mode
            " so quit diff mode to source the ed script and then reenter diff mode
            let l:was_in_diff_mode = 1
            diffoff
        endif

        " source the ed script (no need to jump or mess with history, undo)
        silent! execute 'source ' . l:ed_script_file

        if l:was_in_diff_mode == 1
            diffthis
        endif

        " refresh screen
        "redraw!

        " delete temporary files
        call delete(l:ed_script_file)
    else
        " refresh screen
        redraw

        echohl WarningMsg
        echo 'Renaming of symbol ' . expand('<cword>') . ' failed (place cursor directly above the symbol)'
        echohl None
    endif

    call delete(l:input_file)
    call delete(l:output_file)
endfunction

function! CodeIncludeSymbolAtCursor(mode)
    " Todo: put include_symbols_tags somewhere at global level
    let l:include_symbols_tags = expand('$CSCOPE_FILES_DIR') . '/' .  'include_symbols.tags'
    if !filereadable(l:include_symbols_tags)
        echohl WarningMsg
        echo 'Include symbols tag file not found (' . l:include_symbols_tags . ')'
        echohl None
        return
    endif

    let l:file_name = expand('%')
    if !filereadable(l:file_name)
        echohl WarningMsg
        echo 'Can be used only on regular file (not on ' . l:file_name . ')'
        echohl None
        return
    endif

    if &filetype !=# 'c' && &filetype !=# 'cpp'
        echohl WarningMsg
        echo 'Can be used only on c/cpp filetypes (not on filetype ' . &filetype . ')'
        echohl None
        return
    endif

    if a:mode ==? 'v' || a:mode ==# "\<c-v>" || a:mode ==? 's' || a:mode ==# "\<c-s>"
        let l:current_symbol = <SID>get_visual_selection()
    else
        let l:current_symbol = expand('<cword>')
    endif

    let l:panos = expand('$PANOS')
    if l:panos !=# '$PANOS'
        " strip panos/panos_get_subdir or panos/ from the fullpath provided by ctags
        let l:panos_gen_subdir = ''
        let l:output_list = systemlist('ws_automation.py --print-panos-gen-subdir-with-fallback')
        if len(l:output_list) > 0
            let l:panos_gen_subdir = l:output_list[0]
        endif
    else
        let l:panos = ''
    endif

    let l:kind_x_list = []
    let l:kind_normal_list = []
    let l:candidate_list = []
    let l:oldtags = &tags
    let l:oldtagcase = &tagcase
    let &tags = l:include_symbols_tags
    let &tagcase = l:include_symbols_tags
    let &tagcase ='match'
    let l:ftags = taglist('^'.l:current_symbol.'$')
    let &tagcase = l:oldtagcase
    let &tags = l:oldtags
    for l:i in l:ftags
        let l:filename = l:i.filename

        if l:panos !=# ''
            " strip panos/panos_get_subdir or panos/ from the fullpath provided by ctags
            let l:needle = l:panos . '/' . l:panos_gen_subdir . '/'
            if l:filename =~# l:needle
                let l:filename = substitute(l:filename, l:needle, '', '')
            else
                let l:needle = l:panos . '/'
                let l:filename = substitute(l:filename, l:needle, '', '')
            endif

            " wrap with "" or <>
            if l:filename =~# 'wind/target/h/'
                let l:filename = substitute(l:filename, 'wind/target/h/stl\.[^/]+/mips-wrs-vxworks', '', '')
                let l:filename = substitute(l:filename, 'wind/target/h/stl\.[^/]+/ext', '', '')
                let l:filename = substitute(l:filename, 'wind/target/h/stl\.[^/]+/backward', '', '')
                let l:filename = substitute(l:filename, 'wind/target/h/stl\.[^/]+/', '', '')
                let l:filename = substitute(l:filename, 'wind/target/h/snmp', '', '')
                let l:filename = substitute(l:filename, 'wind/target/h/', '', '')
                let l:filename = '<' . l:filename . '>'
            else
                let l:filename = '"' . l:filename . '"'
            endif
        else
            " default for non-panos sources
            let l:filename = '"' . l:filename . '"'
        endif

        if l:i.kind ==# 'x'
            call add(l:kind_x_list, l:filename)
        else
            call add(l:kind_normal_list, l:filename)
        endif
    endfor

    if len(l:kind_normal_list) > 0
        let l:candidate_list = l:kind_normal_list
    else
        let l:candidate_list = l:kind_x_list
    endif

    " sort and make unique candidates
    call uniq(sort(l:candidate_list))

    " prefer *_api.h, [_/]api/, then common/*, then system includes (e.g. wind/target/h) and then the rest alphabetically
    let l:input_list = []

    let l:idx = 0
    for l:item in l:candidate_list
        if l:item[:len(l:item)-2] =~# '_api\.h$' || l:item[:len(l:item)-2] =~# '[_/]api/'
            call add(l:input_list, l:item)
            call remove(l:candidate_list, l:idx)
        else
            let l:idx = l:idx + 1
        endif
    endfor

    let l:idx = 0
    for l:item in l:candidate_list
        if l:item[1:] =~# '^common/'
            call add(l:input_list, l:item)
            call remove(l:candidate_list, l:idx)
        else
            let l:idx = l:idx + 1
        endif
    endfor

    let l:idx = 0
    for l:item in l:candidate_list
        if l:item[0] ==# '<'
            call add(l:input_list, l:item)
            call remove(l:candidate_list, l:idx)
        else
            let l:idx = l:idx + 1
        endif
    endfor

    for l:item in l:candidate_list
        call add(l:input_list, l:item)
    endfor

    let l:display_list = []
    "add number to items in the list
    let l:index = 1
    while l:index <= len(l:input_list)
        let l:item = l:input_list[l:index - 1]

        call add(l:display_list, l:index . ' ' . l:item)
        let l:index = l:index + 1

    endwhile
    let l:include_file = ''

    if len(l:input_list) > 0
        call insert(l:input_list, 'DUMMY', 0)
        call insert(l:display_list, 'Select include file for "' .  l:current_symbol . '" from the list:', 0)
        if len(l:input_list) > 2
            let l:chosen_number = inputlist(l:display_list)
        else
            " autoselect if only one result
            let l:chosen_number = 1
        endif
        if l:chosen_number > 0 && l:chosen_number < len(l:input_list)
            let l:include_file = l:input_list[l:chosen_number]
            let l:system_header = 0
            if l:include_file[0] ==# '<'
                let l:system_header = 1
            endif
            let l:include_line = '#include ' . l:include_file . ''
            "echomsg 'New include line: ' . l:include_line
            let l:saved_cursor = getcurpos()
            call cursor(1,1)
            " skip if already in the file
            if search(l:include_file, 'n') == 0
                let l:stop_walking = 0
                let l:walk_over = 0
                let l:searched_line = '#include ' . ((l:system_header == 1) ? '<' : '"')
                let l:line = search(l:searched_line, 'n')
                if l:line > 0
                    " we have starting line
                else
                    " no proper include yet (search for any include)
                    let l:searched_line = '#include '
                    let l:line = search(l:searched_line, 'n')
                    "echomsg 'line ' . l:line
                    if l:line > 0
                        " we have a reasonable starting line
                        if l:system_header == 1
                            let l:stop_walking = 1
                        else
                            let l:walk_over = 1
                        endif
                    endif
                endif

                if l:line > 0
                    " now walk the include lines and search for correct place (TODO skip whitespace lines not only '')
                    while l:line <= line('$') && l:stop_walking == 0
                        if getline(l:line) !=# '' && getline(l:line) !~# '#include '
                            break
                        endif
                        if l:walk_over == 0 && getline(l:line) >= l:include_line
                            break
                        endif
                        let l:line = l:line + 1
                    endwhile
                    " skip if duplicate
                    if getline(l:line) !~# l:include_line
                        call append(l:line-1, l:include_line)
                        " add the added line to the saved position lnum to go back correctly
                        let l:saved_cursor[1] += 1
                        redrawstatus!
                        echohl ModeMsg
                        echomsg 'Added new include at line ' . string(l:line) . ': ' . l:include_line
                        echohl None
                    endif
                else
                    call append(l:line, l:include_line)
                    " add the added line to the saved position lnum to go back correctly
                    let l:saved_cursor[1] += 1
                    redrawstatus!
                    echohl ModeMsg
                    echomsg 'Added first include at line ' . string(1) . ': ' . l:include_line
                    echohl None
                endif
            else
                echomsg 'Include line ' . l:include_line . ' is already in the file'
            endif

            call setpos('.', l:saved_cursor)
        else
            "aborted by user
        endif
    else
        " no candidates
        echomsg 'No include files found for symbol "' . l:current_symbol . '"'
    endif
endfunction

function! s:create_keyvals(key, val) abort
    if type(a:val) == type({})
        return a:key . ': {' . s:stringize_options(a:val) . '}'
    else
        return a:key . ': ' . a:val
    endif
endfunction

function! s:stringize_options(opts) abort
    let dict_type = type({})
    let keyvals = map(items(a:opts), 's:create_keyvals(v:val[0], v:val[1])')
    return join(keyvals, ',')
endfunction

function! s:build_extra_options()
    let extra_options = ""

    let opts = copy(g:clang_format_style_options)

    let extra_options .= ', ' . s:stringize_options(opts)

    return extra_options
endfunction

function! s:make_style_options()
    let extra_options = s:build_extra_options()
    return printf("'{BasedOnStyle: %s, IndentWidth: %d, UseTab: %s%s}'",
                        \ g:clang_format_code_style,
                        \ (exists('*shiftwidth') ? shiftwidth() : &l:shiftwidth),
                        \ &l:expandtab==1 ? 'false' : 'true',
                        \ extra_options)
endfunction

function! CodeFormatSelectedLines(line1, line2)
    let l:args = printf(' -lines=%d:%d', a:line1, a:line2)
    let l:args .= printf(' -style=%s ', s:make_style_options())
    let l:args .= printf('-assume-filename=%s ', shellescape(escape(expand('%'), " \t")))

    " TODO use tempname() with getpid() to generate temporary file names
    let l:input_file_name = '__clangformat_in__' . tabpagenr()
    let l:output_file_name = '__clangformat__' . tabpagenr()
    let l:ed_script_file_name = '__edscript__' . tabpagenr()
    let l:rnd = localtime() % 0x10000
    "let l:input_file = expand('%:h') . '/.' . expand('%:t:r') . '.' . expand('%:e')
    let l:input_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:input_file_name
    let l:output_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:output_file_name
    let l:ed_script_file = '/tmp' . '/' . expand('$USER') . '.' .  l:rnd . '.' . l:ed_script_file_name

    " write input_file based on current buffer's content
    call writefile(getline(1,'$'), l:input_file, 'b')

    " format input_file and store result in output_file
    "let l:clang_format_cmd = printf("%s %s --", g:clang_format_executable, l:args)
    "return s:system(l:clang_format_cmd, join(getline(1, '$'), "\n"))
    let l:clang_format_cmd = printf('%s %s %s > %s', g:clang_format_executable, l:args, l:input_file, l:output_file)
    call system(l:clang_format_cmd) | let l:shell_error = v:shell_error

    if l:shell_error == 0
        " produce ed script via diff command (direct redirection is failing via job_start, but works via job_start(['sh', '-c', l:diffcommand]))
        let l:diff_command = 'diff -e ' . l:input_file . ' ' . l:output_file . ' ' . ' >' . l:ed_script_file
        call system(l:diff_command) | let l:shell_error = v:shell_error

        " source the ed script (no need to jump or mess with history, undo)
        silent! execute 'source ' . l:ed_script_file

        " delete temporary files
        call delete(l:ed_script_file)
    else
        echohl WarningMsg
        echo 'Formatting of lines ' . a:line1 . ' - ' . a:line2 . ' failed'
        echohl None
    endif

    call delete(l:input_file)
    call delete(l:output_file)
endfunction

let g:clang_format_executable = 'clang-format'
let g:clang_format_code_style = 'Google'
let g:clang_format_style_options = {
            \ 'BreakBeforeBraces' : 'Allman',
            \ 'ColumnLimit' : '120',
            \ 'AllowShortIfStatementsOnASingleLine' : 'false',
            \ 'AllowShortLoopsOnASingleLine' : 'false',
            \ 'AllowShortFunctionsOnASingleLine' : 'Empty',
            \ }

" check for clang-format and update formatexpr only when existing
if has('autocmd')
    if executable(g:clang_format_executable)
        autocmd FileType c,cpp,objc,java,javascript,typescript setlocal formatexpr=CodeFormatSelectedLines(v:lnum,v:lnum+v:count-1)
    endif
endif

function! TogglePedanticLinting()
    if g:ale_pedantic_linting == 0
        let g:ale_pedantic_linting = 1
        echo 'ALE pedantic linting is turned to level 1 (running ALELint...)'
    elseif g:ale_pedantic_linting == 1
        let g:ale_pedantic_linting = 2
        echo 'ALE pedantic linting is turned to level 2 (running ALELint...)'
    elseif g:ale_pedantic_linting == 2
        let g:ale_pedantic_linting = 3
        echo 'ALE pedantic linting is turned to level 3 (running ALELint...)'
    else
        let g:ale_pedantic_linting = 0
        echo 'ALE pedantic linting is turned off (running ALELint...)'
    endif
    ALELint
endfunction

nmap <Leader>r :call CodeRenameSymbolAtCursor()<CR>
nmap <Leader>i :call CodeIncludeSymbolAtCursor('n')<CR>
vmap <Leader>i <Esc>:call CodeIncludeSymbolAtCursor('v')<CR>gv
nmap <Leader>? :ALEDetail<cr>
nmap <Leader>P :call TogglePedanticLinting()<cr>
" =========================================
" = Project/Versioning system integration =
" =========================================
" guess used versioning system and project based on environment
"  variables/directories
let g:VCS_name=""
let g:PROJECT_name=""
if expand("$CLEARCASE_ROOT") != "$CLEARCASE_ROOT"
    let g:VCS_name="clearcase"
    let g:PROJECT_name="SGSN"
elseif expand("$PANOS") != "$PANOS"
    let g:VCS_name="cvs"
    let g:PROJECT_name="SR"
elseif expand("$LSF_BINDIR") != "$LSF_BINDIR"
    let g:VCS_name="ecms"
    let g:PROJECT_name="WMM"
endif


if g:PROJECT_name == "SR"
    let s:project_specific_path = expand("$ROOT") . '/panos,' . expand("$GEN_PATH") . '/,'

    " tabs are forbidden in SR projects
    set expandtab

    "per project .viminfo
    let g:viminfo_project_dir = expand("$PANOS") . g:OS_dir_separator . ".." . g:OS_dir_separator . "conf" . g:OS_dir_separator
    if isdirectory(g:viminfo_project_dir)
        execute "set viminfo+=n" . g:viminfo_project_dir . ".viminfo"
    endif

    " start in $PANOS folder in CtrlP file mode
    let g:ctrlp_working_path_mode = 'p'

    nmap <silent><F1> :call RefreshTagsAsync("update")<CR>
    imap <silent><F1> <C-o>:call RefreshTagsAsync("update")<CR>
    vmap <silent><F1> <Esc>:call RefreshTagsAsync("update")<CR>gv

    " TODO AKO should iterate over all local buffers and run refresh l:enc
    " (otherwise other windows will not have spell check enabled)
    nmap <silent><S-F1> :call RefreshTagsAsync("mibupdate")<CR>
    imap <silent><S-F1> <C-o>:call RefreshTagsAsync("mibupdate")<CR>
    vmap <silent><S-F1> <Esc>:call RefreshTagsAsync("mibupdate")<CR>gv
else "other projects
    let s:project_specific_path = ""

    " F1 to display help
    nmap <silent><F1> :call SophHelp()<Enter>
    imap <silent><F1> <C-o>:call SophHelp()<Enter>
    vmap <silent><F1> <Esc>:call SophHelp()<Enter>gv
endif

let g:default_search_path = substitute('.,**,../include/**,../src/**,' . s:project_specific_path . g:OS_system_includes_dir, '[\/]', g:OS_dir_separator, 'g')
" set default path
let &path=g:default_search_path
"set suffixesadd=.h

let g:loaded_ccase = 1

if g:VCS_name == "cvs"
    " ===VCSCommand plugin===
    let g:VCSCommandVCSTypePreference = "git"

    nmap <silent><F5> :VCSVimDiff<Enter>
    imap <silent><F5> <C-o>:VCSVimDiff<Enter>
    vmap <silent><F5> <Esc>:VCSVimDiff<Enter>gv

    nmap <silent><F6> :VCSVimDiff BRANCH<Enter>
    imap <silent><F6> <C-o>:VCSVimDiff BRANCH<Enter>
    vmap <silent><F6> <Esc>:VCSVimDiff BRANCH<Enter>gv

    nmap <silent><F9> :VCSBlame!<Enter>
    imap <silent><F9> <C-o>:VCSBlame!<Enter>
    vmap <silent><F9> <Esc>:VCSBlame!<Enter>gv

    nmap <silent><S-F9> :VCSLog<Enter>
    imap <silent><S-F9> <C-o>:VCSLog<Enter>
    vmap <silent><S-F9> <Esc>:VCSLog<Enter>gv

elseif g:VCS_name == "clearcase"
    let g:loaded_ccase = 0

    nmap <silent><F5> :call DiffOrig()<Enter>
    imap <silent><F5> <C-o>:call DiffOrig()<Enter>
    vmap <silent><F5> <Esc>:call DiffOrig()<Enter>gv

    nmap <silent><F6> :call DiffCCPred()<Enter>
    imap <silent><F6> <C-o>:call DiffCCPred()<Enter>
    vmap <silent><F6> <Esc>:call DiffCCPred()<Enter>gv

    nmap <silent><F9> :Ctxlsv<Enter>
    imap <silent><F9> <C-o>:Ctxlsv<Enter>
    vmap <silent><F9> <Esc>:Ctxlsv<Enter>gv

elseif g:VCS_name == "ecms"
    nmap <silent><F5> :call MyEcmsGetCmd("vdload")<Enter>
    imap <silent><F5> <C-o>:call MyEcmsGetCmd("vdload")<Enter>
    vmap <silent><F5> <Esc>:call MyEcmsGetCmd("vdload")<Enter>gv

    nmap <silent><F6> :call MyEcmsGetCmd("vdlatest")<Enter>
    imap <silent><F6> <C-o>:call MyEcmsGetCmd("vdlatest")<Enter>
    vmap <silent><F6> <Esc>:call MyEcmsGetCmd("vdlatest")<Enter>gv

    nmap <silent><F9> :call MyEcmsGetCmd("mdesc", "-e")<Enter>
    imap <silent><F9> <C-o>:call MyEcmsGetCmd("mdesc", "-e")<Enter>
    vmap <silent><F9> <Esc>:call MyEcmsGetCmd("mdesc", "-e")<Enter>gv

    nmap <silent><S-F9> :call MyEcmsGetCmd("mdesc", "-v")<Enter>
    imap <silent><S-F9> <C-o>:call MyEcmsGetCmd("mdesc", "-v")<Enter>
    vmap <silent><S-F9> <Esc>:call MyEcmsGetCmd("mdesc", "-v")<Enter>gv

else "no versioning system
    nmap <silent><F5> :call DiffOrig()<Enter>
    imap <silent><F5> <C-o>:call DiffOrig()<Enter>
    vmap <silent><F5> <Esc>:call DiffOrig()<Enter>gv
endif

let s:localrc=expand("$HOME" . g:OS_dir_separator . ".vimrc_local")
if filereadable(s:localrc)
    execute "source " . s:localrc
endif
