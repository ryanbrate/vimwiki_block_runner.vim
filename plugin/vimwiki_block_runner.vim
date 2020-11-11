" Vim plugin facilitating the running of blocks of code embedded in vimwiki
" Last Change: 10 Nov 2008
" By: Ryan Brate

" Requires functional.vim functions
if !exists('g:loaded_functional_vim') | finish | endif

if exists('g:loaded_vimwiki_block_runner_vim') | finish | endif
let g:loaded_vimwiki_block_runner_vim = 1

function! Get_block_extents(delimiters) abort
    " Return a list of line numbers of delimiters enclosing the current line.
    " If not in block return 0.
    "
    " Args:
    "   delimiters (list): [opening, closing]
    "       e.g., ['{{{', '}}}']
    " Return: 
    "   E.g., [25, 29], buffer line number of start and stop delimiters,
    "   respectively.
    "
    "   Note: one of return list is zero if not in a block (or in incorrectly
    "   formed block)

    let l:opening_delimiter_line = 0
    let l:closing_delimiter_line = 0
    
    " case where cursor on opening delimiter
    if getline('.') =~ '^' . a:delimiters[0]
        let l:opening_delimiter_line = line('.')
        for i in range(line('.')+1, line('$')) " examine subsequent lines sequentially for next delim
            if getline(i) =~ '^' . a:delimiters[0] 
                let l:closing_delimiter_line = 0 " next delimiter is also an opening
                break
            elseif getline(i) =~ '^' . a:delimiters[1]
                let l:closing_delimiter_line = i
                break
            endif
        endfor

    " case where cursor is on closing delimiter
    elseif getline('.') =~ '^' . a:delimiters[1]
        let l:closing_delimiter_line = line('.')
        if line('.') == 1
            let l:opening_delimiter_line = 0
        else
            " examine previous lines sequentially for next delim
            for i in range(line('.')-1, 1, -1) 
                 if getline(i) =~ '^' . a:delimiters[0] 
                    let l:closing_delimiter_line = i 
                    break
                elseif getline(i) =~ '^' . a:delimiters[1]
                    let l:closing_delimiter_line = 0 " next delimiter is also an closing
                    break
                endif
            endfor
        endif

    " case where cursor is between delimiters
    else
        " search earlier lines for delimiters
        for i in range(line('.')-1, 1, -1)
            if getline(i) =~ '^' . a:delimiters[0]
                let l:opening_delimiter_line = i
                break
            elseif getline(i) =~ '^' . a:delimiters[1]
                let l:opening_delimiter_line = 0 " next earliers is not an opening
                break
            endif
        endfor

        " search later lines for delimiters
        for i in range(line('.')+1, line('$'))
            if getline(i) =~ '^' . a:delimiters[0]
                let l:closing_delimiter_line = 0  " next latest in not a closing
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
    " copy the current block to temp file.

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
    " execute the current block

    let l:inputs =  Get_block() " [block_type, block_closing_line, temp_file]
    echom printf('inputs = %s', join(l:inputs, ', '))

    " carry on block extracted, and an interpreter defined for block type
    if exists('g:vwbr_commands')

        if In(l:inputs[0], keys(g:vwbr_commands))

            let l:block_type = l:inputs[0]

            if In(l:block_type, keys(g:vwbr_commands))  " interpreter for block type is defined

                let l:block_close_line = l:inputs[1]
                let l:temp_file = l:inputs[2]

                " execute code, and capture output
                let l:result = system(printf(g:vwbr_commands[l:block_type], l:temp_file))

                " append output to end of block
                call append(l:block_close_line, l:result)
            endif
        endif
    endif

endfunction

