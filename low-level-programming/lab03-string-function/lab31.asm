assume cs:code, ds:data, ss:stack

stack segment para stack 'STACK'
    db 512 dup(?)
stack ends

data segment
    inbuf  db 100,0,100 dup(0)
    nbuf   db 5,0,5 dup(0)
    src    db 256 dup(0)
    dest   db 256 dup(0)
    nval   dw 0
    msgIn  db 'Vvedite stroku, zatem 4islo:',0Dh,0Ah,'$'
    nl     db 0Dh,0Ah,'$'
data ends

code segment

; char *strncpy(char *dest, const char *src, size_t n)
strncpy proc
    push bp
    mov  bp, sp
    push di
    push si

    mov  di, [bp+4]
    mov  si, [bp+6]
    mov  cx, [bp+8]

copy_loop:
    or   cx, cx
    jz   pad_done
    lodsb
    stosb
    dec  cx
    or   al, al
    jnz  copy_loop

pad_loop:
    jcxz pad_done
    xor  al, al
    stosb
    loop pad_loop

pad_done:
    pop  si
    pop  di
    pop  bp
    ret 6
strncpy endp


start:
    mov  ax, data
    mov  ds, ax
    cld
    push ds
    pop  es

    mov  dx, offset msgIn
    mov  ah, 09h
    int  21h

    mov  dx, offset inbuf
    mov  ah, 0Ah
    int  21h

    mov  dx, offset nl
    mov  ah, 09h
    int  21h

    mov  si, offset inbuf
    mov  cl, [si+1]
    xor  ch, ch
    add  si, 2
    mov  di, offset src
    rep  movsb
    mov  byte ptr [di], 0

    mov  dx, offset nbuf
    mov  ah, 0Ah
    int  21h

    mov  si, offset nbuf
    mov  cl, [si+1]
    xor  ch, ch
    add  si, 2
    xor  ax, ax
parse_n:
    or   cx, cx
    jz   parsed
    mov  bl, [si]
    inc  si
    dec  cx
    cmp  bl, '0'
    jb   parse_n
    cmp  bl, '9'
    ja   parse_n
    sub  bl, '0'
    mov  dx, ax
    mov  ax, 10
    mul  dx
    add  ax, bx
    jmp  parse_n
parsed:
    mov  nval, ax

    push nval
    push offset src
    push offset dest
    call strncpy

    mov  si, offset dest
    mov  cx, nval
find_zero:
    or   cx, cx
    jz   put_after
    cmp  byte ptr [si], 0
    je   put_here
    inc  si
    dec  cx
    jmp  find_zero
put_after:
    mov  byte ptr [si], '$'
    jmp  print
put_here:
    mov  byte ptr [si], '$'

print:
    mov  dx, offset dest
    mov  ah, 09h
    int  21h

    mov  ah, 4Ch
    xor  al, al
    int  21h
code ends
end start

