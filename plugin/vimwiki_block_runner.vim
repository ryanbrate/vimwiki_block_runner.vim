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
    " Note: where not in block, empty list returned

    " find the line numbers of all delimeters in the buffer
    let l:delim_positions = Filter(
                \{i->getline(i) =~ '^' . '\(' . join(a:delimiters, '\|') . '\)'}, 
                \range(1, line('$'))
                \)

    " retrieve type of previous delimiter
    let l:previous_line = max(Filter({i -> i<line('.')}, l:delim_positions))
    let l:previous = getline(l:previous_line) =~ a:delimiters[0] ? 1 :
                \getline(l:previous_line) =~ a:delimiters[1] ? 2 :
                \0 " where 1 = opening, 2 = closing, 0 = none
    
    " retrieve type of next delimeter
    let l:next_line = min(Filter({i -> i>line('.')}, l:delim_positions))
    let l:next = getline(l:next_line) =~ a:delimiters[0] ? 1 :
                \getline(l:next_line) =~ a:delimiters[1] ? 2 :
                \0 " where 1 = opening, 2 = closing, 0 = none

    " get the delimiters on the current line
    let l:current = getline('.') =~ a:delimiters[0]? 1 : 
                \getline('.') =~ a:delimiters[1] ? 2 :
                \0 " where 1 = opening, 2 = closing, 0 = none

    " handle return based on scenario...

    " case where cursor on opening delimiter
    if l:current == 1
        if line('.') == line('$')
            return []
        elseif l:next == 1 || l:next == 0
            return []
        elseif l:next == 2
            return [line('.'), l:next_line]
        endif 
    " case where cursor on closing delimiter
    elseif l:current == 2
        if line('.') == 1
            return []
        elseif l:previous == 2 || l:previous == 0
            return []
        elseif l:previous == 1
            return [l:previous_line, line('.')]
        endif
    " case where cursor no on delimiter
    else
        if l:previous == 0 || l:next == 0
            return []
        elseif l:previous == l:next
            return []
        elseif l:previous == 2 && l:next == 1
            return []
        elseif l:previous == 1 && l:next ==2
            return [l:previous_line, l:next_line]
        endif
    endif
    
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
    if len(l:block_extents) != 0 " cursor is in a block

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
            let l:results = systemlist(printf(g:vwbr_commands[l:block_type], l:temp_file))
            echom 'results = ' . join(l:results, ', ')

            " append output to end of block
            for [index, output] in Enumerate(l:results)
                call append(l:block_close_line + index, output)
            endfor

        endif
    endif

endfunction
