# SimpleAutoComplPop

A simplified fork from [vim-scripts/AutoComplPop](https://github.com/vim-scripts/AutoComplPop)

# Why I Create This Plugin?

I'm a PHP developer, and currently I'm using neovim. 

- [Neocomplete](https://github.com/Shougo/neocomplete.vim) needs `if_lua`,
	which is not possible with neovim currently.
- ~~With [deoplete](https://github.com/Shougo/deoplete.nvim) framework,
    currently the only option is
    [phpcomplete-extended](https://github.com/m2mdas/phpcomplete-extended).
    But phpcomplete_extended seems to be unmaintained right now, the latest
    comment is from two years ago.~~
- [YCM](https://github.com/Valloric/YouCompleteMe) is really a great one. But
    It's just too heavy for me, it significantly slows down my vim's startup
    time.
- The origional [AutoComplPop](https://github.com/vim-scripts/AutoComplPop) is
	a little bit complicated, and hard to extend for me.
- I know I would be re-inventing the wheel but I just couldn't stop it :joy:

Finally I decided to create my own SimpleAutoComplPop, focus on **easy to
use**, and **easy to be extended** for your own use cases. SimpleAutoComplPop
is **pure vimscript**, and it **maps keys on a per-buffer basis**. Technically
it will not conflict with other auto-complete plugin if you configure
carefully. 

As a **lightweight** plugin, the [default auto-complete-popup
behavior](plugin/sacp.vim) provideed by this plugin only covers `.php`, `.txt`,
`.markdown`, and `.go` files, for demonstration purpose.  If you have a good
configuration to share, please send me a gist url or a your github repo url,
I'll add it into this README.md or probably created a wiki page for nice
configurations for other filetypes.

# Usage

## PHP

Currently, this is the default php pattern, use omnicomplete's `<C-X><C-o>` key
to for completion.

```vimscript
	autocmd FileType php,php5,php7 call sacp#enableForThisBuffer({ "matches": [
				\ { '=~': '\v[a-zA-Z]{4}$', 'feedkeys': "\<C-x>\<C-o>"},
				\ { '=~': '::$'           , 'feedkeys': "\<C-x>\<C-o>"},
				\ { '=~': '->$'           , 'feedkeys': "\<C-x>\<C-o>"},
				\ ]
				\ })
```

Demo with [phpcomplete.vim](https://github.com/shawncplus/phpcomplete.vim).
Press `<TAB>` to select the popup menu.

![php_demo](https://github.com/roxma/SimpleAutoComplPop.img/blob/master/usage_php_demo.gif)

## Golang

```
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

The special dot character `'.'` needs `'ignoreCompletionMode'` to be set to
work with [vim-go](https://github.com/fatih/vim-go), see the
[#configiration-options-explained](#configiration-options-explained) for more
details.

Demo with [vim-go](https://github.com/fatih/vim-go)

![go_demo](https://github.com/roxma/SimpleAutoComplPop.img/blob/master/usage_go_demo.gif)

This demo looks ok. However SimpleAutoComplPop provide **a slightly improved
plugin key
[`<Plug>(sacp_cache_fuzzy_omnicomplete)`](#plugsacp_cache_fuzzy_omnicomplete)**.
Check the [Advanced Features](#advanced-features) section For more information.


## Configiration Options Explained

- To disable SimpleAutoComplPop, add `let g:sacpEnable = 0` to your vimrc file.
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
            SimpleAutoComplPop to feed the `<C-X><C-O>` keys..
    - **completeopt**, the default value for this option is
        `"menu,menuone,noinsert,noselect"`, set it to `"menu,menuone,noinsert"`
        if you want the first hint to be selected by default.


## Advanced Features

I'm planning on add some advanced features based on SimpleAutoComplPop's
lightweight core, while these features will not be loaded into vim if you don't
use them. Read the following description if you are interested:

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

