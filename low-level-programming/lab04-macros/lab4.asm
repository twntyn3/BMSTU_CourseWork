.model  small
.stack  100h


VOL_ARG MACRO par
    IFNB <par>

        ; запрет регистров
        IF (.TYPE par) AND 10h
            .ERR <VOLUME: register not allowed as argument>

        ELSE
            IFDEF par

                IF (.TYPE par) AND 2
                    mov bx, SIZE par
                    add ax, bx
                ELSEIF (.TYPE par) AND 4

                ELSE
                    .ERR <VOLUME: symbol must be data variable/array or constant>
                ENDIF

            ELSE
                IF (.TYPE par) AND 4
                ; не определённый идентификатор / неверный аргумент
                ELSE
                    .ERR <VOLUME: undefined symbol or invalid argument>
                ENDIF

            ENDIF

        ENDIF

    ENDIF
ENDM


; макрос VOLUME p1-p7

VOLUME  MACRO p1, p2, p3, p4, p5, p6, p7

    pushf
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    xor ax, ax  ; AX = total bytes = 0

    VOL_ARG p1
    VOL_ARG p2
    VOL_ARG p3
    VOL_ARG p4
    VOL_ARG p5
    VOL_ARG p6
    VOL_ARG p7

    call PrintWord

    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    popf

ENDM


.data
; A, B - 64-bit variables
A       db  8 dup (?)   ; 8 bytes
B       dw  4 dup (?)   ; 4 words = 8 bytes
C       db  ?
D       dw  ?

Msg     db  'total volume (bytes): ', '$'


.code

PrintWord PROC NEAR
    push bx
    push cx
    push dx

    cmp ax, 0
    jne pw_not_zero

    mov dl, '0'
    mov ah, 2
    int 21h
    jmp pw_newline

pw_not_zero:
    mov bx, 10
    xor cx, cx

pw_div_loop:
    xor dx, dx
    div bx
    push dx
    inc  cx
    cmp ax, 0
    jne pw_div_loop

pw_print_loop:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop pw_print_loop

pw_newline:
    mov dl, 13
    mov ah, 2
    int 21h
    mov dl, 10
    mov ah, 2
    int 21h

    pop dx
    pop cx
    pop bx
    ret
PrintWord ENDP

main PROC
    mov ax, @data
    mov ds, ax

    mov dx, OFFSET Msg
    mov ah, 9
    int 21h

    ; A = 8 by, B = 8 by, C = 1 by, D = 2 by
    ; total = 8 + 8 + 1 + 2 = 19 bytes
    VOLUME A, B, C, D

    mov ax, 4C00h
    int 21h
main ENDP

END main


