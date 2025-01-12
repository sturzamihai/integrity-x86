.8086
.model  small
.stack  100h

.data
argL    db 0                ; Will hold the length of the command-line
argV    db 128 dup (0)      ; Will hold the command-line path
dta     db 128 dup (0)      ; DTA for file search

msgNoFiles  db 0Dh,0Ah, 'No files found.', 0Dh,0Ah, '$'
msgDone     db 0Dh,0Ah, '[Done]', 0Dh,0Ah, '$'
msgDir      db ' <DIR>',0

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
    ; 6) Print the final path + newline
    ;---------------------------------------------------------------------
    push    di                     ; save DI
    dec     di
    mov     byte ptr [di], '$'     ; replace 0 with '$' for AH=09h
    mov     dx, offset argV
    mov     ah, 09h
    int     21h
    ; Print CR/LF
    mov     ah, 02h
    mov     dl, 0Dh
    int     21h
    mov     dl, 0Ah
    int     21h
    ; Restore 0 terminator
    pop     di
    mov     byte ptr [di], 0

    ;---------------------------------------------------------------------
    ; 7) Set DTA => AH=1Ah
    ;---------------------------------------------------------------------
    mov     dx, offset dta
    mov     ah, 1Ah
    int     21h

    ;---------------------------------------------------------------------
    ; 8) Find First => AH=4Eh
    ;    IMPORTANT: set CX=0x10 to see directories *and* normal files
    ;---------------------------------------------------------------------
    mov     dx, offset argV  ; DS:DX => path
    mov     cx, 0010h         ; bit 4 => include directories (and normal files)
    mov     ah, 4Eh
    int     21h
    jc      no_files         ; if CF=1 => no files/dirs found

print_loop:
    ;---------------------------------------------------------------------
    ; 9) Print the 8.3 name from the DTA. In DOS 3.x+, offset 1Eh => 11 bytes
    ;---------------------------------------------------------------------
    mov     si, offset dta
    add     si, 1Eh          ; point to filename in DTA
    mov     cx, 11

print_file:
    lodsb                   ; AL=[DS:SI]
    cmp     al, ' '
    je      skip_char
    mov     dl, al
    mov     ah, 02h
    int     21h
skip_char:
    loop    print_file

    ;---------------------------------------------------------------------
    ; 9a) Check if this is a directory. DTA offset 15h => file attribute
    ;     bit 4 set => directory
    ;---------------------------------------------------------------------
    mov     al, [dta+15h]
    test    al, 10h         ; is bit 4 set?
    jz      not_dir
    ; If directory, print " <DIR>"
    mov     si, offset msgDir
print_dir:
    lodsb
    cmp     al, 0
    je      done_print_dir
    mov     dl, al
    mov     ah, 02h
    int     21h
    jmp     print_dir
done_print_dir:

not_dir:
    ; Print CR/LF
    mov     dl, 0Dh
    mov     ah, 02h
    int     21h
    mov     dl, 0Ah
    mov     ah, 02h
    int     21h

    ;---------------------------------------------------------------------
    ; 10) Find Next => AH=4Fh
    ;---------------------------------------------------------------------
    mov     ah, 4Fh
    int     21h
    jnc     print_loop      ; if no error => got another => loop

    jmp     done_listing

no_files:
    mov     dx, offset msgNoFiles
    mov     ah, 09h
    int     21h

done_listing:
    mov     dx, offset msgDone
    mov     ah, 09h
    int     21h

    ;---------------------------------------------------------------------
    ; 11) Exit to DOS
    ;---------------------------------------------------------------------
    mov     ax, 4C00h
    int     21h

end start