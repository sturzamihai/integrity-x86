;Create a file
;[in]
;FILENAME: The name of the file
;ATTRIB: ReadOnly, Hidden, System, Normal
;[out]
;HANDLE: File identifier returned, or -1 on error

CreateFile MACRO Filename,Attrib,Handle,Result
    LOCAL NOK,Exit
    push ax
    push cx
    push dx
    push ds

    mov ah,3Ch
    mov cx,Attrib
    lea dx,Filename ; <=> mov DX, offset Filename
    int 21h
    jc NOK
    mov HANDLE,ax
    mov Result,0
    jmp Exit
NOK:
    mov Handle,-1
    mov Result,ax
Exit:
    pop ds
    pop dx
    pop cx
    pop ax
ENDM

;Open a file
;[in]
;FILENAME: The name of the file
;ACCESS: 0 for read, 1 for write, 2 for read-write
;[out]
;HANDLE: File identifier returned, or -1 on error

OpenFile MACRO Filename,Access,Handle,Result
    LOCAL NOK,Exit
    push ax
    push dx
    push ds

    mov ah,3Dh
    mov al,Access
    lea dx,Filename
    int 21h
    jc NOK
    mov Handle,ax
    mov Result,0
    jmp Exit
NOK:
    mov Handle,-1
    mov Result,ax
Exit:
    pop ds
    pop dx
    pop ax
ENDM

;Write to a file
;[in]
;HANDLE: File identifier
;BUFFER: Data to write
;BYTES_TO_WRITE: Number of bytes to write
;[out]
;BYTES_WRITTEN: Number of bytes written

WriteToFile MACRO Handle,Buffer,BytesToWrite,BytesWritten,Result
    LOCAL NOK,Exit
    push ax
    push bx
    push cx
    push dx

    mov ah,40h
    mov bx,Handle
    lea dx,Buffer
    mov cx,BytesToWrite
    int 21h
    jc NOK
    mov BytesWritten,ax
    mov Result,0
    jmp Exit
NOK:
    ;Error code in ax!
    mov Result,ax
Exit:
    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;Read from a file
;[in]
;HANDLE: File identifier
;BUFFER: Destination for data
;BYTES_TO_READ: Number of bytes to read
;[out]
;BYTES_READ: Number of bytes read

ReadFromFile MACRO Handle,Buffer,BytesToRead,BytesRead,Result
    LOCAL NOK,Exit
    push ax
    push bx
    push cx
    push dx

    mov ah,3Fh
    mov bx,Handle
    lea dx,Buffer
    mov cx,BytesToRead
    int 21h
    jc NOK
    mov BytesRead,ax
    mov Result,0
    jmp Exit
NOK:
    ;Error code in ax!
    mov Result,ax
Exit:
    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;Close a file
;[in]
;HANDLE: File identifier

CloseFile MACRO Handle,Result
    LOCAL NOK,Exit
    push ax
    push bx

    mov ah,3Eh
    mov bx,HANDLE
    int 21h
    jc NOK
    mov Result,0
    jmp Exit
NOK:
    mov Result,ax
Exit:
    pop bx
    pop ax
ENDM

;Delete a file
;[in]
;Filename: The name of the file
;[out]
;Result: Operation result (0=success, !=0 error code)

DeleteFile MACRO Filename,Result
    LOCAL NOK,Exit
    push ax
    push dx
    push ds

    mov ah,41h
    lea dx,Filename
    int 21h
    jc NOK
    mov Result,0
    jmp Exit
NOK:
    mov Result,ax
Exit:
    pop ds
    pop dx
    pop ax
ENDM

;Move file pointer
;[in]
;HANDLE: File identifier
;POSITION: Desired position
;FROM: 0 start, 1 current, 2 end
;[out]
;CUR_POSITION: Current position
;Result: Operation result

MoveFilePointer MACRO Handle,Position,From,CurPosition,Result
    LOCAL NOK,Exit
    push ax
    push bx
    push cx
    push dx

    mov ah,42h
    mov al,From
    mov bx,Handle
    mov dx,word ptr Position[0]
    mov cx,word ptr Position[1]
    int 21h
    jc NOK
    mov word ptr CurPosition[0],ax
    mov word ptr CurPosition[1],dx
    mov Result,0
    jmp Exit
NOK:
    mov Result,ax
Exit:
    pop dx
    pop cx
    pop bx
    pop ax
ENDM

;Display a string to the console
;xstr: Offset of the string (DS segment is assumed)
puts MACRO xstr
    push ds
    push ax
    push dx
    mov dx, offset xstr ;lea dx,xstr
    mov ah,09h
    int 21h
    pop dx
    pop ax
    pop ds
ENDM

;Read a string from the console
gets MACRO xstr
    push ax
    push dx

    mov dx, offset xstr ;lea dx,xstr
    mov ah,0Ah
    int 21h

    pop dx
    pop ax
ENDM

;Exit to DOS
exit_dos MACRO
    mov ax,4C00h
    int 21h
ENDM
