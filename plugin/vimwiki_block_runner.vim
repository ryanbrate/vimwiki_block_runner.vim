" Vim plugin facilitating the running of blocks of code embedded in vimwiki
" Last Change: 17 Nov 2020
" By: Ryan Brate

" Requires functional.vim functions
if !exists('g:loaded_functional_vim') | finish | endif

if exists('g:loaded_vimwiki_block_runner_vim') | finish | endif
let g:loaded_vimwiki_block_runner_vim = 1

function! Get_block_extents(delimiters) abort
    " Return [opening_line, closing_line] list, for the block under the cursor
    "
    " Args:
    "   delimiters (list): [opening, closing]
    "       e.g., ['{{{', '}}}']
    " Return: 
    "   E.g., [25, 29], buffer line number of start and stop delimiters,
    "   respectively.
    "
    " Note: Where a corresponding opening or closing delimiter cannot be found, 
    " the line number of this (absent) delimiter is returned as 0

    let l:opening_delimiter_line = 0
    let l:closing_delimiter_line = 0
    
    " case where cursor on opening delimiter
    if getline('.') =~ '^' . a:delimiters[0]

        let l:opening_delimiter_line = line('.')

        " examine subsequent lines sequentially for closing delim
        for i in range(line('.')+1, line('$')) 
            " next delimiter is also an opening, not a closing...eek!
            if getline(i) =~ '^' . a:delimiters[0] 
                let l:closing_delimiter_line = 0 
                break
            " bingo!
            elseif getline(i) =~ '^' . a:delimiters[1]
                let l:closing_delimiter_line = i
                break
            endif
        endfor

    " case where cursor is on closing delimiter
    elseif getline('.') =~ '^' . a:delimiters[1]

        let l:closing_delimiter_line = line('.')

        " if the closing delimiter is on first line, there cannot be a
        " corrsponding opening...eek!
        if line('.') == 1
            let l:opening_delimiter_line = 0
        else
            " examine previous lines sequentially for an opening delimiter
            for i in range(line('.')-1, 1, -1) 
                 if getline(i) =~ '^' . a:delimiters[0] 
                    let l:closing_delimiter_line = i 
                    break
                " next delimiter is also a closing...eek!
                elseif getline(i) =~ '^' . a:delimiters[1]
                    let l:closing_delimiter_line = 0 
                    break
                endif
            endfor
        endif

    " case where cursor is between delimiters (may be inblock or not)
    else
        " search earlier lines for delimiters
        for i in range(line('.')-1, 1, -1)
            if getline(i) =~ '^' . a:delimiters[0]
                let l:opening_delimiter_line = i
                break
            " next earliest is not an opening delim...cursor not in a block
            elseif getline(i) =~ '^' . a:delimiters[1]
                let l:opening_delimiter_line = 0 
                break
            endif
        endfor

        " search later lines for delimiters
        for i in range(line('.')+1, line('$'))
            " next latest is not a closing delim...cursor not in a block
            if getline(i) =~ '^' . a:delimiters[0]
                let l:closing_delimiter_line = 0  
                break
            elseif getline(i) =~ '^' . a:delimiters[1]
                let l:closing_delimiter_line = i
                break
            endif
        endfor
    endif

    return [l:opening_delimiter_line, l:closing_delimiter_line]

endfunction

function! Get_block(delimiters = ['{{{', '}}}'], temp_file = $HOME . '/.vim/plugged/vimwiki_block_runner.vim/temp/block') abort
    " copy the current block to temp file. Ignore if not in a block
    "
    " Args:
    "   delimiters (list): the opening and closing block delimiters
    "   temp_file (str): path of temp file to store the block code for running
    "
    " Returns:
    "   if in a block: [block_type, block_entents, temp_file_path]
    "   else: 0

    " get the line numbers of current block
    let l:block_extents = Get_block_extents(a:delimiters)    
    echom 'block extents = ' . join(l:block_extents, ', ')

    " copy the block to temp file
    if !In(0, l:block_extents)  " cursor is in a block

        " Get the block type
        let l:block_type = split(getline(l:block_extents[0]), a:delimiters[0])[0]
        echom printf('block type = %s', l:block_type)

        " write the block contents to temp file
        execute ':' . string(l:block_extents[0]+1) . ',' . string(l:block_extents[1]-1) . 'w! ' . a:temp_file
        
        return [l:block_type, l:block_extents[1], a:temp_file]

    else " cursor not in a block
        return 0
    endif

endfunction

function! Execute_Block() abort
    " Execute the current code block under cursor.

    let l:inputs =  Get_block() " [block_type, block_closing_line, temp_file]
    echom printf('inputs = %s', join(l:inputs, ', '))

    if exists('g:vwbr_commands')

        let l:block_type = l:inputs[0]

        " is there a block type execution command defined (e.g., in .vimrc)
        if In(l:block_type, keys(g:vwbr_commands))

            let l:block_close_line = l:inputs[1]
            let l:temp_file = l:inputs[2]

            " execute code, and capture output
            let l:result = system(printf(g:vwbr_commands[l:block_type], l:temp_file))

            " append output to end of block
            call append(l:block_close_line, l:result)
        endif
    endif

endfunction
