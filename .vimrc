set nocompatible

"Xxx: this needs .term_detect script support in shell
let s:term_program=expand("$TERM_PROGRAM")
let s:term_version=expand("$TERM_VERSION")
if s:term_program == "lxterminal" || s:term_program == "gnome-terminal" ||
            \ s:term_program == "xterm" || s:term_program == "Konsole" ||
            \ s:term_program == "PuTTY" || s:term_program == "Cygwin"
    let &term = "xterm"
elseif s:term_program == "rxvt" || s:term_program == "urxvt"
    let &term = "rxvt"
else
    "Todo: this is a hack for screen-bce/screen.rxvt to behave as xterm/rxvt in Vim
    if &term == "screen-bce" || &term == "screen"
        if expand("$STY") == "$STY"
            "ssh to devpc from inside of a screen (let's fake STY)
            let $STY = "0.dev"
        endif
        let &term = "xterm"
    elseif &term == "screen.rxvt"
        let &term = "rxvt"
    elseif &term =~ "rxvt"  "for urxvt and 256 color variants
        let &term = "rxvt"
    endif
endif

command! -nargs=1 Silent
            \ | execute ':silent !'.<q-args>
            \ | execute ':redraw!'

if has("win64") || has("win32") || has("win16")
    let g:OS_name="windows"

    let g:OS_dir_separator = '\'
    let g:OS_cat_command = 'type'
    let g:OS_mkdir_command = 'mkdir'
    "TODO: change to cygwin later
    let g:OS_ctags_command = 'c:\Apps\ctags57\ctags.exe'
    let g:OS_system_includes_dir = 'c:\Apps\Dev-Cpp\include'

    let g:OS_vimrc = "_vimrc"

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
    "let g:OS_ctags_command = '/opt/exp/bin/ctags'
    "if filereadable(g:OS_ctags_command) == 0
        let g:OS_ctags_command = 'ctags'
    "endif
    let g:OS_system_includes_dir = '/usr/include'

    let g:OS_vimrc = ".vimrc"

    "
    " What was the name that we were called as?
    "
    let vinvoke=fnamemodify($_, ":p")
    let fullp=substitute(vinvoke, '^\(.*[/]\).*$', '\1', "")
    "
    " It's possible that $VIMRUNTIME does not exist.
    " Let's see if there is a directory vimshare below where we were started
    "
    if isdirectory($VIMRUNTIME) == 0
        let vimshare=fullp . "vimshare"
        if isdirectory(vimshare) == 1
            let $VIMRUNTIME=vimshare . "/vim" . substitute(v:version, "50", "5", "")
            let &helpfile=vimshare . "/vim" . substitute(v:version, "50", "5", "") . "/doc/help.txt"
        endif
    endif
endif

if !has("gui_running")
    if g:OS_name != "windows"
        "set t_Cc=1
        "set t_pa=32767

        if &term =~ "xterm"
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
            set <F1>=O;*P
            set <F2>=O;*Q
            set <F3>=O;*R
            set <F4>=O;*S
            set <Home>=O;*H
            set <End>=O;*F

            "konsole (universal case covers also the above for no mod case)
            set <F1>=O*P
            set <F2>=O*Q
            set <F3>=O*R
            set <F4>=O*S

            "new xterm (wildcard used to handle all alt,control,shift combinations)
            set <xF1>=[1;*P
            set <xF2>=[1;*Q
            set <xF3>=[1;*R
            set <xF4>=[1;*S
            set <xHome>=[1;*H
            set <xEnd>=[1;*F

            set <zHome>=[;*H
            set <zEnd>=[;*F

            set <F17>=OE

            "Todo: specify correct version for old/new xterm bindings (for now 278 - Ubuntu 13.04 timeframe is the limit)
            if s:term_program == "lxterminal" || s:term_program == "gnome-terminal" ||
                        \ s:term_program == "xterm" && s:term_version < "278"
                "old xterm/lxterminal/gnome terminal (e.g. lxterminal in Lubuntu 13.04)
                set <xF1>=O1;*P
                set <xF2>=O1;*Q
                set <xF3>=O1;*R
                set <xF4>=O1;*S

                set <F17>=[E
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
            set <Del>=[3;*~

            "cleanup of Vim's internal duplicate bindings
            set <S-Home>=
            set <S-Left>=
            set <S-Right>=
            set <S-End>=

            "newer xterm can do also right winmenu key (has no setting in Vim,
            " however something nonexistant on typical keyboard can be used - F13 for example)
            set <F13>=[29;*~

            "fake key mappings to enable keypad key 5 (Clear) with all modifiers as <F19>
            set <F18>=O*u
            set <F19>=[1;*E

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

        elseif &term =~ "rxvt"
            set t_Co=256 "override terminfo setting to enable 256 colors
            "rxvt (basic Fn are well covered in default Vim mappings)
            " first two are fixed in rxvt - S-F1 == F11 and S-F2 == F12
            set <S-F3>=[25;*~
            set <S-F4>=[26;*~
            set <S-F5>=[28;*~
            set <S-F6>=[29;*~
            set <S-F7>=[31;*~
            set <S-F8>=[32;*~
            set <S-F9>=[33;*~
            set <S-F10>=[34;*~
            set <S-F11>=[23;*$
            set <S-F12>=[24;*$
            "right windows menu key is equal to S-F6 (but not shift version)
            set <S-F13>=[29;*$

            set <F19>=Ou

            set <kHome>=Ow
            set <kEnd>=Oq

            set <kInsert>=Op

            set <xLeft>=Ot
            set <xUp>=Ox
            set <xRight>=Ov
            set <xDown>=Or

            set <S-Insert>=[2$
            set <S-Del>=[3$
            set <S-Home>=[7$
            set <S-End>=[8$
            "set <S-PageUp>=[5$
            "set <S-PageDown>=[6$
            "set <C-Insert>=[2^
            "set <C-Del>=[3^
            set <C-Home>=[7^
            set <C-End>=[8^
            "set <C-PageUp>=[5^
            "set <C-PageDown>=[6^
            set <S-Up>=[a
            set <S-Down>=[b
            set <S-Left>=[d
            set <S-Right>=[c
            "set <C-Up>=Oa
            "set <C-Down>=Ob
            set <C-Left>=Od
            set <C-Right>=Oc
            "set <A-Up>=[A
            "set <A-Down>=[B
            "set <A-Left>=[D
            "set <A-Right>=[C
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
        if v:version >= 704 || (v:version == 704 && has('patch911'))
            if expand("$STY") != "$STY"
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
        if expand("$STY") != "$STY"
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
        "" changing cursor shape (work in xterm and from screen inside of xterm)
        "if expand("$STY") != "$STY"
        "   let &t_SI .= "\eP\e[5 q\e\\"
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

let g:color_scheme = ""
if has("gui_running")
    if g:OS_name == "windows"
        "colorscheme zenburn
        let g:molokai_original = 1
        let g:color_scheme = "molokai"
        let g:airline_theme = "molokai"
    else
        "colorscheme desert
        if &t_Co == 256
            let g:color_scheme = "wombat256mod"
        else
            let g:color_scheme = "wombat"
        endif
        let g:airline_theme = "wombat"
    endif
else
    "no GUI - console mode
    if g:OS_name == "windows"
        "8-color terminal in windows only, zellner looks OK
        let g:color_scheme = "zellner"
        let g:airline_theme = "dark"
    else
        if &t_Co == 256
            let g:color_scheme = "wombat256mod"
        else
            let g:color_scheme = "wombat"
        endif
        let g:airline_theme = "wombat"
    endif
endif
set background=dark
hi clear

"check vundle installation, if installed, then make use of it
let vundle_readme=expand('~/.vim/bundle/Vundle.vim/README.md')
if filereadable(vundle_readme)
"---VUNDLE---
    filetype off                  " required
    "set the runtime path to include Vundle and initialize
    set rtp+=~/.vim/bundle/Vundle.vim
    call vundle#begin()
    " alternatively, pass a path where Vundle should install plugins
    "call vundle#begin('~/some/path/here')

    " let Vundle manage Vundle, required
    Plugin 'gmarik/Vundle.vim'

    Plugin 'scrooloose/syntastic'
    Plugin 'Valloric/YouCompleteMe'
    Plugin 'starcraftman/vim-eclim'
    Plugin 'terryma/vim-multiple-cursors'
    Plugin 'easymotion/vim-easymotion'

    Plugin 'ctrlpvim/ctrlp.vim'  "kien/ctrlp.vim is no longer maintained
    Plugin 'nixprime/cpsm'  "very fast c based fuzzy matcher to replace ctrlp's slow default
    Plugin 'jasoncodes/ctrlp-modified.vim'
    "Plugin 'ivan-cukic/vim-ctrlp-switcher'

    Plugin 'adizero/vim-togglecursor'
    Plugin 'adizero/vim-clang-format'
    Plugin 'adizero/cscope_maps.vim'

    Plugin 'vim-scripts/vcscommand.vim'
    Plugin 'mikeage/ccase.vim'

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
    "Plugin 'tpope/vim-commentary'
    Plugin 'wilywampa/vim-commentary'

    Plugin 'mhinz/vim-signify'

    Plugin 'vim-airline/vim-airline'
    Plugin 'vim-airline/vim-airline-themes'

    "Plugin 'cohama/lexima.vim'
    "Plugin 'rstacruz/vim-closer'

    Plugin 'wellle/targets.vim'

    "Plugin 't9md/vim-textmanip'
    "Plugin 'stefandtw/quickfix-reflector.vim'

    "Plugin 'vim-scripts/taglist.vim'
    Plugin 'majutsushi/tagbar'

    Plugin 'mbbill/code_complete'
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

    " All of your Plugins must be added before the following line
    call vundle#end()            " required
    filetype plugin indent on    " required
"---VUNDLE---
else
    filetype plugin indent on
endif

"Todo: enable Eclim (by removing following line)
let g:EclimDisabled = "defined"

if v:version < 704
    let g:loaded_youcompleteme = 1 "too old Vim => disable YouCompleteMe
endif

let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'
"Do not ask when starting vim
let g:ycm_confirm_extra_conf = 0
"set tags += $HOME/tmp/ycm.tags
function! YCM_tagfiles()
    if expand("$CSCOPE_FILES_DIR") != "$CSCOPE_FILES_DIR"
        return [expand("$CSCOPE_FILES_DIR") . '/ycm.tags']
    else
        return [expand("$HOME") . '/tmp/ycm.tags']
    endif
endfunction
let g:ycm_collect_identifiers_from_tags_files = 1

let g:ycm_add_preview_to_completeopt = 0
let g:ycm_key_invoke_completion = '<C-Space>'
let g:ycm_cache_omnifunc = 0  "takes simply too much memory in big projects (1GB of sources)

let g:ycm_key_list_select_completion = ['<Down>']
let g:ycm_key_list_previous_completion = ['<Up>']

let g:ycm_always_populate_location_list = 1

let g:ycm_disable_for_files_larger_than_kb = 5000

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
        \ 'mail' : 1
        \}

function! Multiple_cursors_before()
    "let g:ycm_auto_trigger = 0
    if exists('b:ycm_largefile')
        let b:old_ycm_status = 0
    else
        let b:old_ycm_status = 1
        let b:ycm_largefile = 1
    endif
endfunction

function! Multiple_cursors_after()
    "let g:ycm_auto_trigger = 1
    if b:old_ycm_status == 1
        unlet b:ycm_largefile
    endif
endfunction

" make YCM completion via ycm_key_invoke_completion work only after . or ->
" otherwise it is unusably slow (and breaks YCM altogether on huge source bases)
function! YcmConditionalComplete()
    "check if after . or ->, then allow, otherwise ignore
    "check filetype (ft) to prevent for c,c++ only, otherwise allow everywhere
    "(heavy search can be still cancelled by CTRL+C)
    if &ft == "c" || &ft == "cpp"
        let l:start = col('.')-3
        if l:start < 0
            let l:start = 0
        endif
        let l:part = strpart( getline('.'), l:start, col('.')-1 )
        if l:part =~ '.\.$' || part =~ '->$' || part =~ '::$'
            return "\<C-X>\<C-O>\<C-P>"
        else
            return ""
        endif
    else
        return "\<C-X>\<C-O>\<C-P>"
        "return ""
    endif
endfunction

"inoremap g:ycm_key_invoke_completion <C-r>=YcmConditionalComplete()<CR>
exe "inoremap ".g:ycm_key_invoke_completion." <C-r>=YcmConditionalComplete()<CR>"

let s:home_base_path=$HOME

" ============================
" =           Paths          =
" ============================
" replace all directory separators in runtimepath to OS specific
let &runtimepath=substitute(&runtimepath, '[\/]', g:OS_dir_separator, 'g')

let g:default_search_path = substitute('.,**,../include/**,../src/**,' . expand("$ROOT") . '/panos,' . g:OS_system_includes_dir, '[\/]', g:OS_dir_separator, 'g')
" set default path
let &path=g:default_search_path

"set suffixesadd=.h

" ============================
" =         Sessions         =
" ============================
" remove possible trailing slash before creating directory $HOME/.vim/sessions
let g:user_sessions_home = substitute($HOME, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'sessions'
let g:user_session_filename = 'session.vim'

silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_sessions_home

"autocmd VimEnter * call LoadSession()
"autocmd VimLeave * call SaveSession()
function! SaveSession()
    execute 'mksession! ' . g:user_sessions_home . g:OS_dir_separator . g:user_session_filename
endfunction
function! LoadSession()
    "if argc() == 0
        if v:version > 700
            tabfirst
            tabonly
        endif
        execute 'source ' . g:user_sessions_home . g:OS_dir_separator . g:user_session_filename
    "endif
endfunction

" open files with the cursor at the last remembered position
autocmd! BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

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
if exists("+relativenumber")
    set relativenumber      " relative line numbers
endif
set cindent
set autoindent
if has("mouse")
    set mouse=a             " use mouse in xterm to scroll
endif
set scrolloff=5         " 5 lines before and after the current line when scrolling
set ignorecase          " ignore case
set smartcase           " but don't ignore it, when search string contains uppercase letters
set hid                 " allow switching buffers, which have unsaved changes
set shiftwidth=4        " 4 characters for indenting
set showmatch           " showmatch: Show the matching bracket for the last ')'?

set nowrap              " don't wrap by default
syn on
set confirm

set hlsearch

set nostartofline
"set shiftround

"set autoread
"set display+=uhex
set display+=lastline

if has("wildmenu")
    set wildmenu
endif

set tabpagemax=25

"needs to be after syn on (syntax on)
let g:colors_name = g:color_scheme
try
    exec "colorscheme " . g:color_scheme
catch /:E185:/
    " E185 colorscheme not found
    " just ignore
endtry
let g:color_scheme_loaded = 1

"refresh airline after colorscheme load, if already loaded
if exists("#airline")
    call airline#load_theme()
else
    set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
endif

if has("cscope")
    set cscopetag
    set cscopequickfix=s-,c-,d-,i-,t-,e-,f0,g0      " cscope will fill results into quickfix window (possible to open via :copen command, move with <F11><F12>)
    if v:version > 704 || (v:version == 704 && has('patch2033'))
        set cscopequickfix+=a-
    endif
endif

imap jk <Esc>

" follow visual lines (instead of lines) - comes into play when line wrapping is on
map <A-Down> gj
map <A-Up> gk
imap <A-Up> <C-o>gk
imap <A-Down> <C-o>gj

"reselect visual selection after <,> movements
vnoremap < <gv
vnoremap > >gv
" make Y behave like other capitals
map Y y$
" map u/U in visual mode to undo (instead of to lowercase/to uppercase)
vnoremap u <Esc>u
vnoremap U <Esc>U

"Todo: map <C-S> and <C-Q> to something interesting (first need to claim them from terminal)
noremap <C-S> :CtrlPTag<CR>
"noremap! <C-S> <C-o>:CtrlPTag<CR>
noremap <C-Q> :CtrlPBufTag<CR>
"noremap! <C-Q> <C-o>:CtrlPBufTag<CR>

" force saving files that require root permission
"Todo: improve - slows down entering of w character in command mode
cmap w!! %!sudo tee > /dev/null %

" do not move cursor during yank in visual mode
vmap y ygv<Esc>

" search for visually selected text
vnoremap // y/<C-R>"<CR>
vnoremap ?? y?<C-R>"<CR>

"better jumping to function beginning/end (does not require {,} to be in the
"first column of the file

function! My_PreSection(count, bracket_to_find, search_flags, move_to_execute)
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


set errorformat^=%-GIn\ file\ included\ from\ %f:%l:%c:,%-GIn\ file\ included\ from\ %f:%l:%c\\,,%-GIn\ file\ included\ from\ %f:%l:%c,%-GIn\ file\ included\ from\ %f:%l,%-G%*[\ ]from\ %f:%l:%c
set errorformat^=%-G%n:%l:%c%.%#\ Tar\'ing\ up\ changed\ files,%-GBuilding\ list\ of\ req'd\ files\ -\ starting\ at\ %s\ %n:%l:%c\ %.%#,%-GDone\ at\ %s\ %n:%l:%c\ %.%#,%-G%n:%l:%c\ %m\ Sending\ changed\ files\ to\ server,%-G%n:%l:%c\ %s\\,\ Remotely\ executing\ %.%#,%-G###\ %n:%l:%c%.%#\,\ Rsyncing\ files\ with\ \ server\ %.%#,%-G%.%#%n:%l:%c%.%#\,\ Remotely\ SSH\ executing\ %.%#

set laststatus=2

if v:version >= 700
    " set completion options
    set completeopt=menu,longest ",longest,preview

    " dictionary completion CTRL+X CTRL+K in insert mode
    set dictionary=/usr/share/dict/words
    " thesaurus synonyms completion CTRL+X CTRL+T in insert mode
    "set thesaurus=/usr/share/????
    " spell checking (switchable by <Leader>s), CTRL+X CTRL+S in insert mode
    set nospell
    set spelllang=en
    set spellsuggest=5
endif

" ============================
" =       Window title       =
" ============================
"Xxx: this sets screen tab's caption
"let &t_ts="\ek"
"let &t_fs="\e\"
"don't reset screen tab's caption to flying...
"auto VimLeave * let &t_ts="\ek\e\"

set title

":auto BufEnter * let &titlestring= expand("%:t") . " (" . expand($REL) . "-" . expand($RELP) . " " . expand($VPLOAD) . expand($HOST_TAG) . " " . expand($SS) . " | " . expand($ROOT) . ")"
if $REL == ""
    :auto BufEnter * let &titlestring= "%m%r" . expand("%:t")
else
    if $VPLOAD != ""
        if $REL != $RELP
            :auto BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . "-" . $RELP . " " . $VPLOAD . $HOST_TAG . " " . $SS . " | " . $ROOT . ")"
        else
            :auto BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . " " . $VPLOAD . $HOST_TAG . " " . $SS . " | " . $ROOT . ")"
        endif
    else
        :auto BufEnter * let &titlestring= "%m%r" . expand("%:t") . " (" . $REL . " " . $CURRENT_LOCATION . " | " . $ROOT . ")"
    endif
endif

" :auto BufEnter * let &titlestring = hostname() . "/" . expand("%:p")
"Here the window title is reset when the user enters a new buffer. It contains the hostname, a forward slash, then the full path of the current file - for an explanation of the %:p syntax see the Filename Modifiers section of the Executing External Commands recipe..
"
"Another example is to display the value of an environment variable in the window title along with the filename. For instance, Ruby on Rails developers could prefix the filename with the value of RAILS_ENV, which indicates whether the application is in development, production, staging, or testing mode:
"let &titlestring=expand($RAILS_ENV) . ": " . expand("%:t")
"One last trick is to embed the value of an external command in the window title using the %{system('command')} syntax. This could be used to display the name of the current branch, if using a version control system, or indicate whether the project's unit tests are passing or failing.

" ============================
" =          Folding         =
" ============================
if v:version > 600
    if has("folding")
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

" ============================
" =Working with multiple tabs=
" ============================
if v:version > 700
    " navigating multiple tabs - works only in graphical modes (gVim)
    nmap <C-Tab> :tabnext<Enter>
    nmap <C-S-Tab> :tabprev<Enter>
    imap <C-Tab> <C-o>:tabnext<Enter>
    imap <C-S-Tab> <C-o>:tabprev<Enter>
    vmap <C-Tab> <Esc>:tabnext<Enter>gv
    vmap <C-S-Tab> <Esc>:tabprev<Enter>gv

    " simplified movement through windows
    nmap <C-Up> <C-S-Up>
    nmap <C-Down> <C-S-Down>
    imap <C-Up> <C-S-Up>
    imap <C-Down> <C-S-Down>
    vmap <C-Up> <C-S-Up>
    vmap <C-Down> <C-S-Down>
endif

" =====================================
" =Movement with CTRL,SHIFT and ARROWS=
" =====================================
if v:version > 700
    " CTRL+SHIFT+UP/DOWN works only in graphical modes
    nmap <C-S-Up> <C-w>W
    nmap <C-S-Down> <C-w>w
    imap <C-S-Up> <C-o><C-w>W
    imap <C-S-Down> <C-o><C-w>w
    vmap <C-S-Up> <C-w>Wgv
    vmap <C-S-Down> <C-w>wgv
endif

" ======================================
" =Windows editors selection short-cuts=
" ======================================
" word selection
nmap <S-Left> vbge<Space>
nmap <S-Right> vew<BS>
imap <S-Left> _<Esc>mz"_xv`z<BS>obge<Space>
imap <S-Right> _<Esc>my"_xi<Right><C-o><BS>_<Esc>mz"_xv`yo`z
vmap <S-Left> bge<Space>
vmap <S-Right> ew<BS>

" down/up selection
nmap <S-Down> v<Down>
nmap <S-Up> v<Up>
imap <S-Down> _<Esc>mz"_xv`zo`z<Down><Right><BS><BS>
imap <S-Up> _<Esc>mz"_xv`z<Up>o`z<BS>o
vmap <S-Down> <Down>
vmap <S-Up> <Up>

" home/end selection
nmap <S-Home> v<Home>
nmap <S-End> v<End>
imap <S-Home> _<Esc>mz"_s<C-o><Left><C-o>`z<Esc>v<Home>
imap <S-End> _<Esc>mz"_xv`zo<End>
vmap <S-Home> <C-S-Home>
vmap <S-End> <C-S-End>

" indentation with Tab/S-Tab on selected blocks
vnoremap <Tab> >gv
vnoremap <S-Tab> <LT>gv

" indentation by one space with Space/Backspace on selected blocks
vnoremap <Backspace> <Esc>:let origsw=&sw<CR>:let &sw=1<CR>gv<<Esc>:let&sw=origsw<CR>gv
vnoremap <Space> <Esc>:let origsw=&sw<CR>:let &sw=1<CR>gv><Esc>:let&sw=origsw<CR>gv

" move selected lines
vnoremap <C-j> :m '>+1<CR>gv=gv
vnoremap <C-k> :m '<-2<CR>gv=gv
vnoremap <C-S-j> :m '>+1<CR>gv
vnoremap <C-S-k> :m '<-2<CR>gv
" duplicate (above) selected lines
vnoremap <C-d> :t .-1<CR>gv

" half page down/up selection (gVim)
nmap <S-PageDown> v<End><C-d><End>
nmap <S-PageUp> v<Home><C-u>
imap <S-PageDown> _<Esc>mz"_xv`zo<End><C-d><End>
imap <S-PageUp> _<Esc>mz"_xv`z<BS>o<Home><C-u>
vmap <S-PageDown> <End><C-d><End>
vmap <S-PageUp> <Home><C-u>

" word deletion
imap <C-BS> <C-w>
"imap <C-Del> _<Esc>mzew<BS>i<Del><Esc>v`z"_c
imap <C-Del> <C-o>de

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

" resolves even with :: in the cWORD, but without following (), ->, ., , e.g. DbgwController::getPort vs. DbgwController::getPort()
function! SophTag(str)
        "SophTag(...)
        "let args=a:000
        "for a in args
        "   echo a
        "endfor
        for i in [0,1]
            if &csto == i
                let search_cmd="cscope find g "
            else
                let search_cmd="tag "
            endif

            if a:str != ""
                try
                    "echo search_cmd.a:str
                    exec search_cmd.a:str
                    return 0  " search no more, result found
                catch /:E325:/
                    " ATTENTION when opening file
                    return 0
                catch /:E562:\|:E567:\|:E257:\|:E259:\|:E426:/
                    " we will continue with cWORD and cword searches
                endtry
            endif
            try
                let l:cww=substitute(expand("<cWORD>"), '[^A-Za-z_:]', '', 'ga')
                "echo search_cmd.l:cww
                exec search_cmd.l:cww
                return 0  " search no more, result found
            catch /:E325:/
                " ATTENTION when opening file
                return 0
            catch /:E562:\|:E567:\|:E257:\|:E259:\|:E426:/
                " E562 bad usage for cstag - obviously cWORD contains special characters
                " E567 no cscope connections
                " E257 cstag tag not found
                " E259 no matches found for cscope query
                " E426 tag not found
                try
                    "echo search_cmd.expand("<cword>")
                    exec search_cmd.expand("<cword>")
                    return 0  " search no more, result found
                catch /:E325:/
                    " ATTENTION when opening file
                    return 0
                catch /:E562:\|:E567:\|:E257:\|:E259:\|:E426:/
                    " not found
                endtry
            endtry
        endfor
        echohl WarningMsg
        if a:str != ""
            echo "Sorry, no tag generated for ".a:str." or ".expand("<cWORD>")." or ".expand("<cword>")
        else
            echo "Sorry, no tag generated for ".expand("<cWORD>")." or ".expand("<cword>")
        endif
        echohl None
endfunction

nmap <C-]> :call SophTag("")<Enter>
imap <C-]> <C-o>:call SophTag("")<Enter>
"Todo: improve this (it messes last yank buffer 0)
vmap <C-]> y<Esc>:call SophTag("<C-r>0")<Enter>gv

if v:version >= 703
    nmap <S-F7> :UndotreeToggle<Enter>
    imap <S-F7> <C-o>:UndotreeToggle<Enter>
    vmap <S-F7> <Esc>:UndotreeToggle<Enter>gv
else
    nmap <S-F7> :call SophHelp()<Enter>
    imap <S-F7> <C-o>:call SophHelp()<Enter>
    vmap <S-F7> <Esc>:call SophHelp()<Enter>gv
endif

" F2 to save
nmap <F2> :w<Enter>
imap <F2> <C-o>:w<Enter>
vmap <F2> <Esc>:w<Enter>gv

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

map <silent> <F3> :call Header_switch()<CR>
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

nmap <F4> :call Fxxd()<Enter>
imap <F4> <C-o>:call Fxxd()<Enter>
vmap <F4> <Esc>:call Fxxd()<Enter>gv

function! MyDiff()
    let opt = ""
    if &diffopt =~ "icase"
        let opt = opt . "-i "
    endif
    if &diffopt =~ "iwhite"
        "let opt = opt . "-b "
        let opt = opt . "-w "
    endif
    if exists("t:diffoptions")
        let opt = opt . t:diffoptions
    endif
    silent execute "!diff -a --binary " . opt . " " . v:fname_in . " " . v:fname_new . " > " . v:fname_out
    "Note: redraw has problems with Vim compiled in tiny version (even though the function is not used)
    execute "redraw!"
endfunction
"ignore whitespace differences
set diffopt=filler,context:6
"almost the same as without setting diffexpr (but can be easily changed in the future)
set diffexpr=MyDiff()  "produces some artifacts on command line after execution

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

nmap <F8> :TagbarToggle<Enter>
imap <F8> <C-o>:TagbarToggle<Enter>
vmap <F8> <Esc>:TagbarToggle<Enter>gv

"nmap <S-F8> :TlistToggle<Enter>
"imap <S-F8> <C-o>:TlistToggle<Enter>
"vmap <S-F8> <Esc>:TlistToggle<Enter>gv

nmap <S-F6> :call LoadSession()<Enter>
imap <S-F6> <C-o>:call LoadSession()<Enter>
vmap <S-F6> <Esc>:call LoadSession()<Enter>gv

nmap <S-F5> :call SaveSession()<Enter>
imap <S-F5> <C-o>:call SaveSession()<Enter>
vmap <S-F5> <Esc>:call SaveSession()<Enter>gv

" F10 to quit
nmap <F10> :q<Enter>
imap <F10> <C-o>:q<Enter>
vmap <F10> <Esc>:q<Enter>gv
"map ^_ gf

nmap <S-F10> :qa<Enter>
imap <S-F10> <C-o>:qa<Enter>
vmap <S-F10> <Esc>:qa<Enter>gv

"comm! -nargs=? -bang A call AlternateFile("n<bang>", <f-args>)
"abbreviate/iabbrev/cabbrev

" command mode abbreviation of tt as tabnew | tag <args>
comm! -nargs=1 -complete=tag TT tabnew | cstag <args>
cabbrev tt <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'TT' : 'tt')<CR>

function! Quickfix_window_move(type, direction)
    "ignore error E553: no more items and jump to first/last one
    try
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
        endif
    catch
        "silently discard other errors
"        echohl WarningMsg
"        if a:type == "quickfix"
"            echo "No further move is possible in quickfix list"
"        else
"            echo "No further move is possible in location list"
"        endif
"        echohl None
    endtry
endfunction

" Quickfix window - prev/next line jumps
nmap <F11> :call Quickfix_window_move("quickfix", "prev")<Enter>
imap <F11> <C-o>:call Quickfix_window_move("quickfix", "prev")<Enter>
vmap <F11> <Esc>:call Quickfix_window_move("quickfix", "prev")<Enter>v

nmap <F12> :call Quickfix_window_move("quickfix", "next")<Enter>
imap <F12> <C-o>:call Quickfix_window_move("quickfix", "next")<Enter>
vmap <F12> <Esc>:call Quickfix_window_move("quickfix", "next")<Enter>v

" Location window - prev/next line jumps
nmap <S-F11> :call Quickfix_window_move("location", "prev")<Enter>
imap <S-F11> <C-o>:call Quickfix_window_move("location", "prev")<Enter>
vmap <S-F11> <Esc>:call Quickfix_window_move("location", "prev")<Enter>v

nmap <S-F12> :call Quickfix_window_move("location", "next")<Enter>
imap <S-F12> <C-o>:call Quickfix_window_move("location", "next")<Enter>
vmap <S-F12> <Esc>:call Quickfix_window_move("location", "next")<Enter>v

" common leader mappings
let mapleader = ','
map <Leader>l :set invlist!<CR>
map <Leader>n :set nu!<CR>
map <Leader>N :set rnu!<CR>
map <Leader>I :set diffopt-=iwhite<CR>
map <Leader>i :set diffopt+=iwhite<CR>

function! LetDiffOptionsForTab(options)
    let t:diffoptions=a:options
    diffupdate
endfunction
map <Leader>D :call LetDiffOptionsForTab("")<CR>
map <Leader>d :call LetDiffOptionsForTab("-d")<CR>

map <Leader>s :set spell!<CR>
map <Leader>h :set hls!<CR>
map <Leader>H :nohlsearch<CR>
map <Leader>f :set foldenable!<CR>
map <Leader>w :set wrap!<CR>

map <Leader>p :set paste!<CR>

" YouCompleteMe automatic code completion global toggle
function! YcmGlobalToggle()
    if !exists('g:ycm_largefile')
        let g:ycm_largefile = 1
        "let g:ycm_auto_trigger = 0 "use this to toggle automatic(as you type) completion and semantic triggers (., ::, ->) as well
        "let g:ycm_min_num_of_chars_for_completion = 99 "use this instead to keep semantic triggers
        echo "YouCompleteMe automatic completion is turned off globally"
    else
        unlet g:ycm_largefile
        "let g:ycm_auto_trigger = 1 "use this to toggle automatic(as you type) completion and semantic triggers (., ::, ->) as well
        "let g:ycm_min_num_of_chars_for_completion = 2 "use this instead to keep semantic triggers
        echo "YouCompleteMe automatic completion is turned on globally"
    endif
endfunction
map <Leader>Y :call YcmGlobalToggle()<CR>

" YouCompleteMe automatic code completion buffer toggle
function! YcmLocalToggle()
    if !exists('b:ycm_largefile')
        let b:ycm_largefile = 1
        echo "YouCompleteMe automatic completion is turned off for current buffer"
    else
        unlet b:ycm_largefile
        echo "YouCompleteMe automatic completion is turned on for current buffer"
    endif
endfunction
map <Leader>y :call YcmLocalToggle()<CR>

" mouse integration switching
function! SwitchMouse()
    let opt = ""
    if &mouse =~ "a"
        set mouse=
    else
        set mouse=a
    endif
endfunction
map <Leader>m :call SwitchMouse()<CR>

" path leader mappings
"map <Leader>0 :let &path=g:default_search_path<CR>

" ============================
" =        GUI options       =
" ============================
if has("gui_running")
    if v:version > 700
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

    if g:OS_name == "windows"
        "set guifont=Lucida_Console:h8:cEASTEUROPE
        "set guifont=Dina:h8:cANSI
        silent! set guifont=Envy\ Code\ R:h11:cEASTEUROPE
        if &guifont != 'Envy Code R:h11:cEASTEUROPE'
            silent! set guifont=Lucida_Console:h11:cEASTEUROPE
        endif
        set guioptions="aegmrLtT

        " maximize window on start
        autocmd GUIEnter * simalt ~X
    else
        silent! set guifont=Envy\ Code\ R\ 11
        if &guifont != 'Envy Code R 11'
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
function! CleverTabCompletion()
   " do we have omni completion available
   if &omnifunc != ''
      "use omni-completion 1. priority
      return "\<C-X>\<C-O>"
   elseif &dictionary != ''
      " no omni completion, try dictionary completion
      return "\<C-K>"
   else
      "use omni completion or dictionary completion
      "use known-word completion
      return "\<C-N>"
  endif
endfunction

function! TabCompletion()
    if pumvisible()
        return "\<C-N>"
    else
        return "\<Tab>"
    endif
endfunction

function! ShiftTabCompletion()
    "check if at beginning of line or after a space
    "let g:str = strpart( getline('.'), col('.'))
    if strpart( getline('.'), 0, col('.')-1 ) =~ '\t\+\s*$'
        execute "normal F\<C-I>"
        normal x
        return ""
    elseif strpart( getline('.'), col('.')-1 ) =~ '^\s*\t\+'
        normal m`
        execute "normal f\<C-I>"
        normal x
        normal ``
        return ""
    elseif strpart( getline('.'), 0, col('.')-1 ) =~ '^\s*$'
        execute "normal \<LT>\<LT>"
        return ""
    else
        "return CleverTabCompletion()
        if pumvisible()
            return "\<C-P>"
        else
            return "\<S-Tab>"
        endif
    endif
endfunction
" bind function to the tab key
imap <Tab> <C-r>=TabCompletion()<CR>
imap <S-Tab> <C-r>=ShiftTabCompletion()<CR>

" bind ,a to grep word under cursor
nmap <Leader>a :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

" bind \ to Ag - similar to /, just enter search string
nmap \ :grep!<SPACE>

" ============================
" =        OS specific       =
" ============================
if g:OS_name == "windows"
    set grepprg=findstr\ /R\ /S\ /N
else
    set grepprg=grep\ -nH\ $*\ /dev/null

    " The Silver Searcher
    if executable('ag')
      " Use ag over grep
      set grepprg=ag\ --nogroup\ --nocolor
      "\ --column
      nmap <Leader>a :Ag "\b<C-R><C-W>\b"<CR>:cw<CR>
      nmap \ :Ag<SPACE>
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

" ============================
" =      Tagbar plug-in      =
" ============================
let g:tagbar_ctags_bin = g:OS_ctags_command
let g:tagbar_left = 1
let g:tagbar_autofocus = 1

" ============================
" =      TagList plug-in     =
" ============================
let Tlist_Ctags_Cmd = g:OS_ctags_command
let Tlist_Show_Menu = 0  " there is a bug in gVim with taglist show menu turned on (E792: Empty menu name)

" ============================
" =   CodeComplete plug-in   =
" ============================
let g:completekey ='<C-B>'

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
" autodetects from l:shiftwidth \ "IndentWidth" : "4",
" autodetects from l:expandtab \ "UseTab" : "false",
" autoselects based on clang_format#code_style \ "BasedOnStyle" : "Google",
"Todo: autoselect Braces formatting based on the edited file surrounding context (default to Allman)
let g:clang_format#code_style = "Google"
let g:clang_format#style_options = { "BreakBeforeBraces" : "Allman" , "ColumnLimit" : "120"}
let g:clang_format#auto_formatexpr = 1
let g:clang_format#no_operator = 1

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
nmap <silent> <Leader>dc <Plug>ToggleDiffCharAllLines
nmap <silent> <Leader>dC <Plug>ToggleDiffCharCurrentLine

" === vim-commentary ===
"Xxx: insert mode mapping does not work
"Xxx: <C-/> is the same key as <C-_> in terminals
"Todo: solve readonly file warning, when commenting in RO file (first change)

nmap <C-_> gc
"does not work in column one, when trying to comment a line
nmap <C-_><C-_> gcgc
"not really useful
"nmap <C-_><C-_><C-_> :set commentstring=/*%s*/<CR>gcgc

"does not work properly
""imap <C-_> <C-o>gc<Right>

"reselects after commenting, beware of uppercasing with keypress `u` in visual mode
vmap <C-_> gcgv
"switch to // comments in c/ccp files
autocmd FileType c set commentstring=//%s
autocmd FileType cpp set commentstring=//%s

" === quickfix-reflector
let g:qf_join_changes = 1
let g:qf_write_changes = 0

" === MRU ===
"let g:MRU_Open_File_Use_Tabs = 1 "does not work as it should (use t from MRU window)

" === vim-surround ===
let g:surround_no_insert_mappings = 1 "disable insert mode mappings (unnecessary ?)

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
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 3  "value of 1 - autoclose and autoopen clashes with YCM
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0

let g:syntastic_yang_pyang_args = "--ignore-error=LEAFREF_IDENTIFIER_BAD_NODE --ignore-error=UNUSED_IMPORT"
" --ignore-error=LEAFREF_IDENTIFIER_NOT_FOUND --ignore-error=BAD_VALUE"  "only for pyang-1.7 and higher (does not work 100% even then)

let g:syntastic_enable_perl_checker = 1  "Perl is a bit special (this can be dangerous: perl -c execing current file)
let g:syntastic_perl_checkers = ["perl"]

"let g:syntastic_debug_file = "~/syntastic.log"
"let g:syntastic_debug = 33

"following diffsplit override is needed to make Syntastic understand that
"particular window is going to be diff windows and hence not extra Syntastic
"window should be displayed
command! -nargs=* -complete=file Diffsplit let &diff=1 | diffsplit <args>
cabbrev diffsplit <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Diffsplit' : 'diffsplit')<CR>

""" "TODO enable nagelfar, when source-ing of .tcl script is resolved (otherwise too many errors are shown)
""" let g:syntastic_tcl_checkers = []
""" "Pygments package not found
""" let g:syntastic_rst_checkers = []
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [ "sh", "python", "perl", "yang", "mib", "cfg" ], 'passive_filetypes': [ "tcl", "vim", "rst" ] }

" ==========================
" = Miscellaneous functions=
" ==========================
" Generates ctags file named tags for specified folder - simple version
function! MyCTags(fdir)
    " let l:path = "."
    if a:fdir == ""
        let l:path = resolve (expand("%:p:h"))
    else
        let l:path = a:fdir
    endif

    silent! execute "!" . g:OS_ctags_command . " --languages=C,C++ -R --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+fq --tag-relative=yes " . l:path
    "Note: redraw has problems with Vim compiled in tiny version (even though the function is not used)
    execute "redraw!"
endfunction

"comm! CtagsP call MyCTags('.. ' . g:OS_system_includes_dir)
"comm! CtagsC call MyCTags('. ' . g:OS_system_includes_dir)
"comm! CtagsQ call MyCTags('.')

" Generates ctags and cscope tags for current folder MyGenTagsCmd(gt), or $ROOT folder MyGenTagsCmd(rt)
function! MyGenTagsCmd(gtcmd, ...)
    if (a:gtcmd == "gt")
"       silent! execute "!" . "ctags --languages=C,C++ --fields=+ia --extra=+fq --tag-relative=yes -R -f tags --totals=yes ; cscope -b -q -u -R -f cscope.out"
"       cs add cscope.out
"       if &tags != ""
"           let &tags="tags" . "," . &tags
"       else
"           let &tags.="tags"
"       endif
        let l:path = system("pwd")
        let l:path = substitute(l:path,'\n','','')
    elseif (a:gtcmd == "rt")
        let l:path = expand("$ROOT")
    endif

    let l:temp_file_list = system("echo /tmp/cf.\$USER.\$RANDOM")

    silent! execute "!" . "find " . l:path . " \\( -name \"*.h\" -o -name \"*.hh\" -o -name \"*.hpp\" -o -name \"*.c\" -o -name \"*.cc\" -o -name \"*.cpp\" -o -name \"*.java\" -o -name \"*.mk\" -o -name \"*.db\" -o -name \"*.sh\" -o -name \"*.cfg\" \\) | grep -v \"/obj/\" > " . l:temp_file_list
    silent! execute "!" . "ctags --languages=C,C++ --fields=+ia --extra=+fq --tag-relative=yes -f " . l:path . "/tags --totals=yes -L " . l:temp_file_list
    silent! execute "!" . "cscope -b -q -u -f " . l:path . "/cscope.out" . " -i " . l:temp_file_list
    silent! execute "!" . "rm " . l:temp_file_list
    execute "cs add ". l:path . "/" . "cscope.out"
    if &tags != ""
        let &tags=l:path . "/" . "tags" . "," . &tags
    else
        let &tags=l:path . "/" . "tags"
    endif

    try
        cs reset
    catch /:E568:/
        " E568 cscope problem: database already added
        " just ignore
    endtry
    "Note: redraw has problems with Vim compiled in tiny version (even though the function is not used)
    execute "redraw!"
endfunction

"com! -nargs=* Egt call MyGenTagsCmd("gt", <f-args>)
"com! -nargs=* Ert call MyGenTagsCmd("rt", <f-args>)

" XML formatter (works with selected ranges) - uses xmllint internally
function! DoFormatXML() range
    " Save the file type
    let l:origft = &ft

    " Clean the file type
    set ft=

    " Add fake initial tag (so we can process multiple top-level elements)
    exe ":let l:beforeFirstLine=" . a:firstline . "-1"
    if l:beforeFirstLine < 0
        let l:beforeFirstLine=0
    endif
    exe a:lastline . "put ='</PrettyXML>'"
    exe l:beforeFirstLine . "put ='<PrettyXML>'"
    exe ":let l:newLastLine=" . a:lastline . "+2"
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
nnoremap <Leader><Space> :%TrimSpacesConfirm<CR>
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
"au BufWritePre /tmp/* setlocal noundofile

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

function! CscopeCtagsSearch(word)
    let csto_saved=&csto
    let &csto=0
    "echomsg a:word
    "exe "cstag " . a:word
    try
        call SophTag(a:word)
    finally
        let &csto=csto_saved
        unlet csto_saved
    endtry
endfunction

nnoremap g<LeftMouse> <LeftMouse>:call CscopeCtagsSearch("")<CR>
nnoremap g<RightMouse> <C-T>
nmap <C-LeftMouse> g<LeftMouse>
nmap <C-RightMouse> g<RightMouse>

nnoremap z<LeftMouse> <LeftMouse>:exe "cs f s " . expand("<cword>")<CR>
nnoremap z<RightMouse> <LeftMouse>:exe "cs f c " . expand("<cword>")<CR>
nmap <A-LeftMouse> z<LeftMouse>
nmap <A-RightMouse> z<RightMouse>

nnoremap <X1Mouse> <C-O>
nnoremap <X2Mouse> <C-I>
nmap <RightMouse><LeftMouse> <X1Mouse>
"nmap <LeftMouse><RightMouse> <X2Mouse> "causes delay, when selecting text by dragging with LeftMouse pressed

"automatic copy after left button release (not sure about usefulness)
"vnoremap <LeftRelease> <LeftRelease>y

" moving through cscope/ctags
nmap <C-S-Right> :call CscopeCtagsSearch(expand("<cword>"))<Enter>
nmap <C-S-Left> <C-T>
imap <C-S-Right> <C-o>:call CscopeCtagsSearch(expand("<cword>"))<Enter>
imap <C-S-Left> <C-o><C-T>
vmap <C-S-Right> y:call CscopeCtagsSearch("<C-R>"")<Enter>
vmap <C-S-Left> <Esc><C-T><Enter>


" when .vimrc is edited, reload it
if has('autocmd')
"    autocmd! BufWritePost "*" . g:OS_dir_separator . g:OS_vimrc source %
    execute "autocmd! BufWritePost " . g:OS_vimrc . " source %"
endif

"Todo: check Vim startup time via: vim --startuptime /tmp/startup.txt
"

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
        vert new
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
    " tabs are forbidden in SR projects
    set expandtab

    " start in $PANOS folder in CtrlP file mode
    let g:ctrlp_working_path_mode = 'p'

    " ,f to show current line nested feature info for setup_cli.cfg/teardown_cli.cfg updates
    map <Leader>f :call ToggleFeatureInfoWindow("")<CR>

    nmap <F1> :execute "!sr_cscope.sh update"<CR> :cs reset<CR> :<CR>
    imap <F1> <C-o>:execute "!sr_cscope.sh update"<CR> <C-o>:cs reset<CR> <C-o>:<CR>
    vmap <F1> <Esc>:execute "!sr_cscope.sh update"<CR> :cs reset<CR> :<CR>gv

    nmap <S-F1> :execute "!sr_cscope.sh mibupdate"<CR> :let &l:enc=&l:enc<CR>
    imap <S-F1> <C-o>:execute "!sr_cscope.sh mibupdate"<CR> <C-o>:let &l:enc=&l:enc<CR>
    vmap <S-F1> <Esc>:execute "!sr_cscope.sh mibupdate"<CR> :let &l:enc=&l:enc<CR>gv
else "other projects
    " F1 to display help
    nmap <F1> :call SophHelp()<Enter>
    imap <F1> <C-o>:call SophHelp()<Enter>
    vmap <F1> <Esc>:call SophHelp()<Enter>gv
endif

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

    nmap <F9> :VCSBlame!<Enter>
    imap <F9> <C-o>:VCSBlame!<Enter>
    vmap <F9> <Esc>:VCSBlame!<Enter>gv

    nmap <S-F9> :VCSLog<Enter>
    imap <S-F9> <C-o>:VCSLog<Enter>
    vmap <S-F9> <Esc>:VCSLog<Enter>gv

elseif g:VCS_name == "clearcase"
    let g:loaded_ccase = 0

    nmap <F5> :call DiffOrig()<Enter>
    imap <F5> <C-o>:call DiffOrig()<Enter>
    vmap <F5> <Esc>:call DiffOrig()<Enter>gv

    nmap <F6> :call DiffCCPred()<Enter>
    imap <F6> <C-o>:call DiffCCPred()<Enter>
    vmap <F6> <Esc>:call DiffCCPred()<Enter>gv

    nmap <F9> :Ctxlsv<Enter>
    imap <F9> <C-o>:Ctxlsv<Enter>
    vmap <F9> <Esc>:Ctxlsv<Enter>gv

elseif g:VCS_name == "ecms"
    nmap <F5> :call MyEcmsGetCmd("vdload")<Enter>
    imap <F5> <C-o>:call MyEcmsGetCmd("vdload")<Enter>
    vmap <F5> <Esc>:call MyEcmsGetCmd("vdload")<Enter>gv

    nmap <F6> :call MyEcmsGetCmd("vdlatest")<Enter>
    imap <F6> <C-o>:call MyEcmsGetCmd("vdlatest")<Enter>
    vmap <F6> <Esc>:call MyEcmsGetCmd("vdlatest")<Enter>gv

    nmap <F9> :call MyEcmsGetCmd("mdesc", "-e")<Enter>
    imap <F9> <C-o>:call MyEcmsGetCmd("mdesc", "-e")<Enter>
    vmap <F9> <Esc>:call MyEcmsGetCmd("mdesc", "-e")<Enter>gv

    nmap <S-F9> :call MyEcmsGetCmd("mdesc", "-v")<Enter>
    imap <S-F9> <C-o>:call MyEcmsGetCmd("mdesc", "-v")<Enter>
    vmap <S-F9> <Esc>:call MyEcmsGetCmd("mdesc", "-v")<Enter>gv

else "no versioning system
    nmap <F5> :call DiffOrig()<Enter>
    imap <F5> <C-o>:call DiffOrig()<Enter>
    vmap <F5> <Esc>:call DiffOrig()<Enter>gv
endif

let s:localrc=expand("$HOME" . g:OS_dir_separator . ".vimrc_local")
if filereadable(s:localrc)
    execute "source " . s:localrc
endif

