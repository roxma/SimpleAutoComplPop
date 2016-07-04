
" sacp enhanced buffer keyword complete

function! sacpbuffer#begin()

	" call sacp#writeLog('sacpbuffer#begin') " debug

	silent! unlet b:sacpbufferCompleteStartColumn
	silent! unlet b:sacpbufferCompleteCache
	silent! unlet b:sacpbufferInitialBase

	" Avoid this function to be called again when backspace is pressed
	" , for example 'http.st<BS><BS>' .
	" call sacp#lock()

	let l:autorefresh = 1
	if has('nvim')
		let l:autorefresh = 0
	endif
	call sacp#TempOmniBegin({'omnifunc': 'sacpbuffer#complete', 'onfinish': function('s:done'), 'autorefresh': l:autorefresh})

	return ''

endfunction


function! s:done()

	" call sacp#writeLog('sacpbuffer#done') " debug

	silent! unlet b:sacpbufferCompleteStartColumn
	silent! unlet b:sacpbufferCompleteCache
	silent! unlet b:sacpbufferInitialBase
	silent! unlet b:sacpbufferRetList
	silent! unlet b:sacpbufferLastBase

endfunction


function! sacpbuffer#complete(findstart,base)

	" call sacp#writeLog("sacpbuffer#complete findsart:" . a:findstart .", base:[" . a:base ."]" ) " debug

	" first call
	if a:findstart == 1
		" return the old base if vim calls here again
		if exists('b:sacpbufferCompleteStartColumn')
			return b:sacpbufferCompleteStartColumn
		endif
		let b:sacpbufferCompleteStartColumn = match(strpart(getline('.'), 0, col('.') - 1),'\k*$')
		if -1 == b:sacpbufferCompleteStartColumn
			b:sacpbufferCompleteStartColumn = col('.') - 1
		endif
		return b:sacpbufferCompleteStartColumn
	endif

	" cache keywords for completion
	if !exists('b:sacpbufferCompleteCache')
		let b:sacpbufferInitialBase = a:base
		let b:sacpbufferLastBase    = a:base
		let l:scope = 100
		let l:beginL = max([1,line('.')-l:scope])
		let l:endL = min([line('$'),line('.')+l:scope])
		" \%<23l	Matches above a specific line (lower line number).
		" \%>23l	Matches below a specific line (higher line number).
		" let l:matchId = matchadd('sacpbuffer','\%<'.l:endL.'\%>'.l:beginL . '\k\{1,}')
		" let l:matches = getmatches()
		" let l:hls = &hlsearch
		" set nohlsearch
		let b:sacpbufferCompleteCache = []
		let l:chars = split(a:base,'\ze')
		let l:i = 0
		while l:i<len(l:chars)
			if l:chars[l:i] ==# '/'
				let l:chars[l:i] = '\/'
			elseif  l:chars[l:i] ==# '\'
				let l:chars[l:i] = '\\'
			elseif  l:chars[l:i] ==# '?'
				let l:chars[l:i] = '\?'
			endif
			let l:i+=1
		endwhile
		if empty(a:base)
			let l:pattern = '\V\k\+'
		else
			let l:pattern = '\c\V\k\*'.join(l:chars,'\k\*').'\k\*'
		endif
		silent! execute l:beginL.','.l:endL.' s/'.l:pattern.'/\=add(b:sacpbufferCompleteCache,{"word":submatch(0), "abbr":"", "menu":"", "info":"", "icase":1, "dup": 1, "empty": 1})/nge'
		" call sacp#writeLog("pattern: " . l:pattern) " debug
		call uniq(sort(b:sacpbufferCompleteCache))
	endif

	if len(a:base) > len(b:sacpbufferLastBase)
		" The search would be narrowed down, use last returned result
		let l:loopList = b:sacpbufferRetList
		" call sacp#writeLog('narrow ,cache size: '. len(b:sacpbufferCompleteCache) . ", narrowed Size:".len(l:loopList))
	else
		" call sacp#writeLog('rebegin ,cache size: '. len(b:sacpbufferCompleteCache))
		let l:loopList = b:sacpbufferCompleteCache
	endif

	let b:sacpbufferRetList = []
	let l:begin = len(b:sacpbufferInitialBase)
	for l:w in l:loopList
		let l:m = s:WordMatchInfo(l:begin,a:base,l:w.word)
		if empty(l:m)
			" call sacp#writeLog("[" . l:w.word . "] does not match base:".a:base) " debug
			continue
		endif
		" call sacp#writeLog("[" . l:w.word . "] match base:".a:base) " debug
		let l:w.sacpbuffer_match = l:m
		call add(b:sacpbufferRetList,l:w)
	endfor

	call sort(b:sacpbufferRetList,function('s:sortCandidate'))

	" " clear unneaded data ---
	" let l:i = 0
	" while l:i < len(b:sacpbufferRetList)
	" 	unlet b:sacpbufferRetList[l:i].sacpbuffer_match
	" 	let l:i+=1
	" endwhile
	
	" call sacp#writeLog('return size: '. len(b:sacpbufferRetList))

	if empty(b:sacpbufferRetList)
		if a:base=~'\V\k\+\$'
			return -2
		else
			" call s:done()
			" call sacp#writeLog('return size: '. len(b:sacpbufferRetList))
			return -1 " leave completion mode
		endif
	endif
	
	let b:sacpbufferLastBase = a:base
	return { "words":b:sacpbufferRetList, "refresh": "always"}

endfunction

function! s:sortCandidate(w1,w2)
	if (a:w1.sacpbuffer_match.end-a:w1.sacpbuffer_match.begin) < (a:w2.sacpbuffer_match.end-a:w2.sacpbuffer_match.begin)
		return -1
	endif
	if (a:w1.sacpbuffer_match.end-a:w1.sacpbuffer_match.begin) > (a:w2.sacpbuffer_match.end-a:w2.sacpbuffer_match.begin)
		return 1
	endif
	if (a:w1.sacpbuffer_match.begin) < (a:w2.sacpbuffer_match.begin)
		return -1
	endif
	if (a:w1.sacpbuffer_match.begin) > (a:w2.sacpbuffer_match.begin)
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

" call sacp#writeLog('sacpbuffer loaded') " debug

