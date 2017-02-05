# SimpleAutoComplPop

**Note: I'm not mantaining this plugin anymore, in favor of
[nvim-completion-manager](https://github.com/roxma/nvim-completion-manager).
If you have plans for improving this plugin by yourself, please contact me, I'll
transfer the project ownership.**

A simplified fork from [vim-scripts/AutoComplPop](https://github.com/vim-scripts/AutoComplPop)

SimpleAutoComplPop is a **lightweight**, **pure vimscript** plugin, which
focuses on **easy to use**, and **easy to be extended** for your own use cases.
SACP **maps keys on a per-buffer basis**. Technically it will not conflict with
other auto-complete plugin if you configure carefully. 

# Usage

Currently, SACP only provides default configurations for php, go, txt and
markdown files.

## PHP

```vim
	autocmd FileType php,php5,php7 call sacp#enableForThisBuffer({ "matches": [
				\ { '=~': '\v[a-zA-Z]{4}$', 'feedkeys': "\<C-x>\<C-o>"},
				\ { '=~': '::$'           , 'feedkeys': "\<C-x>\<C-o>"},
				\ { '=~': '->$'           , 'feedkeys': "\<C-x>\<C-o>"},
				\ ]
				\ })
```

This demo requires [phpcomplete.vim](https://github.com/shawncplus/phpcomplete.vim).


![php_demo](https://github.com/roxma/SimpleAutoComplPop.img/blob/master/usage_php_demo.gif)

## Golang

```vim
	" 1. variables are all defined in current scope, use keyword from current
	" buffer for completion `<C-x><C-n>`
	" 2. When the '.' is pressed, use smarter omnicomplete `<C-x><C-o>`, this
	" works well with the vim-go plugin
	autocmd FileType go call sacp#enableForThisBuffer({ "matches": [
				\ { '=~': '\v[a-zA-Z]{4}$' , 'feedkeys': "\<C-x>\<C-n>"} ,
				\ { '=~': '\.$'            , 'feedkeys': "\<C-x>\<C-o>", "ignoreCompletionMode":1} ,
				\ ]
				\ })
```

This demo requires [vim-go](https://github.com/fatih/vim-go).

![go_demo](https://github.com/roxma/SimpleAutoComplPop.img/blob/master/usage_go_demo.gif)

Seems good. While SACP provides **a slightly improved
plugin key
[`<Plug>(sacp_cache_fuzzy_omnicomplete)`](#plugsacp_cache_fuzzy_omnicomplete)**.
Check the [Advanced Features](#advanced-features) section For more details.


## Configiration Options Explained

- To disable SACP, add `let g:sacpEnable = 0` to your vimrc file.
- To enable the default auto-complete-popup behavior for php only, add `let
    g:sacpDefaultFileTypesEnable = {"php":1}` to your vimrc file.
- **sacp#enableForThisBuffer** options: 
    - **matches** is a list of patterns, pattern is matched, the keys
        corrosponding the pattern will be feed to vim.
        - **ignoreCompletionMode**. By default, Keys will not be feeded by SACP
            if popup enu is visible or vim is still in completion mode (`:help
            CompleteDone`).  However, It's difficult for complete-functions to
            leave completion mode properly.  With current version of
            [vim-go](https://github.com/fatih/vim-go) plugin for example, when
            I type `htt<C-X><C-O>` it will popup a list containing `http`, then
            I proceed the typing to `htt<C-X><C-O>p.`.  When the `.` is typed
            the popup menu is gone, but the event `CompleteDone` event is not
            triggered. Set the `ignoreCompletionMode` to `1` would force
            SACP to feed the `<C-X><C-O>` keys..
    - **completeopt**, the default value for this option is
        `"menu,menuone,noinsert,noselect"`, set it to `"menu,menuone,noinsert"`
        if you want the first hint to be selected by default.


## Advanced Features

### `<Plug>(sacp_cache_fuzzy_omnicomplete)`

Use the golang example before, I'll change the `\<C-x>\<C-o>` into
`\<Plug>(sacp_cache_fuzzy_omnicomplete)`. This key is based on user's default
omnifunc, it catches the first list return by omnifunc, then provide fuzzy
completion feature.

```
	" 1. variables are all defined in current scope, use keyword from current
	" buffer for completion `<C-x><C-n>`
	" 2. When the '.' is pressed, use smarter omnicomplete `<C-x><C-o>`, this
	" works well with the vim-go plugin
	autocmd FileType go call sacp#enableForThisBuffer({ "matches": [
				\ { '=~': '\v[a-zA-Z]{2}$' , 'feedkeys': "\<C-x>\<C-n>"} ,
				\ { '=~': '\.$'            , 'feedkeys': "\<Plug>(sacp_cache_fuzzy_omnicomplete)", "ignoreCompletionMode":1} ,
				\ ]
				\ })
```

Type `http.ok`, then there goes the first hint `StatusOk`


![go_demo](https://github.com/roxma/SimpleAutoComplPop.img/blob/master/advanced_go_demo.gif)



### `<Plug>(sacp_cache_fuzzy_bufferkeyword_complete)`

Use the keywords (`:help iskeyword`) from current buffer for fuzzy completion.
It only scans the keywords from the 50 lines before and after the current line,
for performance issue.  Use the golang example, replace the `"\<C-x>\<C-n>"`
with `"\<Plug>(sacp_cache_fuzzy_bufferkeyword_complete)"` and see what happens.

