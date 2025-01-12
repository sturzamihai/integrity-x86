.MODEL SMALL
.STACK 100h

.DATA
    ; Hardcoded input string
    input db "Hello, World!", 0
    input_len dw $ - offset input - 1 ; Length of the input string (excluding null terminator)

    ; MD5 Context structure (aligned for TASM compatibility)
    ctx_total dw 0, 0        ; Placeholder for ctx.total[2]
    ctx_state dw 4 DUP (0)   ; Placeholder for ctx.state[4]
    ctx_buffer db 64 DUP (0) ; Placeholder for ctx.buffer[64]

    ; MD5 Digest (16 bytes)
    digest db 16 DUP(?)

    ; Hexadecimal representation of the MD5 digest
    hex_output db 32 DUP(?) ; 32 characters for 16 bytes in hexadecimal
    newline db 0Dh, 0Ah, '$' ; Newline for DOS output

    hex_table db '0123456789ABCDEF' ; Table for converting bytes to hex

.CODE
    EXTRN _md5_starts: NEAR
    EXTRN _md5_update: NEAR
    EXTRN _md5_finish: NEAR

START:
    ; Initialize the MD5 context
    lea ax, ctx_total
    push ax
    call _md5_starts
    add sp, 2 ; Adjust stack for one parameter

    ; Update the MD5 context with the input data
    lea ax, ctx_total
    push ax
    lea ax, input
    push ax
    mov cx, input_len
    push cx
    call _md5_update
    add sp, 6 ; Adjust stack for three parameters

    ; Finalize the MD5 and store the result in 'digest'
    lea ax, ctx_total
    push ax
    lea ax, digest
    push ax
    call _md5_finish
    add sp, 4 ; Adjust stack for two parameters

    ; Convert the binary digest to a hexadecimal string
    mov si, offset digest    ; Source: digest
    mov di, offset hex_output ; Destination: hex_output
    mov cx, 16               ; 16 bytes to process

ConvertToHex:
    lodsb                     ; Load next byte from digest into AL
    mov ah, al                ; Copy AL to AH for high nibble
    mov cl, 4                 ; Load the shift count into CL
    shr al, cl                ; Perform the shift using the value in CL
    and al, 0Fh               ; Mask out high bits
    mov bx, offset hex_table
    add al, [bx]              ; Convert high nibble to ASCII
    stosb                     ; Store result in hex_output

    mov al, ah                ; Restore original byte
    and al, 0Fh               ; Mask out low bits
    add al, [bx]              ; Convert low nibble to ASCII
    stosb                     ; Store result in hex_output

    loop ConvertToHex

    ; Null-terminate the hex_output string
    mov byte ptr [di], 0

    ; Output the hexadecimal MD5 hash
    mov dx, offset hex_output
    mov ah, 09h
    int 21h

    ; Output a newline
    mov dx, offset newline
    mov ah, 09h
    int 21h

    ; Exit program
    mov ax, 4C00h
    int 21h

END START
