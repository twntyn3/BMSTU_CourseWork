bits 16
org 100h

%macro BYTE_VAR 2
    %ifdef %{1}_TYPE
        %error "Variable already defined"
    %endif
    %1: db %2
    %define %{1}_TYPE 1
%endmacro

%macro WORD_VAR 2
    %ifdef %{1}_TYPE
        %error "Variable already defined"
    %endif
    %1: dw %2
    %define %{1}_TYPE 2
%endmacro

; 2a: byte +1, word +2
%macro INCREASE 1-*
    pushf
    %rep %0
        %ifndef %{1}_TYPE
            %error "Unknown variable"
        %elif %{1}_TYPE = 1
            inc byte [%1]
        %elif %{1}_TYPE = 2
            add word [%1], 2
        %else
            %error "Wrong variable type"
        %endif
        %rotate 1
    %endrep
    popf
%endmacro

; 2b: only bytes become -1
%macro SET_MINUS_ONE 1-*
    %rep %0
        %ifndef %{1}_TYPE
            %error "Unknown variable"
        %elif %{1}_TYPE = 1
            mov byte [%1], -1
        %elif %{1}_TYPE != 2
            %error "Wrong variable type"
        %endif
        %rotate 1
    %endrep
%endmacro

; 2c: array of B (bytes) or W (words)
%macro DEF 3-4
    %if %3 < 1
        %error "Array length must be positive"
    %endif
    %ifdef %{1}_TYPE
        %error "Name already used"
    %elifidni %2, B
        %ifempty %4
            %1: resb %3
        %else
            %1: times %3 db %4
        %endif
        %define %{1}_TYPE 1
    %elifidni %2, W
        %ifempty %4
            %1: resw %3
        %else
            %1: times %3 dw %4
        %endif
        %define %{1}_TYPE 2
    %else
        %error "Type must be B or W"
    %endif
%endmacro

section .data
    BYTE_VAR A, 1
    WORD_VAR B, 10
    BYTE_VAR C, 2
    WORD_VAR D, 20
    BYTE_VAR E, 3
    WORD_VAR F, 30

    DEF X, B, 4, 7
    DEF Y, W, 3, -2

    okA db '2a: OK', 13, 10, '$'
    noA db '2a: FAIL', 13, 10, '$'
    okB db '2b: OK', 13, 10, '$'
    noB db '2b: FAIL', 13, 10, '$'
    okC db '2c: OK', 13, 10, '$'
    noC db '2c: FAIL', 13, 10, '$'

section .bss
    DEF Z, B, 4
Z_end:

section .text
start:
    push cs
    pop ds

    INCREASE A, B, C, D, E, F

    mov dx, okA
    cmp byte [A], 2
    jne .failA
    cmp word [B], 12
    jne .failA
    cmp byte [C], 3
    jne .failA
    cmp word [D], 22
    jne .failA
    cmp byte [E], 4
    jne .failA
    cmp word [F], 32
    je .showA
.failA:
    mov dx, noA
.showA:
    mov ah, 09h
    int 21h

    SET_MINUS_ONE A, B, C, D, E, F

    mov dx, okB
    cmp byte [A], -1
    jne .failB
    cmp word [B], 12
    jne .failB
    cmp byte [C], -1
    jne .failB
    cmp word [D], 22
    jne .failB
    cmp byte [E], -1
    jne .failB
    cmp word [F], 32
    je .showB
.failB:
    mov dx, noB
.showB:
    mov ah, 09h
    int 21h

    mov dx, okC
    cmp byte [X], 7
    jne .failC
    cmp byte [X+3], 7
    jne .failC
    cmp word [Y], -2
    jne .failC
    cmp word [Y+4], -2
    jne .failC
    mov ax, Z_end - Z
    cmp ax, 4
    je .showC
.failC:
    mov dx, noC
.showC:
    mov ah, 09h
    int 21h

    mov ax, 4C00h
    int 21h

