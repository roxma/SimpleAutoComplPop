
" sacp enhanced omni complete
" cache omni list && fuzzy search complete menu

function! sacpomni#begin()

	if sacp#TempOmniGetOriginOmnifunc()==""
		call sacp#setCompleteDone()
		return ''
	endif

	silent! unlet b:sacpomniCompleteStartColumn
	silent! unlet b:sacpomniCompleteCache
	silent! unlet b:sacpomniInitialBase

	" Avoid this function to be called again when backspace is pressed
	" , for example 'http.st<BS><BS>' .
	" call sacp#lock()

	let l:autorefresh = 1
	if has('nvim')
		let l:autorefresh = 0
	endif
	call sacp#TempOmniBegin({'omnifunc': 'sacpomni#complete', 'onfinish': function('s:done'), 'autorefresh': l:autorefresh})

	return ''

endfunction


function! s:done()

	" call sacp#writeLog('sacpomnir#done') " debug

	silent! unlet b:sacpomniCompleteStartColumn
	silent! unlet b:sacpomniCompleteCache
	silent! unlet b:sacpomniInitialBase

endfunction


" wrapped omni func
function! sacpomni#complete(findstart,base)

	" call sacp#writeLog("sacpomni#complete") " debug

	" first call
	if a:findstart == 1
		" return the old base if vim calls here again
		if exists('b:sacpomniCompleteStartColumn')
			return b:sacpomniCompleteStartColumn
		endif
		let b:sacpomniCompleteStartColumn = call(sacp#TempOmniGetOriginOmnifunc(),[a:findstart,a:base])
		return b:sacpomniCompleteStartColumn
	endif

	" catche the first list return by user's omni func for fuzzy completion
	if !exists('b:sacpomniCompleteCache')
		let b:sacpomniInitialBase = a:base
		let l:ret = call(sacp#TempOmniGetOriginOmnifunc(),[a:findstart,a:base])
		if type(l:ret)==3  " list
			let b:sacpomniCompleteCache = l:ret
		elseif type(l:ret)==4 " dict
			let b:sacpomniCompleteCache = l:ret.words
		else
			return l:ret
		endif
	endif

	let l:retlist = []
	let l:begin = len(b:sacpomniInitialBase)
	" TODO: b:sacpomniCompleteCache maybe a list of strings
	for l:w in b:sacpomniCompleteCache
		let l:m = s:WordMatchInfo(l:begin,a:base,l:w.word)
		if empty(l:m)
			" call sacp#writeLog("[" . l:w.word . "] does not match base:".a:base . ", begin:".l:begin.", word:".l:w.word) " debug
			continue
		endif
		" call sacp#writeLog("[" . l:w.word . "] match base:".a:base) " debug
		let l:w.sacpomni_match = l:m
		let l:retlist += [l:w]
	endfor

	call sort(l:retlist,function('s:sortCandidate'))

	" " clear unneaded data ---
	" let l:i = 0
	" while l:i < len(l:retlist)
	" 	unlet l:retlist[l:i].sacpomni_match
	" 	let l:i+=1
	" endwhile

	return { "words":l:retlist, "refresh": "always"}

endfunction

function! s:sortCandidate(w1,w2)
	if (a:w1.sacpomni_match.end-a:w1.sacpomni_match.begin) < (a:w2.sacpomni_match.end-a:w2.sacpomni_match.begin)
		return -1
	endif
	if (a:w1.sacpomni_match.end-a:w1.sacpomni_match.begin) > (a:w2.sacpomni_match.end-a:w2.sacpomni_match.begin)
		return 1
	endif
	if (a:w1.sacpomni_match.begin) < (a:w2.sacpomni_match.begin)
		return -1
	endif
	if (a:w1.sacpomni_match.begin) > (a:w2.sacpomni_match.begin)
		return 1
	endif
	if len(a:w1) < len(a:w2)
		return -1
	endif
	if len(a:w1) > len(a:w2)
		return 1
	endif
	return 0
endfunction

" if doesnot match, return empty dict
" (2,'heol','helloworld') returns {4,8} 'ol' match 'oworl', 2 meas initial base is 'he', omitted for the match
function! s:WordMatchInfo(begin,base,word)
	let l:lb = len(a:base)
	let l:lw = len(a:word)
	let l:i = a:begin
	let l:j = l:i
	let l:begin = 0
	let l:end = -1

	if a:begin==l:lb
		return {"begin":a:begin,"end":a:begin}
	endif
	if a:base==?a:word
		" asumes world is not empty string here
		return {"begin":a:begin,"end":l:lw-1}
	endif

	while l:i<l:lb
		while l:j < l:lw
			if a:base[l:i]==?a:word[l:j]
				if l:i==a:begin
					let l:begin = l:j
				endif
				if l:i==l:lb-1
					let l:end = l:j
				endif
				let l:j+=1
				break
			endif
			let l:j+=1
		endwhile
		let l:i+=1
	endwhile

	" not match
	if l:end==-1
		return {}
	endif

	return {"begin":l:begin,"end":l:end}

endfunction

" call sacp#writeLog('sacpomni loaded') " debug

