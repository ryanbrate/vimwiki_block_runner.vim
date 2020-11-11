# vimwiki_block_runner.vim

A plugin to evaluate a code block defined within vimwiki, appending the printed output immediately after the codeblock 

## Example

With cursor (anywhere) within the code block, run *:call Execute_Block()*

```
{{{python


}}}
--> The block output is appended immediately after the block
```

## Installation

E.g., using [vim-plug](https://github.com/junegunn/vim-plug)

```
Plug 'ryanbrate/functional.vim'
Plug 'ryanbrate/vimwiki_block_runner'
```

## set vimrc variables

1. Define 'block labels':'block run commands' pairs in g:vwbr_commands.

E.g.
```
let g:vwbr_commands = {
    \'python':'python3 %s',
    \}
```

Where *%s* denotes the code block to be executed

2. Shortcut mapping to execute a block

```
augroup FileType vimwiki
    au! 
    au Filetype vimwiki nnoremap <buffer> <Leader>wb call Execute_Block()
augroup END
```
