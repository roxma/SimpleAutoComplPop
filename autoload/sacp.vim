

"""
" neocomplete needs if_lua, currently not possible with nvim
" deoplete's php engine only work with the unmaintained phpcomplete_extended
" So I do it my self
"
" I hope this will be more extensible then the original AutoComplPop.
" Key mappings are enabled on per-buffer basis, which will make it more easily to be compatible with
" other auto complete plugins.


" call this funciton to enable auto complete pop
function! sacp#enableForThisBuffer(options)

	if !exists("b:sacpOptions")
		" config for this buffer for the first time
		autocmd InsertEnter,CompleteDone <buffer> let b:sacpCompleteDone=1 | let b:sacpCompleteDoneText = s:getCurrentText()
		autocmd InsertEnter              <buffer> let b:sacpSmartCompleteDone=1
		" vim's TextChangedI will be triggered even when <C-X><C-O> is pressed
		" use InsertCharPre to workaround this bug
		if has('nvim')
			autocmd TextChangedI             <buffer> call sacp#feedPopup('')
		else
			autocmd InsertCharPre             <buffer> call sacp#feedPopup(v:char)
		endif
	endif


	let b:sacpCompleteDone = 1
	let b:sacpLockCount    = 0
	" when complete-functions return refresh always, there's no way to stay in
	" completion mode properly (even when returns -2), vim will exit
	" completion mode directly when a key typed after the popup menu gets
	" empty. But the text pattern will still match the pattern to trigger a
	" new completion mode, vim will get really slow when this hapens. I
	" invented this variable to solve this issue.
	let b:sacpSmartCompleteDone = 1

	let b:sacpOptions          = copy(a:options)

	let &l:completeopt = get(a:options,'completeopt','menu,menuone,noinsert,noselect')

	" Supress the anoying messages like '-- Keyword completion (^N^P)' when
	" press '<C-n>' key. This option is only supported after vim 7.4.314 
	" https://groups.google.com/forum/#!topic/vim_dev/WeBBjkXE8H8
	silent! setlocal shortmess+=c

	if g:sacpDefaultKeyMapEnable==1
		inoremap <expr> <buffer> <silent> <TAB>  pumvisible()?"\<C-n>":"\<TAB>"
		inoremap <expr> <buffer> <silent> <S-TAB>  pumvisible()?"\<C-p>":"\<TAB>"
		inoremap <expr> <buffer> <silent> <CR>  pumvisible()?"\<C-y>":"\<CR>"
	endif

endfunction

function! sacp#lock()
	let b:sacpLockCount = get(b:,'sacpLockCount',0)
	let b:sacpLockCount += 1
endfunction

function! sacp#unlock()
	let b:sacpLockCount -= 1
	if b:sacpLockCount < 0
		let b:sacpLockCount = 0
		throw "AutoComplPop: not locked"
	endif
endfunction

function! sacp#writeLog(line)
	return writefile(["[" . localtime() . "] ".  a:line],"sacp.log","a")
endfunction 

""
" If this function is called when handling event InsertCharPre, 
" set the parameter to v:char, otherwise set it to empty stirng
function! sacp#feedPopup(char)

	" NOTICE:
	" workaround for vim's bug, <C-X><C-O> key will update vim's changed tick
	" if !has('nvim')
	" 	if get(b:,'sacpTempOmniAutoRefreshed',0) == 1
	" 		let b:sacpTempOmniAutoRefreshed=0
	" 		return
	" 	endif
	" endif
	
	if &paste
		return ''
	endif

	" NOTE: CursorMovedI is not triggered while the popup menu is visible. And
	"       it will be triggered when popup menu is disappeared.

	if b:sacpLockCount > 0
		return ''
	endif

	let l:text = s:getCurrentText().a:char
	if (b:sacpCompleteDone==1) && (b:sacpSmartCompleteDone==0)
		if empty(s:checkMatch(l:text,b:sacpLastCompleteMatch))
			let b:sacpSmartCompleteDone=1
		elseif len(b:sacpCompleteDoneText) > len(l:text)
			" set complete done when enough words are deleted
			let b:sacpSmartCompleteDone=1
		endif
	endif

	let l:needIgnoreCompletionMode = pumvisible() || (b:sacpCompleteDone==0) || (b:sacpSmartCompleteDone==0)

	let b:sacpMatch = s:getFirstMatch(l:text,l:needIgnoreCompletionMode)
	if empty(b:sacpMatch)
		call s:TempOmniAutoRefresh()
		return ''
	endif

	let b:sacpLastCompleteMatch = b:sacpMatch

	" In case of dividing words by symbols (e.g. "for(int", "ab==cd") while a
	" popup menu is visible, another popup is not available unless input <C-e>
	" or try popup once. So first completion is duplicated.
	" call s:setTempOption(s:GROUP0, 'spell', 0)
	" call s:setTempOption(s:GROUP0, 'complete', g:acp_completeOption)
	" call s:setTempOption(s:GROUP0, 'ignorecase', g:acp_ignorecaseOption)
	" NOTE: With CursorMovedI driven, Set 'lazyredraw' to avoid flickering.
	"       With Mapping driven, set 'nolazyredraw' to make a popup menu visible.
	" call s:setTempOption(s:GROUP0, 'lazyredraw', !g:acp_mappingDriven)
	" NOTE: 'textwidth' must be restored after <C-e>.
	" call s:setTempOption(s:GROUP1, 'textwidth', 0)
	" call s:setCompletefunc()

	let b:sacpCompleteDone = 0
	let b:sacpSmartCompleteDone = 0
	call feedkeys(b:sacpMatch.feedkeys)
	return '' " this function is called by <C-r>=

endfunction

function! sacp#setCompleteDone()
	let b:sacpCompleteDone = 1
	let b:sacpSmartCompleteDone = 1
endfunction

function! s:getCurrentText()
	return strpart(getline('.'), 0, col('.') - 1)
endfunction

function! s:getFirstMatch(text,needIgnoreCompletionMode)
	for l:m in b:sacpOptions['matches']
		if (a:needIgnoreCompletionMode==1) && get(l:m,"ignoreCompletionMode",0)==0
			continue
		endif
		let l:ret = s:checkMatch(a:text,l:m)
		if !empty(l:ret)
			return l:ret
		endif
	endfor
	return {}
endfunction

function! s:checkMatch(text,m)
	for [l:operator,l:pattern] in items(a:m)
		if l:operator =~ '^[=~=!#]\{1,}$' " is operator
			let l:r = eval("a:text ".l:operator." l:pattern")
			if l:r == 1
				return a:m
			endif
		endif
	endfo
	return {}
endfunction


" manage wrapped omni functions {

" parameters:
" {
"	'omnifunc' :
"	'autorefresh' : 
"	'onfinish' :
" }
function! sacp#TempOmniBegin(opt)

	if !exists("b:sacpTempOmniCnt")
		autocmd CompleteDone <buffer> call s:TempOmniOnCompleteDone()
	endif

	if get(b:,"sacpTempOmniCnt",0)==0
		let b:sacpTempOmniOriginOmnifunc = &l:omnifunc
	endif

	" If still in sacp#TempOmni completion mode, call the onfinish for the
	" previous setting
	if exists('b:sacpTempOmniOpt["onfinish"]')
		call b:sacpTempOmniOpt["onfinish"]()
	endif

	let b:sacpTempOmniOpt = a:opt
	let b:sacpTempOmniCnt = get(b:,"sacpTempOmniCnt",0)+1

	let &l:omnifunc = a:opt["omnifunc"]
	call feedkeys("\<C-X>\<C-O>",'t')

endfunction

" if autorefresh is not set, this function has no effect
function! s:TempOmniAutoRefresh()
	if !exists('b:sacpTempOmniOpt')
		return
	endif
	if get(b:sacpTempOmniOpt,'autorefresh',0) == 0
		return
	endif
	let b:sacpTempOmniCnt += 1

	" NOTICE:
	" workaround for vim's bug, <C-X><C-O> key will update vim's changed tick
	" if !has('nvim') " && !pumvisible()
	" 	let b:sacpTempOmniAutoRefreshed=1
	" endif
	noautocmd call feedkeys("\<C-X>\<C-O>",'t')
endfunction

function! s:TempOmniOnCompleteDone()

	if get(b:,"sacpTempOmniCnt",0)==0
		return
	endif

	let b:sacpTempOmniCnt-=1
	if b:sacpTempOmniCnt>0
		return
	endif

	if exists('b:sacpTempOmniOpt["onfinish"]')
		call b:sacpTempOmniOpt["onfinish"]()
		unlet b:sacpTempOmniOpt
	endif

	" resume the origional omni func
	let &l:omnifunc = b:sacpTempOmniOriginOmnifunc 
endfunction

function! sacp#TempOmniGetOriginOmnifunc()
	if get(b:,"sacpTempOmniCnt",0)>0
		return b:sacpTempOmniOriginOmnifunc
	else
		return &l:omnifunc
	endif
endfunction

" }

