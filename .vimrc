set nocompatible

if has("win64") || has("win32") || has("win16")
	let osys="windows"

	let g:OS_dir_separator = '\'
	let g:OS_cat_command = 'type'
	let g:OS_mkdir_command = 'mkdir'
	" change to cygwin later (TODO)
	let g:OS_ctags_command = 'c:\Apps\ctags57\ctags.exe'
	let g:OS_system_includes_dir = 'c:\Apps\Dev-Cpp\include'

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

	let osys=system('uname -s')
	
	let g:OS_dir_separator = '/'
	let g:OS_cat_command = 'cat'
	let g:OS_mkdir_command = 'mkdir -p'
	"let g:OS_ctags_command = '/opt/exp/bin/ctags'
	"if filereadable(g:OS_ctags_command) == 0
		let g:OS_ctags_command = 'ctags'
	"endif

	let g:OS_system_includes_dir = '/usr/include'

	let my_uid=substitute(system('id'), '^uid=\([0-9]*\)(.*', '\1', "")
	let my_login=substitute(system('id'), '^uid=\([0-9]*\)(\([^)]*\)).*', '\2', "")

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

let g:tagbar_ctags_bin = g:OS_ctags_command

if osys == "windows"
	let s:tags_home_base_path=$HOME
else
	let s:tags_home_base_path=$HOME
endif

" ============================
" =           Paths          =
" ============================
" replace all directory separators in runtimepath to OS specific
let &runtimepath=substitute(&runtimepath, '[\/]', g:OS_dir_separator, 'g')

let g:default_search_path = substitute('.,**,../include/**,../src/**,' . expand("$ROOT") . '/panos,' . g:OS_system_includes_dir, '[\/]', g:OS_dir_separator, 'g')
let g:header_source_flip_search_path = substitute('.,**,../include/**,../src/**,' . expand("$ROOT") . '/panos,', '[\/]', g:OS_dir_separator, 'g')

" remove possible trailing slash before creating directory $HOME/.vim/tags
let g:user_tags_home = substitute(s:tags_home_base_path, '[\/]$', '', '') . g:OS_dir_separator . '.vim' . g:OS_dir_separator . 'tags'
silent! execute '!' . g:OS_mkdir_command . ' ' . g:user_tags_home

" set default path
let &path=g:default_search_path

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

" when .vimrc is edited, reload it (doesn't work)
"autocmd! bufwritepost $VIMRUNTIME/../../../Data/settings/vimrc source

" open files with the cursor at the last remembered position
autocmd! BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

set helplang=en
set langmenu=en

filetype plugin on

"set ttybuiltin "this is default
"  set notbi
"set ttymouse xterm2 "VIM autodetect from TERM env variable name (=~xterm => xterm2)


" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set nobackup		" DON'T keep a backup file

set history=400		" keep 400 lines of command line history
set ruler			" show the cursor position all the time
set showcmd			" display incomplete commands
set incsearch		" do incremental searching
set tabstop=4

set number				" line numbers
set cindent
set autoindent
if has("mouse")
	set mouse=a				" use mouse in xterm to scroll
endif
set scrolloff=5 		" 5 lines bevore and after the current line when scrolling
set ignorecase			" ignore case
set smartcase			" but don't ignore it, when search string contains uppercase letters
set hid 				" allow switching buffers, which have unsaved changes
set shiftwidth=4		" 4 characters for indenting
set showmatch			" showmatch: Show the matching bracket for the last ')'?

set nowrap				" don't wrap by default
syn on
set confirm

set hlsearch

" tabs are forbidden in SR projects
if expand("$PANOS") != "$PANOS"
	set expandtab
endif

set cscopequickfix=s-,c-,d-,i-,t-,e-,f0,g0		" cscope will fill results into quickfix window (possible to open via :copen command, move with <F11><F12>)

imap jj	<Esc> 

" follow visual lines (instead of lines - comes into play when line wrapping is on
map <A-Down> gj
map <A-Up> gk
imap <A-Up> <C-o>gk
imap <A-Down> <C-o>gj

set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\[HEX=\%02.2B]\ [POS=%04l,%04v][%p%%]\ [LEN=%L]
set laststatus=2

if v:version >= 700
	" set completion options
	set completeopt=menu,longest ",longest,preview

	" spell checking (switchable by <Leader>s)
	"set dictionary=/usr/share/dict/words
	"set thesaurus=/usr/share/????
	set nospell
	set spelllang=en
	set spellsuggest=5
endif

" ============================
" =       Window title       =
" ============================
"TODO setting of windows title based on environment / file edited / edit status ?
set t_ts=]0;
set t_fs=
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
"Here the window title is reset when the user enters a new buffer. It contains the hostname, a forward slash, then the full path of the current fileFor an explanation of the %:p syntax see the Filename Modifiers section of the Executing External Commands recipe..
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

	" this works also in console
	nmap <C-S-Right> :tabnext<Enter>
	nmap <C-S-Left> :tabprev<Enter>
	imap <C-S-Right> <C-o>:tabnext<Enter>
	imap <C-S-Left> <C-o>:tabprev<Enter>
	vmap <C-S-Right> <Esc>:tabnext<Enter>gv
	vmap <C-S-Left> <Esc>:tabprev<Enter>gv
	
	" (CTRL+SHIFT+UP/DOWN works only in gVim)
	nmap <C-S-Up> <C-w>W
	nmap <C-S-Down> <C-w>w
	imap <C-S-Up> <C-o><C-w>W
	imap <C-S-Down> <C-o><C-w>w
	vmap <C-S-Up> <C-w>Wgv
	vmap <C-S-Down> <C-w>wgv

	" simplified movement through windows
	nmap <C-Up> <C-S-Up>
	nmap <C-Down> <C-S-Down>
	imap <C-Up> <C-S-Up>
	imap <C-Down> <C-S-Down>
	vmap <C-Up> <C-S-Up>
	vmap <C-Down> <C-S-Down>
	
	" nmap <C-t> :tabnew 
	" imap <C-t> <C-o>:tabnew 
	" vmap <C-t> <Esc>:tabnew 
endif

" ============================
" =Windows editors short-cuts=
" ============================
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

" half page down/up selection (gVim)
nmap <S-PageDown> v<End><C-d><End>
nmap <S-PageUp> v<Home><C-u>
imap <S-PageDown> _<Esc>mz"_xv`zo<End><C-d><End>
imap <S-PageUp> _<Esc>mz"_xv`z<BS>o<Home><C-u>
vmap <S-PageDown> <End><C-d><End>
vmap <S-PageUp> <Home><C-u>

" word deletion (gVim)
imap <C-BS> <C-w>
imap <C-Del> _<Esc>mzew<BS>i<Del><Esc>v`z"_c

" faster cursor movement with CTRL pressed (vim default, not necessary to define)
"nmap <C-Left> B
"nmap <C-Right> W
"imap <C-Left> <C-o>B
"imap <C-Right> <C-o>W
"vmap <C-Left> B
"vmap <C-Right> W

" tab, shift+tab
"inoremap <S-Tab> <C-O><LT><LT>

"nnoremap <Tab> >>
"nnoremap <S-Tab> <LT><LT>

vnoremap <Tab> >gv
vnoremap <S-Tab> <LT>gv

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
            endtry
        endtry
    endif
endfunction

" resolves even with :: in the cWORD, but without following (), ->, ., , e.g. DbgwController::getPort vs. DbgwController::getPort()
function! SophTag(str)
		"SophTag(...)
		"let args=a:000
		"for a in args
		"	echo a
		"endfor
		if a:str != ""
			try
				exec "cstag ".a:str
				return 0  " search no more, result found
			catch /:E562:\|:E257:/
				" we will continue with cWORD and cword searches
			endtry
		endif
		try
			let l:cww=substitute(expand("<cWORD>"), '[^A-Za-z_:]', '', 'ga')
			"echo l:cww
			exec "cstag ".l:cww
		catch /:E562:\|:E257:/
			" E562 bad usage for cstag - obviously cWORD contains special characters
			" E257 cstag tag not found
			try
				exec "cstag ".expand("<cword>")
			catch /:E562:\|:E257:/
				echohl WarningMsg
				if a:str != ""
					echo "Sorry, no tag generated for ".a:str." or ".expand("<cWORD>")." or ".expand("<cword>")
				else
					echo "Sorry, no tag generated for ".expand("<cWORD>")." or ".expand("<cword>")
				endif
			endtry
		endtry
endfunction

nmap <C-]> :call SophTag("")<Enter>
imap <C-]> <C-o>:call SophTag("")<Enter>
vmap <C-]> y<Esc>:call SophTag("<C-r>0")<Enter>gv

" F1 to display help
if expand("$PANOS") != "$PANOS"
	nmap <F1> :execute "!sr_cscope.sh update"<CR> :cs reset<CR>
	imap <F1> <C-o>:execute "!sr_cscope.sh update"<CR> <C-o>:cs reset<CR>
	vmap <F1> <Esc>:execute "!sr_cscope.sh update"<CR> :cs reset<CR>gv
else
	"nmap <F1> :exec "help ".expand("<cword>")<CR>
	"imap <F1> <C-o>:exec "help ".expand("<cword>")<CR>
	"vmap <F1> <Esc>:exec "help ".expand("<cword>")<CR>
	nmap <F1> :call SophHelp()<Enter>
	imap <F1> <C-o>:call SophHelp()<Enter>
	vmap <F1> <Esc>:call SophHelp()<Enter>gv
endif

nmap <S-F7> :call SophHelp()<Enter>
imap <S-F7> <C-o>:call SophHelp()<Enter>
vmap <S-F7> <Esc>:call SophHelp()<Enter>gv

" F2 to save
nmap <F2> :w<Enter>
imap <F2> <C-o>:w<Enter>
vmap <F2> <Esc>:w<Enter>gv

" F3 to toggle source/header
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

map <F3> :call Mosh_Flip_Ext()<CR>
imap <F3> <C-o>:call Mosh_Flip_Ext()<CR>
vmap <F3> <Esc>:call Mosh_Flip_Ext()<CR>gv

" F4 to switch between hex and ASCII editing
function! Fxxd()
	let c=getline(".")
	if c =~ '^[0-9a-f]\{7}:'
		:%!xxd -r
	else
		:%!xxd -g4
	endif
endfunction

nmap <F4> :call Fxxd()<Enter>
imap <F4> <C-o>:call Fxxd()<Enter>
vmap <F4> <Esc>:call Fxxd()<Enter>gv

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

function! DiffCCPred()
	if &diff
		diffoff!
		wincmd o
	else
		let ftype = &filetype
		let predfile=tempname().".vimtmp"
		silent! exe "!echo " . expand('%:p') . "> " . predfile		
		silent! exe "!cleartool desc -short -predecessor " . expand('%:p') . ">> " . predfile
  		silent! exec 'split '.predfile
		let predfilename=getline(1)."@@".getline(2)
		bwipeout
		let actualfilename=expand('%:p')
		vert new
		setlocal bt=nofile
		exe "r !cleartool shell " . g:OS_cat_command. " " . predfilename
		let &titlestring = predfilename . " <-> " . actualfilename
		0d_
		exe "setlocal filetype=" . ftype		
		diffthis | wincmd p | diffthis
	endif
endfunction

"ignore whitespace when diff-ing
set diffopt=filler,context:6,iwhite
"almost the same as without setting diffexpr (but can be easily changed in the future)
set diffexpr=MyDiff()  "produces some artifacts on command line after execution
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
	redraw!
endfunction

try
	"defines sign type information
	sign define information text=!> texthl=Error linehl=Warning 
	"places sign type information with ID 123 on current line
	"exe ":sign place 123 line=" . line(".") . " name=information file=" . expand("%:p")
	"remove sign with ID 123 from current file
	"exe ":sign unplace 123 file=" . expand("%:p")

	"nmap <F7> :exe ":sign place 123 line=" . line(".") . " name=information file=" . expand("%:p")<CR>
	"nmap <S-F7> :exe ":sign unplace 123 file=" . expand("%:p")<CR>
catch
	"just ignore, signs probably not compiled in this version of VIM
endtry

set pastetoggle=<F7>

nmap <F8> :TagbarToggle<Enter>
imap <F8> <C-o>:TagbarToggle<Enter>
vmap <F8> <Esc>:TagbarToggle<Enter>gv

nmap <S-F8> :TlistToggle<Enter>
imap <S-F8> <C-o>:TlistToggle<Enter>
vmap <S-F8> <Esc>:TlistToggle<Enter>gv

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

function! MyCTags(fdir)
	" let l:path = "."
	if a:fdir == ""
		let l:path = resolve (expand("%:p:h"))
	else
		let l:path = a:fdir
	endif
	
	silent! execute "!" . g:OS_ctags_command . " --languages=C,C++ -R --c-kinds=+p --c++-kinds=+p --fields=+iaS --extra=+fq --tag-relative=yes " . l:path
	redraw!
endfunction

function! MyEcmsGetCmd(mgcmd, ...)
	if ((a:mgcmd == "vdload") || (a:mgcmd == "vdlatest"))
		if &diff
			diffoff!
			wincmd o
			return
		endif
	elseif ((a:mgcmd == "mdesc") && ((a:0 > 0) && ((a:1 == "-v") || (a:1 == "-e"))))
		if exists("t:mtree")
			if t:mtree == 1
				let l:tpn = tabpagenr()
				if l:tpn > 0
					let l:tpn = l:tpn - 2
				endif
				exe "tabmove " . l:tpn
				tabclose
				"t:mtree = 0
				return
			endif
		else
			let t:mtree = 0
		endif
	endif

	if (expand("$REL") == "")
		echohl WarningMsg
		echo l:path . "please use se first"
		echohl Normal
		return
	elseif (expand("$ROOT") == "")
		echohl WarningMsg
		echo l:path . "ROOT env variable is not set"
		echohl Normal
		return
	endif

	let l:saved_cursor = getpos(".")
	let l:linenumber = line(".")
"let l:path = substitute(expand('%p'),'^\([A-z]\+:\\[^\\]\+\).*','\1','')
	echo expand("$ROOT")

"let l:path = expand("%:p")

	let l:mr = ""
	let l:input_file = ""

	echo "ARGS = " . a:0

	if a:0 > 0
		let l:mr = a:1
	end
	if a:0 > 1
		let l:input_file = a:2
	end

	echo "CMD: " . a:mgcmd
	echo "MR: " . l:mr
	echo "PATH: " . l:input_file

	if l:input_file == ""
	  let l:path = resolve(expand("%:p"))
	else
	  let l:path = resolve(l:input_file)
	endif
	
	"let l:path = "/fs/mmebld/LM50022.00/glob/sgsn/lib/util/qdb.c"
	"let l:path = "glob/sgsn/lib/util/qdb.c"
	"let l:path = "qdb.c"
	"echo l:path

	let l:path_tail = system("basename " . l:path)
	let l:path_tail = substitute(l:path_tail,'\n','','')

	echo l:path_tail

	let l:path_dir = system("dirname " . l:path)
	let l:path_dir = substitute(l:path_dir,'\n','','')

	echo l:path_dir

	if l:path_dir == "."
		let l:path_pwd = system("pwd")
		let l:path_pwd = substitute(l:path_pwd,'\n','','')
		let l:path = l:path_pwd . "/" . l:path_tail
		let l:path_dir = l:path_pwd
	elseif matchstr(l:path_dir,"^/") == ""
		let l:path = expand("$ROOT") . "/" . l:path
		let l:path_dir = system("dirname " . l:path)
		let l:path_dir = substitute(l:path_dir,'\n','','')
	endif

	echo "FINAL: " . l:path
	"return

	"check for $ROOT prefix or /fs/*/*/ prefix
	if (matchstr(l:path,expand("$ROOT")) != "")
		"no action necessary - l:path is the final node path
	else
		if (matchstr(l:path,"/fs/") != "")
			if ((a:mgcmd == "vdload") || (a:mgcmd == "vdlatest"))
				echohl WarningMsg
				echo l:path . " starts with /fs/*/*/ - cannot compare with " . a:mgcmd . " (switch to your root node directory and compare from there)"
				echohl Normal
				return
			else
				"transform /fs/ into $ROOT path
				let l:tpath = substitute(l:path,'\(/fs/[0-9A-Za-z_\-\.]\+/[0-9A-Za-z_\-\.]\+\)\(.*\)','\2','')
				echo l:tpath
				let l:path = expand("$ROOT") . l:tpath
			endif
		else
			echohl WarningMsg
			echo l:path . " does not start with $ROOT/ or /fs/*/*/ - unable to proceed"
			echohl Normal
			return
		endif
	endif

	"future node path set
	echo l:path

	let l:choice = 1

	"confirm file replacement, if applicable
	if filereadable(l:path)
		if (a:mgcmd == "mgload") || (a:mgcmd == "mglatest")
			let l:choice = confirm(l:path . " overwrite ?", "&yes\n&no\n&cancel", 3)
		endif
	endif

	if a:mgcmd == "switch"
		if filereadable(l:path)
			exe "e " . l:path
			call setpos('.', saved_cursor)
			redraw!
			return
		else
			echohl WarningMsg
			echo l:path . " does not exist in your root node (get/checkout it first from ECMS)"
			echohl Normal
			return	
		endif
	endif

	if l:choice == 0
		"escaped
	elseif l:choice == 1
		if l:mr == "" || matchstr(l:mr,"^-") != ""
			if ((a:mgcmd == "vdload") || (a:mgcmd == "vdlatest"))
				let l:rnd = localtime() % 0x10000
				let l:file_name = "/tmp/" . l:rnd . "." . expand("$USER") . "." . expand("$GENERIC") . "." . expand("$SS") . "." . a:mgcmd . "." . l:path_tail
				"echo "!" . a:mgcmd . " -n " . " -o " . l:file_name  . " " . l:path . ""
				silent! execute "!" . a:mgcmd . " -n " . " -o " . l:file_name  . " " . l:path . ""
				let l:res = v:shell_error
				if filereadable(l:file_name)
					if l:res == 0
						redraw!
						echo a:mgcmd . " claims that both files are identical"
					elseif l:res == 1
						"exe "set nofoldenable"
						exe "vert diffsplit " . l:file_name
						exe "wincmd l"
						call setpos('.', saved_cursor)
						redraw!
						"exe "wincmd h"
						"exe "wincmd l"
						"exe "0"
						"call setpos('.', saved_cursor)
						"exe "wincmd l"
						"call setpos('.', saved_cursor)
						"exe "set foldlevel=99"
						"exe "set foldenable"
					else
						echohl WarningMsg
						echo l:file_name . " does exist, but unknown result ". l:res . " returned from " . a:mgcmd
						echohl Normal
					endif
				else
					echohl WarningMsg
					echo l:file_name . " does not exist - problem with getting original file from ECMS"
					echohl Normal
				endif
			elseif a:mgcmd != "mdesc"
				silent! execute "!" . a:mgcmd . " " . l:path . ""
				redraw!
			else
				"mdesc script call
				if ((l:mr == "-v") || (l:mr == "-e"))
					let l:rnd = localtime() % 0x10000
					let l:file_name = "/tmp/" . l:rnd . "." . expand("$USER") . "." . expand("$GENERIC") . "." . expand("$SS") . "." . a:mgcmd . "." . l:path_tail
					if l:mr == "-v"
						silent! execute "!" . a:mgcmd . " -v " . " -o " . l:file_name  . " " . l:path . ""
					else
						silent! execute "!" . a:mgcmd . " -v -e " . " -o " . l:file_name  . " " . l:path . ""	
					endif
					let l:path_basename = system("basename " . l:file_name)
					let l:file_body = l:file_name . ".body"
					let l:sysout = system("cp " . l:file_body . " " . l:file_body . "." . l:path_basename)
					let l:file_body = l:file_body . "." . l:path_basename
					let l:file_header = l:file_name . ".header"
					let l:file_mrdetail = l:file_name . ".mrdetail"
					"let l:ft = &filetype
					exe "tabe " . l:file_body
					exe "8split " . l:file_header
					exe "1000000"
					exe "set nonu"
					exe "set ro"
					redraw
					exe "wincmd j"
					exe "vert 40split " . l:file_mrdetail
					exe "" . l:linenumber
					exe "set nonu"
					exe "set scrollbind"
					exe "set ro"
					redraw
					exe "wincmd l"
					"exe "set filetype=" . l:ft
					call setpos('.', saved_cursor)
					exe "set scrollbind"
					exe "set ro"
					redraw!
					let t:mtree = 1
				else
					execute "!" . a:mgcmd .  " " . l:path . ""
				endif
			endif
		else
			if ((a:mgcmd == "mput") || (a:mgcmd == "mlock"))
				silent! execute "!" . a:mgcmd . " " . l:mr . " " . l:path . ""
				redraw!
			else
				silent! execute "!" . a:mgcmd . " -l " . l:mr . " " . l:path . ""
			end
		end
		if (a:mgcmd == "mgload") || (a:mgcmd == "mglatest")
			exe "e " . l:path
			call setpos('.', saved_cursor)
			redraw!
		endif
	elseif l:choice == 2
		exe "e " . l:path
		call setpos('.', saved_cursor)
		redraw!
	else
		"aborted
	endif

""" 	e /home/akocis/lm500/glob/sgsn/lib/util/qdb.c
""" "br /home/akocis/lm500/glob/sgsn/lib/util/qdb.c
""" 	e!
""" 	call setpos('.', saved_cursor)
""" "silent! execute l:linenumber
""" 	redraw!
endfunction

function! MyGenTagsCmd(gtcmd, ...)
"let l:path_pwd = system("pwd")
	if (a:gtcmd == "gt")
"		silent! execute "!" . "ctags --languages=C,C++ --fields=+ia --extra=+fq --tag-relative=yes -R -f tags --totals=yes ; cscope -b -q -u -R -f cscope.out"
"		cs add cscope.out
"		if &tags != ""
"			let &tags="tags" . "," . &tags
"		else
"			let &tags.="tags"
"		endif
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
	redraw!
endfunction

"comm! EcmsGetLatest call MyEcmsGetCmd("mglatest")
"comm! EcmsGetLoad call MyEcmsGetCmd("mgload")

cabbrev ecl Ecl
cabbrev ecb Ecb
cabbrev egl Egl
cabbrev egb Egb

cabbrev ep Ep
cabbrev el El
cabbrev eu Eu

cabbrev ede Ede
cabbrev et Et
cabbrev etf Etf

cabbrev es Es

cabbrev edl Edl
cabbrev edb Edb

cabbrev egt Egt
cabbrev ert Ert

com! -nargs=* Ecl call MyEcmsGetCmd("mglatest", <f-args>)
com! -nargs=* Ecb call MyEcmsGetCmd("mgload", <f-args>)
com! -nargs=* Egl call MyEcmsGetCmd("mglatest", "", <f-args>)
com! -nargs=* Egb call MyEcmsGetCmd("mgload", "", <f-args>)

com! -nargs=* Ep call MyEcmsGetCmd("mput", <f-args>)
com! -nargs=* El call MyEcmsGetCmd("mlock", <f-args>)
com! -nargs=* Eu call MyEcmsGetCmd("munlock", "", <f-args>)

com! -nargs=* Ede call MyEcmsGetCmd("mdesc", "", <f-args>)
com! -nargs=* Et call MyEcmsGetCmd("mdesc", "-e", <f-args>)
com! -nargs=* Etf call MyEcmsGetCmd("mdesc", "-v", <f-args>)

com! -nargs=* Es call MyEcmsGetCmd("switch", "", <f-args>)

com! -nargs=* Edl call MyEcmsGetCmd("vdlatest", "", <f-args>)
com! -nargs=* Edb call MyEcmsGetCmd("vdload", "", <f-args>)

com! -nargs=* Egt call MyGenTagsCmd("gt", <f-args>)
com! -nargs=* Ert call MyGenTagsCmd("rt", <f-args>)

"TODO show SCCS + show featured

if expand("$CLEARCASE_ROOT") != "$CLEARCASE_ROOT"
	nmap <F5> :call DiffOrig()<Enter>
	imap <F5> <C-o>:call DiffOrig()<Enter>
	vmap <F5> <Esc>:call DiffOrig()<Enter>gv

	nmap <F6> :call DiffCCPred()<Enter>
	imap <F6> <C-o>:call DiffCCPred()<Enter>
	vmap <F6> <Esc>:call DiffCCPred()<Enter>gv

	nmap <F9> :Ctxlsv<Enter>
	imap <F9> <C-o>:Ctxlsv<Enter>
	vmap <F9> <Esc>:Ctxlsv<Enter>gv

elseif expand("$PANOS") != "$PANOS"
    nmap <F5> :VCSVimDiff<Enter>
    imap <F5> <C-o>:VCSVimDiff<Enter>
    vmap <F5> <Esc>:VCSVimDiff<Enter>gv

    nmap <F6> :VCSVimDiff BRANCH<Enter>
    imap <F6> <C-o>:VCSVimDiff BRANCH<Enter>
    vmap <F6> <Esc>:VCSVimDiff BRANCH<Enter>gv

    nmap <F9> :VCSBlame!<Enter>
    imap <F9> <C-o>:VCSBlame!<Enter>
    vmap <F9> <Esc>:VCSBlame!<Enter>gv
    
    nmap <S-F9> :VCSLog<Enter>
    imap <S-F9> <C-o>:VCSLog<Enter>
    vmap <S-F9> <Esc>:VCSLog<Enter>gv

elseif expand("$LSF_BINDIR") != "$LSF_BINDIR"
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

else
	nmap <F5> :call DiffOrig()<Enter>
	imap <F5> <C-o>:call DiffOrig()<Enter>
	vmap <F5> <Esc>:call DiffOrig()<Enter>gv

	"nmap <F6> :call DiffOrig()<Enter>
	"imap <F6> <C-o>:call DiffOrig()<Enter>
	"vmap <F6> <Esc>:call DiffOrig()<Enter>gv

	"nmap <F9> :Ctxlsv<Enter>
	"imap <F9> <C-o>:Ctxlsv<Enter>
	"vmap <F9> <Esc>:Ctxlsv<Enter>gv
endif

"comm! -nargs=? -bang A call AlternateFile("n<bang>", <f-args>)
"abbreviate/iabbrev/cabbrev

" command mode abbreviation of tt as tabnew | tag <args>
cabbrev tt TT
comm! -nargs=1 -complete=tag TT tabnew | tag <args> 

" common ctags commands
comm! CtagsP call MyCTags('.. ' . g:OS_system_includes_dir)
comm! CtagsC call MyCTags('. ' . g:OS_system_includes_dir)
comm! CtagsQ call MyCTags('.')

" Quickfix window - prev/next line jumps
nmap <F11> :cprev<Enter>
imap <F11> <C-o>:cprev<Enter>
vmap <F11> <Esc>:cprev<Enter>v

nmap <F12> :cnext<Enter>
imap <F12> <C-o>:cnext<Enter>
vmap <F12> <Esc>:cnext<Enter>v

" LQuickfix window - prev/next line jumps
nmap <S-F11> :lprev<Enter>
imap <S-F11> <C-o>:lprev<Enter>
vmap <S-F11> <Esc>:lprev<Enter>v

nmap <S-F12> :lnext<Enter>
imap <S-F12> <C-o>:lnext<Enter>
vmap <S-F12> <Esc>:lnext<Enter>v

" common leader mappings
let mapleader = ','
map <Leader>l :set invlist!<CR>
map <Leader>n :set nu!<CR>
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
map <Leader>f :set foldenable!<CR>
map <Leader>w :set wrap!<CR>

"map <Leader>t :set tags=tags<CR>
"map <Leader>f :echo line(".")<CR>
function! ShowFeatureInfo(line_number)
    "buffer featureinfo 
    wincmd w
    "echo system("/usr/local/timostools/setup_cli_find.pl -line " . a:line_number)
    "read "!". "/usr/local/timostools/setup_cli_find.pl -line " . a:line_number
    "exe "normal! i hello"
    "execute "read !ls"
    silent! normal gg
    silent! normal dG
    silent! execute "read !/usr/local/timostools/setup_cli_find.pl -line " . a:line_number . " " . t:featureinfo_opts
    wincmd w
endfunction

function! ToggleFeatureInfoWindow(options)
    if !exists("t:featureinfowindow")
        let t:featureinfowindow = 0 
        let t:featureinfowindow_teardown = 0 
    endif
    if t:featureinfowindow == 1
        "remove window
        "let l:tpn = tabpagenr()
        "if l:tpn > 0
        "    let l:tpn = l:tpn - 2
        "endif
        "exe "tabmove " . l:tpn
        "tabclose
        autocmd! FeatureInfo
        bwipeout featureinfo
        "autocmd! FocusGained * :echo system("/usr/local/timostools/setup_cli_find.pl -line " . line("."))
        let t:featureinfowindow = 0
    else
        let t:featureinfo_opts = ""
        let l:path = resolve(expand("%:t"))
        if ((l:path == "setup_cli.cfg") || (l:path == "teardown_cli.cfg"))
            if (l:path == "teardown_cli.cfg")
                let t:featureinfo_opts = "-teardown"
            endif
        else
            return
        endif

        "create window
        "autocmd FocusGained * :call Highlight_cursor()
        augroup FeatureInfo
            autocmd!
            autocmd CursorMoved <buffer> :call ShowFeatureInfo(line("."))
        augroup END
        "autocmd FocusGained * :echo system("/usr/local/timostools/setup_cli_find.pl -line " . line("."))
        
        exe "8new"
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        file featureinfo 
        exe "1000000"
        exe "set nonu"
        exe "set ro"
        wincmd w
        doautocmd FeatureInfo CursorMoved <buffer>
        let t:featureinfowindow = 1
    endif
endfunction

map <Leader>f :call ToggleFeatureInfoWindow("")<CR>

map <Leader>p :set paste!<CR>
" mouse intergration switching
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
map <Leader>0 :let &path=g:default_search_path<CR>

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
			return bufname($).' windows: '.wincount.' '.bufferlist ' '
		endfunction
		set guitabtooltip=%!InfoGuiTooltip()
	endif

	if osys == "windows"
		"colorscheme zenburn
		let g:molokai_original = 1
		colorscheme molokai

		"set guifont=Lucida_Console:h8:cEASTEUROPE
		"set guifont=Dina:h8:cANSI
		set guifont=Envy\ Code\ R:h11:cEASTEUROPE
		set guioptions="aegmrLtT
		
		" maximize window on start
		autocmd GUIEnter * simalt ~X
	else
		"colorscheme desert
		colorscheme wombat256mod
	
		set guifont=Envy\ Code\ R\ 11
		set guioptions="aegimrLtT
	
		" maximize window on start (still not good enough - it's not truly
		" maxed)
		set guiheadroom=0
		"set lines=999 columns=999
	
		set lines=50 columns=210
	endif
else
	"no GUI - console mode
	if osys == "windows"
		"8-color terminal in windows only, zellner looks OK
		colorscheme zellner
	else
		set t_Co=256 "override terminfo setting to enable 256 colors
		colorscheme wombat256mod

		if &term =~ "sco"
			map <Esc>[M <F1>
			map <Esc>[N <F2>
			map <Esc>[O <F3>
			map <Esc>[P <F4>
			map <Esc>[Q <F5>
			map <Esc>[R <F6>
			map <Esc>[S <F7>
			map <Esc>[T <F8>
			map <Esc>[U <F9>
			map <Esc>[V <F10>
			map <Esc>[W <F11>
			map <Esc>[X <F12>
			map <Esc>[A <Up>
			map <Esc>[B <Down>
			map <Esc>[C <Right>
			map <Esc>[D <Left>
			map <Esc>[L <Insert>
			map ^? <Del>
			map <Esc>[H <Home>
			map <Esc>[F <End>
			map <Esc>[I <PageUp>
			map <Esc>[G <PageDown>
			map ^H <BS>
			map <Esc>[Z <S-Tab>
			map <Esc>[Y <S-F1>
			map <Esc>[a <S-F3>
			map <Esc>[b <S-F4>
			map <Esc>[c <S-F5>
			map <Esc>[d <S-F6>
			map <Esc>[e <S-F7>
			map <Esc>[f <S-F8>
			map <Esc>[g <S-F9>
			map <Esc>[h <S-F10>
			map <Esc>[i <S-F11>
			map <Esc>[j <S-F12>
			map <Esc>[k <C-F1>
			map <Esc>[l <C-F2>
			map <Esc>[m <C-F3>
			map <Esc>[n <C-F4>
			map <Esc>[o <C-F5>
			map <Esc>[p <C-F6>
			map <Esc>[q <C-F7>
			map <Esc>[r <C-F8>
			map <Esc>[s <C-F9>
			map <Esc>[t <C-F10>
			map <Esc>[u <C-F11>
			map <Esc>[v <C-F12>
			map <Esc>[w <C-S-F1>
			map <Esc>[x <C-S-F2>
			map <Esc>[y <C-S-F3>
			map <Esc>[z <C-S-F4>
			map <Esc>[@ <C-S-F5>
			map <Esc>[[ <C-S-F6>
			map <Esc>[\ <C-S-F7>
			map <Esc>[] <C-S-F8>
			map <Esc>[^ <C-S-F9>
			map <Esc>[_ <C-S-F10>
			map <Esc>[` <C-S-F11>
			map <Esc>[{ <C-S-F12>
			map <Esc>[OA <C-Up>
			map <Esc>[OB <C-Down>
			map <Esc>[OC <C-Right>
			map <Esc>[OD <C-Left>
			map <Esc><Esc>[A <A-Up>
			map <Esc><Esc>[B <A-Down>
			map <Esc><Esc>[C <A-Right>
			map <Esc><Esc>[D <A-Left>
			map <Esc><Esc>[OA <A-C-Up>
			map <Esc><Esc>[OB <A-C-Down>
			map <Esc><Esc>[OC <A-C-Right>
			map <Esc><Esc>[OD <A-C-Left>
			"TODO add other ALT key combinations 
			"also all these bindings need map! variants

			"identical to S-Tab (Shift+F2 = Shift+TAB)
			"map <Esc>[Z <S-F2>

			"TODO mouse support (change of VIM sources is necessary)
			"set ttym=sco ??? ^[M [ "`..] XYZ ???
			if has("mouse")
				set mouse=
			endif
			"not functional in PuTTY SCO emulation
			"map <Esc>[7$ <S-Home>
			"map <Esc>[8$ <S-End>
			"map <Esc>[c <S-Right>
			"map <Esc>[d <S-Left>
			"map <Esc>[Ow <kHome>
			"map <Esc>[Oq <kEnd>
			"map <Esc>[Oy <kPageUp>
			"map <Esc>[Os <kPageDown>
		elseif &term =~ "xterm"
			"map Shift+F3..F10 keys (additional 8 combinations)
			map <Esc>[25~ <S-F3>
			"map! <Esc>[25~ <S-F3>
			map <Esc>[26~ <S-F4>
			"map! <Esc>[26~ <S-F4>
			map <Esc>[28~ <S-F5>
			"map! <Esc>[28~ <S-F5>
			map <Esc>[29~ <S-F6>
			"map! <Esc>[29~ <S-F6>
			map <Esc>[31~ <S-F7>
			"map! <Esc>[31~ <S-F7>
			map <Esc>[32~ <S-F8>
			"map! <Esc>[32~ <S-F8>
			map <Esc>[33~ <S-F9>
			"map! <Esc>[33~ <S-F9>
			map <Esc>[34~ <S-F10>
			"map! <Esc>[34~ <S-F10>
		
			map [A <C-Up>
			"map! [A <C-Up>
			map [B <C-Down>
			"map! [B <C-Down>
			map [C <C-Right>
			"map! [C <C-Right>
			map [D <C-Left>
			"map! [D <C-Left>
			map <Up> <A-Up>
			"map! <Up> <A-Up>
			map <Down> <A-Down>
			"map! <Down> <A-Down>
			map <Right> <A-Right>
			"map! <Right> <A-Right>
			map <Left> <A-Left>
			"map! <Left> <A-Left>
			map <C-@> <C-Space>
			map! <C-@> <C-Space>

			"map <Esc><Esc>[OA <A-Up>
			"map! <Esc><Esc>[OA <A-Up>
			"map <Esc><Esc>[OB <A-Down>
			"map! <Esc><Esc>[OB <A-Down>
			"map <Esc><Esc>[OC <A-Right>
			"map! <Esc><Esc>[OC <A-Right>
			"map <Esc><Esc>[OD <A-Left>		
			"map! <Esc><Esc>[OD <A-Left>		
		endif

		"if &term =~ "xterm\\|rxvt"
		"  :silent !echo -ne "\033]12;red\007"
		"  let &t_SI = "\033]12;orange\007"
		"  let &t_EI = "\033]12;red\007"
		"  autocmd VimLeave * :!echo -ne "\033]12;red\007"
		"endif
	endif
endif

" simple code completion - works correctly only in graphical modes (gVim) - XXX colides with cscope special stuff - CTRL+SPACE
"imap <C-Space> <C-n><C-p><Down>
"imap <C-S-Space> <C-p><C-n><Up>
imap <C-Space> <C-r>=CleverTabCompletion()<CR>

" ============================
" =       Super S-TAB        =
" ============================
function! CleverTabCompletion()
   " do we have omni completion available
   if &omnifunc != ''
	  "use omni-completion 1. priority
	  return "\<C-X>\<C-O>"
   elseif &dictionary != ''
	  " no omni completion, try dictionary completio
	  return "\<C-K>"
   else
	  "use omni completion or dictionary completion
	  "use known-word completion
	  return "\<C-N>"
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
		return CleverTabCompletion()
	endif
endfunction
" bind function to the tab key
imap <S-Tab> <C-r>=ShiftTabCompletion()<CR>

" bind ,a to grep word under cursor
nmap <Leader>a :grep! "\b<C-R><C-W>\b"<CR>:cw<CR>

" bind \ to Ag - similar to /, just enter search string
nmap \ :grep!<SPACE>

" ============================
" =        OS specific       =
" ============================
if osys == "windows"
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

      " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
      let g:ctrlp_user_command = 'ag %s -l --nocolor -g "" -p ~/.agignore'
      "--ignore *gen/work/ --ignore *gen/agent/ti-mibs/'

      " ag is fast enough that CtrlP doesn't need to cache
      let g:ctrlp_use_caching = 1
    endif

	"set equalprg=indent\ -gnu
	"set equalprg=indent\ -nbad\ -bap\ -nbc\ -bbo\ -bl\ -bli0\ -bls\ -ncdb\ -nce\ -cp1\ -cs\ -di16\ -ndj\ -nfc1\ -nfca\ -hnl\ -i4\ -ip5\ -lp\ -pcs\ -nprs\ -psl\ -saf\ -sai\ -saw\ -nsc\ -nsob\ -nut
	"set formatprg=par\ -w78j
endif

set tags=
if filereadable("tags")
	set tags+=tags
endif
if $CTAGS_FILE != ""
	"if &tags != ""
	"	set tags+=,
	"endif
	set tags+=$CTAGS_FILE
endif
if $CTAGS_PREFIX != ""
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
	"	"comma separator is added automatically via += construct
	"	"if &tags != ""
	"	"	set tags+=,
	"	"endif
	"	set tags+=$CTAGS_PREFIX
	"endif
endif

" ============================
" =      TagList plug-in      =
" ============================
let Tlist_Ctags_Cmd = g:OS_ctags_command
let Tlist_Show_Menu = 1

" ============================
" =   CodeComplete plug-in    =
" ============================
let g:completekey ='<Tab>'

" ============================
" =    Clearcase plug-in     =
" ============================
"let g:loaded_ccase = 0  " set to 1 to abort loading ccase.vim plugin
let g:ccaseUseDialog = 0   " sets usage of windows input dialog

" ============================
" =     ALU work specific    =
" ============================
" work specific ctags commands
"" if osys == "windows"
"" 	" these Ctags commands depend on current file directory (must be run from ..view..drive..)
"" 	let s:view_path = substitute(expand('%p'),'^\([A-z]\+:\\[^\\]\+\).*','\1','')
"" 	" full OAM
"" 	comm! CtagsOam call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'oam' . ' ' . s:view_path . g:OS_dir_separator . 'U3_sgsn_src_oam' . ' ' . s:view_path . g:OS_dir_separator . 'U3_sgsn_common' . ' ' . g:OS_system_includes_dir)
"" 	" full CHA
"" 	comm! CtagsCha call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'cha' . ' ' . s:view_path . g:OS_dir_separator . 'U3_src_sgsn_serv' . ' ' . s:view_path . g:OS_dir_separator . 'U3_sgsn_common' . ' ' . g:OS_system_includes_dir)
"" else
"" 	" warning, relative paths do not work due in linux in ctags due to /u/btl/akocis vs. /phys/btl/home001/akocis
"" 	" full OAM
"" 	comm! CtagsOam call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'oam' . ' /sgsn/src/oam /sgsn/common ' . g:OS_system_includes_dir)
"" 	" full CHA
"" 	comm! CtagsCha call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'cha' . ' /sgsn/src/serv/cha /sgsn/common ' . g:OS_system_includes_dir)
"" 	
"" 	" full RelayC
"" 	comm! CtagsRelayC call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'relayc' . ' /sgsn/src/stack/NAS/relayc /sgsn/common ' . g:OS_system_includes_dir)
"" 
"" 	comm! CtagsSGSN call MyCTags('-f' . g:user_tags_home . g:OS_dir_separator . 'sgsn' . ' /sgsn/src/oam /sgsn/src/serv/cha /sgsn/cfg /sgsn/common /vob/3pp_tomas ' . g:OS_system_includes_dir)
"" endif
"" "   work related
"" map <Leader>o :let &tags=g:user_tags_home . g:OS_dir_separator . 'oam'<CR>
"" map <Leader>c :let &tags=g:user_tags_home . g:OS_dir_separator . 'cha'<CR>
"" map <Leader>r :let &tags=g:user_tags_home . g:OS_dir_separator . 'relayc'<CR>
"" 
"" map <Leader>a :let &tags=g:user_tags_home . g:OS_dir_separator . 'sgsn'<CR>
"" 
"" "   work related
"" map <Leader>1 :set path=.,/sgsn/src/oam/Gb-Mgt/**,/sgsn/src/oam/Trace-Mgt/**,/sgsn/src/oam/Common/**,/sgsn/common/**,/sgsn/cfg/**,/vob/3pp_tomas/usr/nectar/include/**,/vob/3pp_tomas/usr/nectar/nam/include/**,/vob/3pp_tomas/usr/nectar/oam/include/**,/vob/3pp_tomas/usr/tao/include/**,/vob/3pp_tomas/usr/include/**,/usr/include/**<CR>
"" map <Leader>2 :set path=.,/sgsn/src/serv/cha/**,/sgsn/src/oam/Common/**,/sgsn/common/**,/sgsn/cfg/**,/vob/3pp_tomas/usr/nectar/include/**,/vob/3pp_tomas/usr/nectar/nam/include/**,/vob/3pp_tomas/usr/nectar/oam/include/**,/vob/3pp_tomas/usr/include/**,/usr/include/**<CR>

function! DoPrettyXML()
  " save the filetype so we can restore it later
  let l:origft = &ft
  set ft=
  " delete the xml header if it exists. This will
  " permit us to surround the document with fake tags
  " without creating invalid xml.
  1s/<?xml .*?>//e
  " insert fake tags around the entire document.
  " This will permit us to pretty-format excerpts of
  " XML that may contain multiple top-level elements.
  0put ='<PrettyXML>'
  $put ='</PrettyXML>'
  silent %!xmllint --format -
  " xmllint will insert an <?xml?> header. it's easy enough to delete
  " if you don't want it.
  " delete the fake tags
  2d
  $d
  " restore the 'normal' indentation, which is one extra level
  " too deep due to the extra tags we wrapped around the document.
  silent %<
  " back to home
  1
  " restore the filetype
  exe "set ft=" . l:origft
endfunction
command! PrettyXML call DoPrettyXML()
