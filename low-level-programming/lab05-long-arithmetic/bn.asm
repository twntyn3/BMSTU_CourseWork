; bignumb.asm — большие числа: знаковое сложение и умножение (DEC/HEX)


.MODEL  small
.STACK  100h

.DATA
MaxDigits   db 64
Base        db 10
OpChar      db ?

MsgHello    db 13,10,'[BigInt] DEC/HEX, signed + and *',13,10,'$'
MsgAskBase  db 13,10,'Choose base: (D)ecimal or (H)exadecimal? $'
MsgBadBase  db 13,10,'ERROR: press D or H.$'
MsgAskOp    db 13,10,'Choose operation: + or *: $'
MsgBadOp    db 13,10,'ERROR: press + or *.$'
MsgAskA     db 13,10,'Enter first integer: $'
MsgAskB     db 13,10,'Enter second integer: $'
MsgBadChar  db 13,10,'ERROR: invalid character for chosen base.$'
MsgTooLong  db 13,10,'ERROR: too many digits (MaxDigits limit).$'
MsgEmpty    db 13,10,'ERROR: empty number.$'
MsgResult   db 13,10,'Result: $'
CRLF        db 13,10,'$'

INBUF_MAX   EQU 130
InBuf1      db INBUF_MAX,0,INBUF_MAX dup (0)
InBuf2      db INBUF_MAX,0,INBUF_MAX dup (0)

A_digits    db 128 dup(0)
B_digits    db 128 dup(0)
R_digits    db 256 dup(0)

lenA        dw 0
lenB        dw 0
lenR        dw 0

signA       db 0
signB       db 0
signR       db 0

OutBuf      db 320 dup(0)

.CODE

PrintStr PROC NEAR
    mov ah,09h
    int 21h
    ret
PrintStr ENDP

PrintCRLF PROC NEAR
    lea dx, CRLF
    call PrintStr
    ret
PrintCRLF ENDP

; ES:DI, CX bytes -> 0
ClearBuf PROC NEAR
    push ax
    push di
    mov al,0
CB_L:   or  cx,cx
        jz  CB_D
        stosb
        dec cx
        jmp CB_L
CB_D:   pop di
        pop ax
    ret
ClearBuf ENDP

;парсер строки

ParseLine PROC NEAR
    push ax bx cx dx si di bp

    mov cl, [si+1]
    mov ch, 0
    or  cx,cx
    jnz PL_NotEmpty
    lea dx, MsgEmpty
    call PrintStr
    stc
    jmp PL_Exit

PL_NotEmpty:
    lea si, [si+2]
    mov al,[si]
    mov dl,0
    cmp al,'-'
    jne PL_CheckPlus
    inc si
    dec cx
    mov dl,1
    jmp PL_AfterSign
PL_CheckPlus:
    cmp al,'+'
    jne PL_AfterSign
    inc si
    dec cx
PL_AfterSign:
    or  cx,cx
    jnz PL_LenOk
    lea dx, MsgEmpty
    call PrintStr
    stc
    jmp PL_Exit

PL_LenOk:
    mov al,[MaxDigits]
    cbw
    cmp cx, ax
    jbe PL_Convert
    lea dx, MsgTooLong
    call PrintStr
    stc
    jmp PL_Exit

PL_Convert:
    mov byte ptr ds:[bp], dl
    mov word ptr [bx], 0  ; len=0

    push cx
    push es
    mov ax,@data
    mov es,ax
    push di
    xor cx,cx
    mov cl,[MaxDigits]
    call ClearBuf
    pop di
    pop es
    pop cx

    ; DX -> последний символ исходной строки
    mov ax, si
    add ax, cx
    dec ax
    mov dx, ax

    push di
    pop  bp

PL_DLoop:
    mov si, dx
    mov al, [si]

    ; символ -> цифра
    cmp al,'0'
    jb  PL_Bad
    cmp al,'9'
    jbe PL_IsDec
    cmp al,'A'
    jb  PL_Lower
    cmp al,'F'
    jbe PL_HexU
PL_Lower:
    cmp al,'a'
    jb  PL_Bad
    cmp al,'f'
    jbe PL_HexL
    jmp PL_Bad

PL_IsDec:
    sub al,'0'
    jmp PL_Store

PL_HexU:
    sub al,'A'
    add al,10
    cmp byte ptr [Base],16
    jne PL_Bad
    jmp PL_Store

PL_HexL:
    sub al,'a'
    add al,10
    cmp byte ptr [Base],16
    jne PL_Bad

PL_Store:
    cmp al, [Base]
    jae PL_Bad

    mov si, [bx]             ; len
    add si, bp               ; dest + len
    mov [si], al
    inc word ptr [bx]        ; len++

    cmp cx,1
    je  PL_Done
    dec dx
    dec cx
    jmp PL_DLoop

PL_Done:
    clc
    jmp PL_Exit

PL_Bad:
    lea dx, MsgBadChar
    call PrintStr
    stc

PL_Exit:
    pop bp di si dx cx bx ax
    ret
ParseLine ENDP

; сравнение модулей 

CmpAbs PROC NEAR
    push si bx dx

    mov ax, lenA
    mov bx, lenB

CA_TA:  cmp ax,0
        je  CA_TA_D
        mov si, ax
        dec si
        mov dl, [A_digits+si]
        or  dl,dl
        jnz CA_TA_D
        dec ax
        jmp CA_TA
CA_TA_D:

CA_TB:  cmp bx,0
        je  CA_TB_D
        mov si, bx
        dec si
        mov dl, [B_digits+si]
        or  dl,dl
        jnz CA_TB_D
        dec bx
        jmp CA_TB
CA_TB_D:

    cmp ax,bx
    ja  CA_AGT
    jb  CA_BGT

    mov dx, ax
    or  dx,dx
    jz  CA_EQ
    dec dx
CA_UL:  mov si, dx
        mov al, [A_digits+si]
        mov ah, [B_digits+si]
        cmp al, ah
        ja  CA_AGT
        jb  CA_BGT
        or  dx,dx
        jz  CA_EQ
        dec dx
        jmp CA_UL

CA_EQ:  xor ax,ax
        jmp CA_OUT
CA_AGT: mov ax,1
        jmp CA_OUT
CA_BGT: mov ax,0FFFFh
CA_OUT: pop dx bx si
    ret
CmpAbs ENDP

; сложение модулей
AddAbs PROC NEAR
    push ax bx cx dx si

    mov ax, lenA
    mov bx, lenB
    cmp ax, bx
    ja  AA_MaxA
    mov cx, bx
    jmp AA_MaxOk
AA_MaxA:
    mov cx, ax
AA_MaxOk:
    xor si, si
    xor dl, dl
    mov bl, [Base]

AA_L:   cmp si, cx
        jae AA_Aft
        mov al,0
        mov ah,0
        cmp si, lenA
        jae AA_NoA
        mov al, [A_digits+si]
AA_NoA: cmp si, lenB
        jae AA_NoB
        mov ah, [B_digits+si]
AA_NoB: add al, ah
        add al, dl
        cmp al, bl
        jb  AA_NoC
        sub al, bl
        mov dl,1
        jmp AA_St
AA_NoC: mov dl,0
AA_St:  mov [R_digits+si], al
        inc si
        jmp AA_L

AA_Aft: or  dl,dl
        jz  AA_Set
        mov [R_digits+si], dl
        inc si
AA_Set: mov lenR, si

    pop si dx cx bx ax
    ret
AddAbs ENDP

; вычитание модулей 

SubAbs PROC NEAR
    push ax bx dx si

    xor si, si
    mov bl, [Base]
    xor dl, dl

SA_L:
    cmp si, lenA
    jae SA_D

    ; AL = A[i], AH = B[i] (или 0)
    mov al, 0
    cmp si, lenA
    jae SA_NoA
    mov al, [A_digits+si]
SA_NoA:
    mov ah, 0
    cmp si, lenB
    jae SA_NoB
    mov ah, [B_digits+si]
SA_NoB:

    or  dl, dl
    jz  SA_ClrCF
    stc
    jmp SA_DoSBB
SA_ClrCF:
    clc
SA_DoSBB:

    sbb al, ah
    jnc SA_NoBorrow


    add al, bl
    mov dl, 1
    jmp SA_Store

SA_NoBorrow:
    xor dl, dl

SA_Store:
    mov [R_digits+si], al
    inc si
    jmp SA_L


SA_D:
    mov ax, si
    or  ax, ax
    jnz SA_T1
    mov ax, 1
    mov byte ptr [R_digits], 0
    jmp SA_Set
SA_T1:  dec ax
SA_T:   mov si, ax
        mov dl, [R_digits+si]
        or  dl, dl
        jnz SA_SetLen
        or  ax, ax
        jz  SA_One
        dec ax
        jmp SA_T
SA_One: mov ax, 1
        mov byte ptr [R_digits], 0
        jmp SA_Set
SA_SetLen:
        inc ax
SA_Set: mov lenR, ax

    pop si dx bx ax
    ret
SubAbs ENDP



; умножение модулей 
MulAbs PROC NEAR
    push ax bx cx dx si di


    mov ax, @data
    mov es, ax
    lea di, R_digits
    mov ax, lenA
    add ax, lenB
    inc ax
    mov cx, ax
    xor al, al
    rep stosb

    mov cl, [Base]
    xor si, si             ; i = 0

NextDigitA:
    cmp si, lenA
    jae DoneMul

    xor di, di             ; j = 0
    xor dl, dl             ; перенос = 0

LoopB:
    cmp di, lenB
    jae AfterInnerLoop

    mov bh, [A_digits+si]

    mov al, [B_digits+di]  ; AL = B[j]
    mul bh                 ; AX = AL * BH

    mov bx, si
    add bx, di             ; pos = i + j

    ; + R[pos]
    add al, byte ptr [R_digits+bx]
    adc ah, 0

    ; + перенос
    add al, dl
    adc ah, 0


    div cl               
    mov byte ptr [R_digits+bx], ah
    mov dl, al

    inc di
    jmp LoopB

AfterInnerLoop:

    mov bx, si
    add bx, lenB
    or  dl, dl
    jz  SkipCarry

CarryPropagate:
    mov al, byte ptr [R_digits+bx]
    add al, dl
    mov ah, 0
    adc ah, 0
    div cl 
    mov byte ptr [R_digits+bx], ah
    mov dl, al
    inc bx
    or  dl, dl
    jnz CarryPropagate

SkipCarry:
    inc si
    jmp NextDigitA

DoneMul:
    ; вычислить lenR
    mov ax, lenA
    add ax, lenB
    dec ax
    mov si, ax
FindLen:
    cmp si, 0
    jl  SetLen1
    cmp byte ptr [R_digits+si], 0
    jne SetLen
    dec si
    jmp FindLen
SetLen:
    inc si
    mov lenR, si
    jmp EndMul
SetLen1:
    mov lenR, 1
    mov byte ptr [R_digits], 0
EndMul:
    pop di si dx cx bx ax
    ret
MulAbs ENDP


;печать результата
PrintResult PROC NEAR
    push ax bx cx dx si di
    lea di, OutBuf


    mov al, [signR]
    or  al,al
    jz  PR_NoMinus
    mov ax, lenR
    cmp ax,1
    jne PR_PutMinus
    cmp byte ptr [R_digits],0
    je  PR_NoMinus
PR_PutMinus:
    mov byte ptr [di], '-'
    inc di
PR_NoMinus:

    mov cx, lenR
    or  cx,cx
    jnz PR_Have
    mov byte ptr [di], '0'
    inc di
    jmp PR_End
PR_Have:
    dec cx
PR_Skip:
    mov si, cx
    mov al, [R_digits+si]
    or  al,al
    jnz PR_Start
    or  cx,cx
    jz  PR_Start
    dec cx
    jmp PR_Skip

PR_Start:
    mov bl, [Base]
PR_L:
    mov si, cx
    mov al, [R_digits+si]
    cmp bl,16
    jne PR_D
    cmp al,9
    jbe PR_P0
    add al, 'A'-10
    jmp PR_S
PR_P0:
    add al, '0'
    jmp PR_S
PR_D:
    add al, '0'
PR_S:
    mov [di], al
    inc di
    or  cx,cx
    jz  PR_End
    dec cx
    jmp PR_L

PR_End:
    mov byte ptr [di], '$'
    lea dx, MsgResult
    call PrintStr
    lea dx, OutBuf
    call PrintStr
    call PrintCRLF

    pop di si dx cx bx ax
    ret
PrintResult ENDP

;main
main PROC
    mov ax, @data
    mov ds, ax

    lea dx, MsgHello
    call PrintStr

    ; выбор базы
    lea dx, MsgAskBase
    call PrintStr
    mov ah,01h
    int 21h
    call PrintCRLF
    cmp al,'d'
    jne MB_NotDlow
    mov [Base], byte ptr 10
    jmp AskOp
MB_NotDlow:
    cmp al,'D'
    jne MB_NotD
    mov [Base], byte ptr 10
    jmp AskOp
MB_NotD:
    cmp al,'h'
    jne MB_NotHlow
    mov [Base], byte ptr 16
    jmp AskOp
MB_NotHlow:
    cmp al,'H'
    jne MB_Bad
    mov [Base], byte ptr 16
    jmp AskOp
MB_Bad:
    lea dx, MsgBadBase
    call PrintStr
    jmp ExitDOS

AskOp:
    lea dx, MsgAskOp
    call PrintStr
    mov ah,01h
    int 21h
    call PrintCRLF
    mov [OpChar], al
    cmp al,'+'
    je  AfterOpOk
    cmp al,'*'
    je  AfterOpOk
    lea dx, MsgBadOp
    call PrintStr
    jmp ExitDOS
AfterOpOk:


    lea dx, MsgAskA
    call PrintStr
    lea dx, InBuf1
    mov ah,0Ah
    int 21h
    lea si, InBuf1
    lea di, A_digits
    lea bx, lenA
    lea bp, signA
    call ParseLine
    jnc  InputA_OK
    jmp  ExitDOS
InputA_OK:


    lea dx, MsgAskB
    call PrintStr
    lea dx, InBuf2
    mov ah,0Ah
    int 21h
    lea si, InBuf2
    lea di, B_digits
    lea bx, lenB
    lea bp, signB
    call ParseLine
    jnc  InputB_OK
    jmp  ExitDOS
InputB_OK:

    ; выбор операции
    mov al, [OpChar]
    cmp al,'+'
    je  DoAdd
    jmp DoMul

DoAdd:
    mov al, [signA]
    mov ah, [signB]
    cmp al, ah
    jne AddDiff

    call AddAbs
    mov al, [signA]
    mov [signR], al
    jmp PrintAndExit

AddDiff:
    call CmpAbs
    or  ax,ax
    jnz NotZero
    mov lenR, 1
    mov byte ptr [R_digits], 0
    mov [signR], byte ptr 0
    jmp PrintAndExit
NotZero:
    cmp ax,1
    jne NotAgtB
    call SubAbs               ; |A|>|B|
    mov al, [signA]
    mov [signR], al
    jmp PrintAndExit
NotAgtB:
    mov ax, lenA
    xchg ax, lenB
    mov lenA, ax
    xor si, si
    mov cl, [MaxDigits]
    mov ch, 0
AD_S1:
    cmp si, cx
    jae AD_Swapped
    mov al, [A_digits+si]
    mov ah, [B_digits+si]
    mov [A_digits+si], ah
    mov [B_digits+si], al
    inc si
    jmp AD_S1
AD_Swapped:
    call SubAbs
    ; вернуть
    xor si, si
    mov cl, [MaxDigits]
    mov ch, 0
AD_SB1:
    cmp si, cx
    jae AD_SetSB
    mov al, [A_digits+si]
    mov ah, [B_digits+si]
    mov [A_digits+si], ah
    mov [B_digits+si], al
    inc si
    jmp AD_SB1
AD_SetSB:
    mov ax, lenA
    xchg ax, lenB
    mov lenA, ax
    mov al, [signB]
    mov [signR], al
    jmp PrintAndExit

; умножение 
DoMul:
    call MulAbs

    mov al, [signA]
    xor al, [signB]
    mov bx, lenR
    cmp bx,1
    jne MulSetSign
    cmp byte ptr [R_digits],0
    jne MulSetSign
    mov al,0
MulSetSign:
    mov [signR], al

PrintAndExit:
    call PrintResult

ExitDOS:
    mov ax,4C00h
    int 21h
main ENDP

END main
