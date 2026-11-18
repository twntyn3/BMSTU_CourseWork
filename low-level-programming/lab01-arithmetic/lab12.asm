.model small
.stack 100h 

.data
    a   dw 3
    b   dw 8
    c   dw 4
    d   dw 6
    res dw ?
    rem dw ?
.code
start:
    mov ax, @data
    mov ds, ax
    ;delenie b/c
    mov ax, b
    mov dx, 0
    div c ; idiv если отр числа     див делит дх ах на указанный с 32 бит на 16 -_-
    mov rem, dx

    add ax, a
    
    mul d
    
    sub ax, 4

    
    mov res, ax
    
    
    mov ax, 4C00h
    ;mov al, 0
    int 21h
end start
    

