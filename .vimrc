augroup fusionscript_lua
	autocmd BufWritePost *.lua AsyncRun ldoc .
	autocmd BufWritePost *.ld AsyncRun ldoc .
augroup END

setlocal suffixesadd+=.lua
