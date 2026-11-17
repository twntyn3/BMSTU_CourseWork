.286
.model small
.stack 100h
.data
    max_len equ 30

    input_prompt db 'Vvedite dva chisla (dlia 16-richnykh ispolzuite h na kontse):',13,10,'$'
    num1_prompt db 'Pervoe chislo: $'
    num2_prompt db 'Vtoroe chislo: $'
    sum_result_prompt db 13,10,'Summa: $'
    mul_result_prompt db 13,10,'Proizvedenie: $'
    error_prompt db 13,10,'Oshibka: nedopustimye simvoly.$'
    error_base_mismatch db 13,10,'Oshibka: raznye sistemy schisleniya.$'
    newline db 13,10,'$'

    num1_str_buffer db max_len+3 dup (?)
    num2_str_buffer db max_len+3 dup (?)

    num1_str_ptr dw ?
    num2_str_ptr dw ?

    result_str db max_len*2+3 dup (?)

    num1_digits db max_len dup (0)
    num2_digits db max_len dup (0)
    result_digits db max_len*2+1 dup (0)

    num1_sign db 0
    num2_sign db 0
    result_sign db 0

    num1_len dw 0
    num2_len dw 0
    result_len dw 0

    is_hex db 0
    base db 10
    op_is_hex db 0
    op_base db 10

.code
main proc
    mov ax,@data
    mov ds,ax

    mov ah,9
    lea dx,input_prompt
    int 21h

    mov ah,9
    lea dx,num1_prompt
    int 21h
    lea dx,num1_str_buffer
    call read_string
    lea si,num1_str_buffer
    call parse_string
    jnc okp1
    call print_error_and_exit
okp1:
    mov num1_len,dx
    mov num1_sign,bl
    mov num1_str_ptr,si
    mov al,[is_hex]
    mov [op_is_hex],al
    mov al,[base]
    mov [op_base],al
    mov dx,num1_len
    mov si,num1_str_ptr
    lea di,num1_digits
    call convert_to_digits
    jnc okc1
    call print_error_and_exit
okc1:

    mov ah,9
    lea dx,num2_prompt
    int 21h
    lea dx,num2_str_buffer
    call read_string
    lea si,num2_str_buffer
    call parse_string
    jnc okp2
    call print_error_and_exit
okp2:
    mov num2_len,dx
    mov num2_sign,bl
    mov num2_str_ptr,si
    mov al,[base]
    cmp al,[op_base]
    je same_base
    call print_base_mismatch_and_exit
same_base:
    mov dx,num2_len
    mov si,num2_str_ptr
    lea di,num2_digits
    call convert_to_digits
    jnc okc2
    call print_error_and_exit
okc2:

    mov al,[op_is_hex]
    mov [is_hex],al
    mov al,[op_base]
    mov [base],al

    call signed_add
    mov ah,9
    lea dx,sum_result_prompt
    int 21h
    call clear_result_str
    lea si,result_digits
    mov cx,result_len
    lea di,result_str
    call convert_to_string
    lea dx,result_str
    int 21h

    call signed_multiply
    mov ah,9
    lea dx,mul_result_prompt
    int 21h
    call clear_result_str
    lea si,result_digits
    mov cx,result_len
    lea di,result_str
    call convert_to_string
    lea dx,result_str
    int 21h

    mov ax,4c00h
    int 21h
main endp

read_string proc
    push di
    mov di,dx
    mov byte ptr [di],max_len+2
    mov ah,0ah
    int 21h
    mov ah,9
    lea dx,newline
    int 21h
    pop di
    ret
read_string endp

parse_string proc
    push bx
    push di
    xor bl,bl
    mov byte ptr [is_hex],0
    mov byte ptr [base],10
    mov di,si
    inc di
    xor ch,ch
    mov cl,[di]
    mov dx,cx
    inc di
    mov si,di
    cmp dx,0
    je parse_fail
    cmp byte ptr [si],'-'
    jne check_hex
    mov bl,1
    inc si
    dec dx
    cmp dx,0
    je parse_fail
check_hex:
    cmp dx,0
    je no_hex_found
    mov di,si
    add di,dx
    dec di
    mov al,[di]
    cmp al,'h'
    je mark_hex
    cmp al,'H'
    jne no_hex_found
mark_hex:
    mov byte ptr [is_hex],1
    mov byte ptr [base],16
    dec dx
no_hex_found:
    cmp dx,0
    je parse_fail
    mov al,bl
    pop di
    pop bx
    mov bl,al
    clc
    ret
parse_fail:
    pop di
    pop bx
    stc
    ret
parse_string endp

convert_to_digits proc
    pusha
    mov cx,dx
    add si,dx
    dec si
ctd_loop:
    mov al,[si]
    cmp al,'0'
    jb ctd_bad
    cmp al,'9'
    jbe is_d
    cmp byte ptr [is_hex],1
    jne ctd_bad
    cmp al,'a'
    jb try_up
    cmp al,'f'
    jbe low_hex
try_up:
    cmp al,'A'
    jb ctd_bad
    cmp al,'F'
    ja ctd_bad
    sub al,'A'
    add al,10
    jmp store
low_hex:
    sub al,'a'
    add al,10
    jmp store
is_d:
    sub al,'0'
    cmp byte ptr [is_hex],1
    je store
    cmp al,10
    jae ctd_bad
store:
    mov [di],al
    inc di
    dec si
    loop ctd_loop
    clc
    jmp ctd_end
ctd_bad:
    stc
ctd_end:
    popa
    ret
convert_to_digits endp

convert_to_string proc
    pusha
    mov ax,result_len
    cmp ax,0
    jne cs_nonzero
    mov byte ptr [result_digits],0
    mov result_len,1
cs_nonzero:
    mov cx,result_len
    mov al,result_sign
    cmp al,1
    jne cs_no_minus
    mov byte ptr [di],'-'
    inc di
cs_no_minus:
    lea si,result_digits
    add si,cx
    dec si
cs_loop:
    mov al,[si]
    cmp byte ptr [is_hex],1
    je cs_hex
    add al,'0'
    jmp cs_put
cs_hex:
    cmp al,10
    jb cs_dec
    add al,'a'
    sub al,10
    jmp cs_put
cs_dec:
    add al,'0'
cs_put:
    mov [di],al
    inc di
    dec si
    loop cs_loop
    mov byte ptr [di],'$'
    popa
    ret
convert_to_string endp

; ==== РЕАЛИЗАЦИЯ СЛОЖЕНИЯ ИЗ bignumb.asm ====

signed_add proc
    call clear_result

    mov al,num1_sign
    mov ah,num2_sign
    cmp al,ah
    jne sa_diff

    call add_magnitudes
    mov result_sign,al
    ret

sa_diff:
    call compare_magnitudes
    or ax,ax
    jnz sa_not_zero

    mov result_len,1
    mov byte ptr [result_digits],0
    mov result_sign,0
    ret

sa_not_zero:
    cmp ax,1
    jne sa_notAgtB

    call subtract
    mov al,num1_sign
    mov result_sign,al
    ret

sa_notAgtB:
    mov ax,num1_len
    xchg ax,num2_len
    mov num1_len,ax

    xor si,si
    mov cl,max_len
    mov ch,0
sa_sw1:
    cmp si,cx
    jae sa_swapped
    mov al,[num1_digits+si]
    mov ah,[num2_digits+si]
    mov [num1_digits+si],ah
    mov [num2_digits+si],al
    inc si
    jmp sa_sw1
sa_swapped:
    call subtract

    xor si,si
    mov cl,max_len
    mov ch,0
sa_sw2:
    cmp si,cx
    jae sa_setsign
    mov al,[num1_digits+si]
    mov ah,[num2_digits+si]
    mov [num1_digits+si],ah
    mov [num2_digits+si],al
    inc si
    jmp sa_sw2
sa_setsign:
    mov ax,num1_len
    xchg ax,num2_len
    mov num1_len,ax
    mov al,num2_sign
    mov result_sign,al
    ret
signed_add endp

add_magnitudes proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax,num1_len
    mov bx,num2_len
    cmp ax,bx
    ja  am_maxA
    mov cx,bx
    jmp am_maxOk
am_maxA:
    mov cx,ax
am_maxOk:
    xor si,si
    xor dl,dl
    mov bl,base

am_L:
    cmp si,cx
    jae am_after
    mov al,0
    mov ah,0
    cmp si,num1_len
    jae am_noA
    mov al,[num1_digits+si]
am_noA:
    cmp si,num2_len
    jae am_noB
    mov ah,[num2_digits+si]
am_noB:
    add al,ah
    add al,dl
    cmp al,bl
    jb  am_noC
    sub al,bl
    mov dl,1
    jmp am_store
am_noC:
    mov dl,0
am_store:
    mov [result_digits+si],al
    inc si
    jmp am_L

am_after:
    or  dl,dl
    jz  am_set
    mov [result_digits+si],dl
    inc si
am_set:
    mov result_len,si

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
add_magnitudes endp

subtract proc
    push ax
    push bx
    push dx
    push si

    xor si,si
    mov bl,base
    xor dl,dl

sb_L:
    cmp si,num1_len
    jae sb_D
    mov al,0
    cmp si,num1_len
    jae sb_noA
    mov al,[num1_digits+si]
sb_noA:
    mov ah,0
    cmp si,num2_len
    jae sb_noB
    mov ah,[num2_digits+si]
sb_noB:
    sub al,dl
    cmp al,ah
    jae sb_noBorrow
    add al,bl
    mov dl,1
    jmp sb_store
sb_noBorrow:
    xor dl,dl
sb_store:
    sub al,ah
    mov [result_digits+si],al
    inc si
    jmp sb_L

sb_D:
    mov ax,si
    or  ax,ax
    jnz sb_T1
    mov ax,1
    mov byte ptr [result_digits],0
    jmp sb_set
sb_T1:
    dec ax
sb_T:
    mov si,ax
    mov dl,[result_digits+si]
    or  dl,dl
    jnz sb_setLen
    or  ax,ax
    jz  sb_one
    dec ax
    jmp sb_T
sb_one:
    mov ax,1
    mov byte ptr [result_digits],0
    jmp sb_set
sb_setLen:
    inc ax
sb_set:
    mov result_len,ax

    pop si
    pop dx
    pop bx
    pop ax
    ret
subtract endp

compare_magnitudes proc
    push bx
    push cx
    push dx
    push si

    mov ax,num1_len
    mov bx,num2_len

ca_ta:
    cmp ax,0
    je  ca_ta_d
    mov si,ax
    dec si
    mov dl,[num1_digits+si]
    or  dl,dl
    jnz ca_ta_d
    dec ax
    jmp ca_ta
ca_ta_d:

ca_tb:
    cmp bx,0
    je  ca_tb_d
    mov si,bx
    dec si
    mov dl,[num2_digits+si]
    or  dl,dl
    jnz ca_tb_d
    dec bx
    jmp ca_tb
ca_tb_d:

    cmp ax,bx
    ja  ca_agt
    jb  ca_bgt

    mov dx,ax
    or  dx,dx
    jz  ca_eq
    dec dx
ca_ul:
    mov si,dx
    mov al,[num1_digits+si]
    mov ah,[num2_digits+si]
    cmp al,ah
    ja  ca_agt
    jb  ca_bgt
    or  dx,dx
    jz  ca_eq
    dec dx
    jmp ca_ul

ca_eq:
    xor ax,ax
    jmp ca_out
ca_agt:
    mov ax,1
    jmp ca_out
ca_bgt:
    mov ax,0FFFFh

ca_out:
    pop si
    pop dx
    pop cx
    pop bx
    ret
compare_magnitudes endp

; ==== конец вставки из bignumb.asm ====

signed_multiply proc
    call clear_result
    mov al,num1_sign
    xor al,num2_sign
    mov result_sign,al
    call multiply
    ret
signed_multiply endp

multiply proc
    pusha
    mov cl,base
    xor si,si
mm_outer:
    mov ax,num1_len
    cmp si,ax
    jae mm_done
    mov dl,num1_digits[si]
    xor di,di
    mov ch,0
mm_inner:
    mov ax,num2_len
    cmp di,ax
    jae mm_inner_done
    mov al,num2_digits[di]
    mul dl
    mov bx,si
    add bx,di
    add bx,offset result_digits
    add al,[bx]
    adc ah,0
    add al,ch
    adc ah,0
    div cl
    mov ch,al
    mov [bx],ah
    inc di
    jmp mm_inner
mm_inner_done:
    cmp ch,0
    je mm_no_tail
    mov bx,si
    mov ax,num2_len
    add bx,ax
    add bx,offset result_digits
mm_prop:
    add [bx],ch
    mov al,[bx]
    xor ah,ah
    div cl
    mov [bx],ah
    mov ch,al
    inc bx
    cmp ch,0
    jne mm_prop
mm_no_tail:
    inc si
    jmp mm_outer
mm_done:
    mov ax,num1_len
    add ax,num2_len
    mov result_len,ax
    call trim_zeros_proc
    popa
    ret
multiply endp

clear_result proc
    push di
    push cx
    push ax
    push ds
    pop es
    lea di,result_digits
    mov cx,max_len*2+1
    xor al,al
    rep stosb
    mov result_len,0
    mov result_sign,0
    pop ax
    pop cx
    pop di
    ret
clear_result endp

clear_result_str proc
    push di
    push cx
    push ax
    push ds
    pop es
    lea di,result_str
    mov cx,max_len*2+3
    mov al,'$'
    rep stosb
    pop ax
    pop cx
    pop di
    ret
clear_result_str endp

trim_zeros_proc proc
    push bx
    push ax
    lea bx,result_digits
    add bx,result_len
    dec bx
tz_loop:
    mov ax,result_len
    cmp ax,1
    jle tz_after
    cmp byte ptr [bx],0
    jne tz_after
    dec bx
    dec result_len
    jmp tz_loop
tz_after:
    mov ax,result_len
    cmp ax,1
    jne tz_end
    cmp byte ptr [result_digits],0
    jne tz_end
    mov result_sign,0
tz_end:
    pop ax
    pop bx
    ret
trim_zeros_proc endp

print_error_and_exit proc
    mov ah,9
    lea dx,error_prompt
    int 21h
    mov ax,4c01h
    int 21h
print_error_and_exit endp

print_base_mismatch_and_exit proc
    mov ah,9
    lea dx,error_base_mismatch
    int 21h
    mov ax,4c01h
    int 21h
print_base_mismatch_and_exit endp

end main
