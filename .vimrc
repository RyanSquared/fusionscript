augroup fusionscript_config
	autocmd BufWritePost *.lua AsyncRun ldoc .
	autocmd BufWritePost *.ld AsyncRun ldoc .
	autocmd VimEnter luacov.report.out call search("\\**0")
augroup END

setlocal suffixesadd+=.lua
