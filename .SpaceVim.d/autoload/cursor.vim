function! cursor#after() abort
au VimLeave,VimSuspend * set guicursor=a:ver26
endfunction
