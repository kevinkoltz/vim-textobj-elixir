let s:save_cpo = &cpo
set cpo&vim

" each pair has the syntax element and the vim syntax label
let s:terms=[
      \ ['schema',      'elixirEctoSchemaMacro'],
      \ ['setup_all',   'elixirExUnitMacro'],
      \ ['setup',       'elixirExUnitMacro'],
      \ ['describe',    'elixirExUnitMacro'],
      \ ['test',        'elixirExUnitMacro'],
      \ ['object',      'elixirAbsintheMacro'],
      \ ['field',       'elixirAbsintheMacro'],
      \ ['input_object', 'elixirAbsintheMacro'],
      \ ['unless',      'elixirKeyword'],
      \ ['quote',       'elixirKeyword'],
      \ ['case',        'elixirKeyword'],
      \ ['cond',        'elixirKeyword'],
      \ ['when',        'elixirKeyword'],
      \ ['with',        'elixirKeyword'],
      \ ['for',         'elixirKeyword'],
      \ ['if',          'elixirKeyword'],
      \ ['defprotocol', 'elixirProtocolDefine'],
      \ ['defmodule',   'elixirModuleDefine'],
      \ ['defmacro',    'elixirMacroDefine'],
      \ ['defmacrop',   'elixirPrivateMacroDefine'],
      \ ['defimpl',     'elixirImplDefine'],
      \ ['defp',        'elixirPrivateDefine'],
      \ ['def',         'elixirDefine']
      \]

" -----------------------------------------------------
" -- TERM - query / transform term

function! s:term_reg()
  return join(s:term_keys(), '\|')
endfunction

function! s:term_dict()
  let acc = {}
  for pair in s:terms
    let acc[pair[0]] = pair[1]
  endfor
  return acc
endfunction

function! s:term_keys()
  let acc = []
  for pair in s:terms 
    call add(acc, pair[0])
  endfor
  return acc
endfunction

function! s:syntax_for_term(term)
  return s:term_dict()[a:term]
endfunction

" -----------------------------------------------------
" -- INDENT - calculate the line indent

function! s:find_indent(direction)
  let pos  = getpos('.')
  let line = search('[a-zA-A0-9]', a:direction )
  call setpos('.', pos)
  if line == 0
    throw 'not found'
  endif
  return indent(line)
endfunction

function! s:prev_indent()
  return s:find_indent('bW') + 2
endfunction

function! s:next_indent()
  return s:find_indent('W') + 2
endfunction

function! s:calculate_indent()
  return max([s:prev_indent(), s:next_indent()])
endfunction

function! s:current_indent()
  let line = substitute(getline('.'),' ','', 'g')
  return empty(line) ? s:calculate_indent() : indent('.')
endfunction

" -----------------------------------------------------
" -- SEARCH - search for a text object

function! s:syntax_for_line(line)
  return synIDattr(synID(a:line, col('.'),1), 'name')
endfunction

function! s:search_head(block, indent) 
  while 1
    let line = search( '\<\%('.a:block.'\)\>', 'bW' )
    if line == 0
      throw 'not found'
    endif
    let syntax = s:syntax_for_term(expand('<cword>'))
    if syntax == ''
      throw 'not found'
    endif
    let current_indent = indent('.')
    if current_indent < a:indent && syntax ==# s:syntax_for_line(line)
      return [syntax, current_indent, getpos('.')]
    endif
  endwhile
endfunction

function! s:search_tail(head_indent)
  while 1
    let line = search('end', 'W')
    if line == 0
      throw 'not found'
    endif
    if indent('.') == a:head_indent && 'elixirBlockDefinition' ==# s:syntax_for_line(line)
      return getpos('.')
    endif
  endwhile
endfunction

function! s:search_block(block) 
  let pos = getpos('.')
  try
    let indent = s:current_indent()
    let [syntax, head_indent, head] = s:search_head(a:block, indent)
    call setpos('.', pos)
    let tail = s:search_tail(head_indent)
    return ['V', head, tail]
  catch /^not found$/
    echohl Error | echo 'block is not found.' | echohl None
    call setpos('.', pos)
    return 0
  endtry
endfunction

" narrow range by 1 line on both sides
function! s:inside(range) 
  " check if range exists
  if type(a:range) != type([]) || a:range[1][1]+1 > a:range[2][1]-1
    return 0
  endif
  let range = a:range
  let range[1][1] += 1
  let range[2][1] -= 1
  return range
endfunction

" -----------------------------------------------------
" -- SELECT - main functions

function! textobj#elixir#any_select_i() 
  return s:inside(s:search_block(s:term_reg()))
endfunction

function! textobj#elixir#any_select_a()
  return s:search_block(s:term_reg())
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
