.model small
.stack 100h 

.data
    a           dw 3
    b           dw 8
    c           dw 4
    d           dw 6
    res         dw ?
    rem         dw ?

    decbuf      db 6 dup (?), '$'
    decbuf_rev  db 6 dup (?), '$'

    hexbuf      db 6 dup (?), '$'
    hexbuf_rev  db 6 dup (?), '$'

    space db ' $'

.code
start:
    mov     ax, @data
    mov     ds, ax

    mov     ax, b
    mov     dx, 0
    div     c
    mov     rem, dx

    add     ax, a
    mul     d
    sub     ax, 4
    mov     res, ax

    ;decyati4naya

    mov     ax, res
    mov     si, 0 
    cmp     ax, 0
    jne     convert_loop_enter
    mov     byte ptr decbuf_rev[si], '0'
    inc     si
    jmp     convert_done

convert_loop_enter:
convert_loop:
    xor     dx, dx
    mov     bx, 10
    div     bx
    add     dl, '0'
    mov     decbuf_rev[si], dl
    inc     si
    cmp     ax, 0
    jne     convert_loop

convert_done:
    dec     si
    mov     di, 0

copy_loop:
    mov     al, decbuf_rev[si]
    mov     decbuf[di], al
    inc     di
    dec     si
    jns     copy_loop

    mov     byte ptr decbuf[di], '$'
    mov     dx, offset decbuf
    mov     ah, 09h
    int     21h

    mov     dx, offset space
    mov     ah, 09h
    int     21h
    

    ;16 v 4elom analogi4no 10-ti4noi

    mov     ax, res
    mov     si, 0
    cmp     ax, 0
    jne     hex_loop_enter
    mov     byte ptr hexbuf_rev[si], '0'
    inc     si
    jmp     hex_done

hex_loop_enter:
hex_loop:
    xor     dx, dx
    mov     bx, 16
    div     bx
    cmp     dl, 9
    jbe     hex_digit
    add     dl, 55          ; 10 15 v  A F
    jmp     short hex_store
hex_digit:
    add     dl, '0'         ; 0 9 v 0 9
hex_store:
    mov     hexbuf_rev[si], dl
    inc     si
    cmp     ax, 0
    jne     hex_loop

hex_done:
    dec     si
    mov     di, 0
hex_copy:
    mov     al, hexbuf_rev[si]
    mov     hexbuf[di], al
    inc     di
    dec     si
    jns     hex_copy

    mov     byte ptr hexbuf[di], '$'
    mov     dx, offset hexbuf
    mov     ah, 09h
    int     21h

    ; konec

    mov     ax, 4C00h
    int     21h

end start
