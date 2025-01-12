.8086
.model  small
.stack  100h

.data
argL    db 0                ; Will hold the length of the command-line
argV    db 128 dup (0)      ; Will hold the command-line path
dta     db 128 dup (0)      ; DTA for file search

msgNoFiles  db 0Dh,0Ah, 'No files found.', 0Dh,0Ah, '$'
msgDone     db 0Dh,0Ah, '[Done]', 0Dh,0Ah, '$'

.code
start:
    ;---------------------------------------------------------------------
    ; 1) Set DS to our data segment
    ;---------------------------------------------------------------------
    mov     ax, @data
    mov     ds, ax

    ;---------------------------------------------------------------------
    ; 2) Retrieve PSP segment with DOS fn 62h => PSP in BX => put into ES
    ;---------------------------------------------------------------------
    mov     ah, 62h
    int     21h
    mov     es, bx          ; ES = PSP segment

    ;---------------------------------------------------------------------
    ; 3) Read command-line length from PSP:80h
    ;---------------------------------------------------------------------
    mov     al, [es:80h]    ; AL = length (0..127)
    mov     [argL], al      ; store in argL

    ;---------------------------------------------------------------------
    ; 4) Copy that many bytes from PSP:82h to argV
    ;---------------------------------------------------------------------
    mov     cl, al          ; CL = length
    mov     si, 82h         ; offset in PSP where text starts
    mov     di, offset argV ; DS:DI => our buffer
    sub     cl, 1           ; skip trailing CR (common in PSP)
copy_args:
    mov     al, [es:si]
    mov     [di], al
    inc     si
    inc     di
    loop    copy_args

    ; Null-terminate it (C-style)
    mov     byte ptr [di], 0

    ;---------------------------------------------------------------------
    ; 5) Append "\*.*" automatically if path does not end with a slash
    ;---------------------------------------------------------------------
    ; Let's find the terminating 0 we just wrote, and look at the previous char.
    ; If it’s not '\' then we add '\*.*'. 
    ; 
    ; NOTE: This is a simplistic approach. If user typed wildcards themselves
    ; (like "C:\MYDIR\*.TXT"), you will end up with "C:\MYDIR\*.TXT\*.*".
    ; In a real program, you might want more checks or different logic.
    ;---------------------------------------------------------------------
    dec     di               ; step back to look at last typed character
    mov     al, [di]         ; AL = last typed character
    cmp     al, '\'          ; did user already type a backslash?
    je      skip_backslash   ; if so, skip adding backslash
    inc     di               ; else restore DI 
    mov     byte ptr [di], '\' ; add a backslash
    inc     di
    jmp     add_wildcards

skip_backslash:
    inc     di               ; restore DI to the terminator

add_wildcards:
    ; now add "*.*"
    mov     byte ptr [di], '*'
    inc     di
    mov     byte ptr [di], '.'
    inc     di
    mov     byte ptr [di], '*'
    inc     di
    mov     byte ptr [di], 0  ; null-terminate again
    inc     di

    ;---------------------------------------------------------------------
    ; (Optional) Print the final path, for debugging (DOS fn 09h => '$')
    ; Overwrite the final 0 with '$', then restore it to 0 after printing.
    ;---------------------------------------------------------------------
    push    di                    ; save DI
    dec     di
    mov     byte ptr [di], '$'    ; replace the 0 terminator with '$'
    mov     dx, offset argV
    mov     ah, 09h
    int     21h
    ; Print CR/LF
    mov     ah, 02h
    mov     dl, 0Dh  ; CR
    int     21h
    mov     dl, 0Ah  ; LF
    int     21h
    ; Restore the 0 terminator
    pop     di
    mov     byte ptr [di], 0

    ;---------------------------------------------------------------------
    ; 7) Set our Disk Transfer Area for file search => AH=1Ah
    ;---------------------------------------------------------------------
    mov     dx, offset dta
    mov     ah, 1Ah
    int     21h

    ;---------------------------------------------------------------------
    ; 8) "Find First" => AH=4Eh, DS:DX => argV, CX=0 => normal files
    ;---------------------------------------------------------------------
    mov     dx, offset argV
    mov     cx, 0
    mov     ah, 4Eh
    int     21h
    jc      no_files         ; carry set => error => no files found

print_loop:
    ;---------------------------------------------------------------------
    ; 9) Print the file name from the DTA at offset 1Eh (11 bytes, space-padded)
    ;---------------------------------------------------------------------
    mov     si, offset dta
    add     si, 1Eh          ; point SI to the 11-byte "FILENAMEEXT"
    mov     cx, 11

print_file:
    lodsb                   ; AL = [DS:SI], SI++
    cmp     al, ' '
    je      skip_char
    mov     dl, al
    mov     ah, 02h         ; DOS: print char in DL
    int     21h
skip_char:
    loop    print_file

    ; Print CR/LF
    mov     dl, 0Dh
    mov     ah, 02h
    int     21h
    mov     dl, 0Ah
    mov     ah, 02h
    int     21h

    ;---------------------------------------------------------------------
    ; 10) "Find Next" => AH=4Fh
    ;---------------------------------------------------------------------
    mov     ah, 4Fh
    int     21h
    jnc     print_loop   ; if no error => we have another file => loop

    jmp     done_listing

no_files:
    ;---------------------------------------------------------------------
    ; If "Find First" failed => print "No files found."
    ;---------------------------------------------------------------------
    mov     dx, offset msgNoFiles
    mov     ah, 09h
    int     21h

done_listing:
    ;---------------------------------------------------------------------
    ; Print "[Done]" then exit
    ;---------------------------------------------------------------------
    mov     dx, offset msgDone
    mov     ah, 09h
    int     21h

    mov     ax, 4C00h
    int     21h

end start