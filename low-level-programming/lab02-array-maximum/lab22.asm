.model small
.stack 100h
.data
    ; массив и данные
    arr dw 1, 2, 3, 4, 5, 6, 8, 7, 9, 2
    n   db ($ - arr) / 2 

    max_i db 0
    max_v dw 0

    msg0 db 0Dh, 0Ah, 'max element index: $'
    msg1 db 0Dh, 0Ah, 'max element value: $'


    decbuf_rev db 6 dup(?)
    decbuf     db 6 dup(?)
    space      db ' $'

.code
start:
    mov ax, @data
    mov ds, ax

    mov si, 0
    mov ax, word ptr arr
    mov max_v, ax
    mov max_i, 0

    ; посик максимума
    mov si, 0
    mov cl, n
    mov ch, 0
    mov ax, word ptr arr
    mov max_v, ax
    mov max_i, 0

search_loop:
    mov ax, word ptr arr[si]
    cmp ax, max_v
    jle not_max

    mov max_v, ax
    mov ax, si
    shr ax, 1
    mov max_i, al

not_max:
    inc si
    inc si
    loop search_loop

    ; вывод результата
    mov dx, offset msg0
    mov ah, 09h
    int 21h

    mov al, max_i
    mov ah, 0
    call print_number

    mov dx, offset msg1
    mov ah, 09h
    int 21h

    mov ax, max_v
    call print_number

    mov ah, 4Ch
    int 21h


; Процедура: print_number (для вывода чиселок)

print_number proc
    push ax
    push bx
    push dx
    push si
    push di

    mov si, 0
    cmp ax, 0
    jne convert_loop_enter
    mov byte ptr decbuf_rev[si], '0'
    inc si
    jmp convert_done

convert_loop_enter:
convert_loop:
    xor dx, dx
    mov bx, 10
    div bx
    add dl, '0'
    mov decbuf_rev[si], dl
    inc si
    cmp ax, 0
    jne convert_loop

convert_done:
    dec si
    mov di, 0

copy_loop:
    mov al, decbuf_rev[si]
    mov decbuf[di], al
    inc di
    dec si
    jns copy_loop

    mov byte ptr decbuf[di], '$'
    mov dx, offset decbuf
    mov ah, 09h
    int 21h

    mov dx, offset space
    mov ah, 09h
    int 21h

    pop di
    pop si
    pop dx
    pop bx
    pop ax

    ret

print_number endp

end start
