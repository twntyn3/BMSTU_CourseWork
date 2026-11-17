; LAB6_PM_N18_FINAL_v2.ASM  (TASM 2.02)
        .386p

GROUP_NO        EQU     18

PAGE_DIR_PHYS   EQU     00100000h
PAGE_TBL0_PHYS  EQU     00101000h

HI_GDT_PHYS     EQU     00110000h
HI_CODE_PHYS    EQU     00120000h
HI_DATA_PHYS    EQU     00130000h
HI_STACK_TOP    EQU     0019F000h

VIDEO_PHYS      EQU     000B8000h
VIDEO_VIRT      EQU     (GROUP_NO*1000h)       ; 12000h for N=18

CODE_SEL        EQU     0008h
DATA_SEL        EQU     0010h

RM_CODE segment para public 'CODE' use16
        assume  cs:RM_CODE, ss:RM_STACK

@@start:
        mov     ax,0003h
        int     10h

        in      al,92h
        or      al,02h
        out     92h,al

        xor     eax,eax
        mov     ax,PM_CODE
        shl     eax,4
        add     eax,offset PM_STAGE1_ENTRY
        mov     dword ptr cs:ENTRY_OFF,eax

        xor     eax,eax
        mov     ax,RM_CODE
        shl     eax,4
        add     eax,offset GDT
        mov     dword ptr cs:GDTR+2,eax
        lgdt    fword ptr cs:GDTR

        cli
        in      al,70h
        or      al,80h
        out     70h,al

        mov     eax,cr0
        or      eax,00000001h
        mov     cr0,eax

        db      66h
        db      0EAh
ENTRY_OFF dd     0
        dw      CODE_SEL

; ---------------- GDT (copied to HI_GDT_PHYS before paging) ----------------
GDT:
NULL_descr      db  8 dup(0)

; CODE base=0, limit=FFFFF, G=1, DB=1  (effective limit FFFFFFFF)
CODE_descr      db  0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h

; DATA base=0, limit=FFFFF, G=1, DB=1  (effective limit FFFFFFFF)
DATA_descr      db  0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h

; VIDEO data: base=B8000h, limit=0FFFh, G=0, DB=1
VIDEO_descr     db  0FFh,0Fh,00h,80h,0Bh,10010010b,01000000b,00h

; INVALID #1: system reserved type (type=0), base_mid = GROUP_NO (18)
; access: P=1 DPL=0 S=0 type=0  => 80h
INV_SYS_descr   db  0FFh,0FFh,00h,00h,GROUP_NO,10000000b,00000000b,00h

; INVALID #2: reserved bit in 2nd dword (L=1), limit contains GROUP_NO (0012h)
; limit=0012h, base=0, access=9Ah (code), flags: L=1, others 0
INV_L_descr     db  (GROUP_NO AND 0FFh),((GROUP_NO SHR 8) AND 0FFh),00h,00h,00h,10011010b,00100000b,00h

; SYSTEM descriptor (valid): 32-bit available TSS type=9, P=1 => 89h
SYS_TSS_descr   db  00h,00h,00h,00h,00h,10001001b,00000000b,00h

GDT_size        equ $-GDT
GDTR            dw  GDT_size-1
                dd  0

RM_CODE ends

RM_STACK segment para stack 'STACK' use16
        db  200h dup(?)
RM_STACK ends

PM_CODE segment para public 'CODE' use32
        assume cs:PM_CODE, ds:PM_DATA, ss:PM_DATA

; ---------------- Stage 1: relocate GDT + data + stage2 code, then enable paging ----------------
PM_STAGE1_ENTRY:
        mov     ax,DATA_SEL
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     esp,0009F000h
        cld

        ; Copy current GDT (from GDTR) to HI_GDT_PHYS
        sub     esp,8
        sgdt    fword ptr [esp]
        movzx   ecx,word ptr [esp]
        inc     ecx
        mov     esi,dword ptr [esp+2]
        add     esp,8

        mov     edi,HI_GDT_PHYS
        mov     edx,ecx
        shr     ecx,2
        rep     movsd
        mov     ecx,edx
        and     ecx,3
        rep     movsb

        ; Copy PM_DATA to HI_DATA_PHYS
        xor     eax,eax
        mov     ax,PM_DATA
        shl     eax,4
        mov     esi,eax
        mov     edi,HI_DATA_PHYS
        mov     ecx,(PM_DATA_SIZE+3)/4
        rep     movsd

        ; Copy stage2 code to HI_CODE_PHYS
        xor     eax,eax
        mov     ax,PM_CODE
        shl     eax,4
        add     eax,offset PM_STAGE2_START
        mov     esi,eax
        mov     edi,HI_CODE_PHYS
        mov     ecx,(PM_STAGE2_SIZE+3)/4
        rep     movsd

        ; Build paging: PDE[0] -> PT0, identity map first 4MB, patch page N*1000h -> B8000h
        mov     edi,PAGE_DIR_PHYS
        mov     eax,(PAGE_TBL0_PHYS or 00000007h)
        stosd
        mov     ecx,1023
        xor     eax,eax
        rep     stosd

        mov     edi,PAGE_TBL0_PHYS
        mov     eax,00000007h
        mov     ecx,1024
@@fill_pt0:
        mov     dword ptr [edi],eax
        add     edi,4
        add     eax,1000h
        loop    @@fill_pt0

        mov     edi,PAGE_TBL0_PHYS
        mov     eax,GROUP_NO
        shl     eax,2
        add     edi,eax
        mov     dword ptr [edi],(VIDEO_PHYS or 00000007h)

        mov     eax,PAGE_DIR_PHYS
        mov     cr3,eax

        mov     eax,cr0
        or      eax,80000000h
        mov     cr0,eax
        jmp     short $+2

        ; Jump to relocated stage2
        db      0EAh
        dd      (HI_CODE_PHYS + (PM_STAGE2_ENTRY - PM_STAGE2_START))
        dw      CODE_SEL

; ---------------- Stage 2 (runs from HI_CODE_PHYS) ----------------
PM_STAGE2_START label byte

PM_STAGE2_ENTRY:
        mov     ax,DATA_SEL
        mov     ds,ax
        mov     es,ax
        mov     ss,ax
        mov     esp,HI_STACK_TOP
        cld

        mov     ebp,HI_DATA_PHYS

        ; Force GDTR -> relocated GDT
        sub     esp,8
        mov     word ptr [esp],(GDT_size-1)
        mov     dword ptr [esp+2],HI_GDT_PHYS
        lgdt    fword ptr [esp]
        add     esp,8

        mov     byte ptr [ebp + offset cur_attr],07h
        call    ClearScreen

        mov     byte ptr [ebp + offset cur_attr],0Fh
        lea     esi,[ebp + offset S_TITLE]
        call    PrintStrZ
        call    NewLine
        call    NewLine

        lea     esi,[ebp + offset GDTR_BUF]
        sgdt    fword ptr [esi]

        movzx   ecx,word ptr [esi]
        inc     ecx
        shr     ecx,3
        mov     eax,dword ptr [esi+2]
        mov     dword ptr [ebp + offset GDT_BASE],eax

        xor     eax,eax
@@gdt_loop:
        push    ecx

        mov     edx,eax
        and     edx,00000007h
        lea     esi,[ebp + offset ColorTbl]
        mov     dl,byte ptr [esi+edx]
        mov     byte ptr [ebp + offset cur_attr],dl

        mov     esi,dword ptr [ebp + offset GDT_BASE]
        lea     esi,[esi + eax*8]

        call    ShowDescriptor
        call    NewLine

        inc     eax
        pop     ecx
        loop    @@gdt_loop

@@hang:
        jmp     @@hang

; ---------------- Screen helpers (write to VIDEO_VIRT) ----------------
ClearScreen proc near
        push    eax
        push    ecx

        mov     dword ptr [ebp + offset cur_row],0
        mov     dword ptr [ebp + offset cur_col],0

        mov     edi,VIDEO_VIRT
        mov     ax,0720h
        mov     ecx,80*25
        rep     stosw

        mov     edi,VIDEO_VIRT

        pop     ecx
        pop     eax
        ret
ClearScreen endp

NewLine proc near
        push    eax

        mov     eax,dword ptr [ebp + offset cur_row]
        inc     eax
        mov     dword ptr [ebp + offset cur_row],eax
        mov     dword ptr [ebp + offset cur_col],0

        imul    eax,eax,160
        add     eax,VIDEO_VIRT
        mov     edi,eax

        pop     eax
        ret
NewLine endp

PrintChar proc near
        push    eax
        push    ebx

        mov     bl,byte ptr [ebp + offset cur_attr]
        mov     byte ptr [edi],al
        mov     byte ptr [edi+1],bl
        add     edi,2

        mov     eax,dword ptr [ebp + offset cur_col]
        inc     eax
        mov     dword ptr [ebp + offset cur_col],eax
        cmp     eax,80
        jb      @@ok
        call    NewLine
@@ok:
        pop     ebx
        pop     eax
        ret
PrintChar endp

PrintStrZ proc near
        push    eax
@@next:
        mov     al,byte ptr [esi]
        inc     esi
        test    al,al
        jz      @@done
        cmp     al,0Dh
        jne     @@not_cr
        call    NewLine
        jmp     @@next
@@not_cr:
        cmp     al,0Ah
        je      @@next
        call    PrintChar
        jmp     @@next
@@done:
        pop     eax
        ret
PrintStrZ endp

PrintHex32 proc near
        push    eax
        push    ecx
        push    edx
        push    esi

        mov     edx,eax
        mov     ecx,8
@@hx:
        rol     edx,4
        mov     al,dl
        and     al,0Fh
        movzx   eax,al
        lea     esi,[ebp + offset HexTbl]
        mov     al,byte ptr [esi+eax]
        call    PrintChar
        loop    @@hx

        pop     esi
        pop     edx
        pop     ecx
        pop     eax
        ret
PrintHex32 endp

; prints EDX:EAX as 16 hex digits
PrintHex64 proc near
        push    eax
        push    edx
        mov     eax,edx
        call    PrintHex32
        pop     edx
        pop     eax
        call    PrintHex32
        ret
PrintHex64 endp

PrintHex8 proc near
        push    eax
        push    ecx
        push    edx
        push    esi

        mov     dl,al
        mov     ecx,2
@@hx8:
        rol     dl,4
        mov     al,dl
        and     al,0Fh
        movzx   eax,al
        lea     esi,[ebp + offset HexTbl]
        mov     al,byte ptr [esi+eax]
        call    PrintChar
        loop    @@hx8

        pop     esi
        pop     edx
        pop     ecx
        pop     eax
        ret
PrintHex8 endp

PrintDigit proc near
        add     al,'0'
        call    PrintChar
        ret
PrintDigit endp

PrintBitFromZF proc near
        push    eax
        mov     al,'0'
        jz      @@p
        mov     al,'1'
@@p:    call    PrintChar
        pop     eax
        ret
PrintBitFromZF endp

; ---------------- Descriptor decode ----------------
; IN: ESI = descriptor pointer, index is on stack from caller loop (EAX before call)
ShowDescriptor proc near
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    esi

        mov     ebx,esi
        mov     dl,byte ptr [ebx+5]         ; access
        mov     dh,byte ptr [ebx+6]         ; flags/limhi

        lea     esi,[ebp + offset S_GDT1]
        call    PrintStrZ

        mov     al,byte ptr [esp+16]
        call    PrintHex8

        lea     esi,[ebp + offset S_BASE]
        call    PrintStrZ

        ; base
        movzx   eax,word ptr [ebx+2]
        movzx   ecx,byte ptr [ebx+4]
        shl     ecx,16
        or      eax,ecx
        movzx   ecx,byte ptr [ebx+7]
        shl     ecx,24
        or      eax,ecx
        call    PrintHex32

        ; raw 20-bit limit in EAX
        movzx   eax,word ptr [ebx]
        movzx   ecx,byte ptr [ebx+6]
        and     ecx,0Fh
        shl     ecx,16
        or      eax,ecx

        ; effective limit
        lea     esi,[ebp + offset S_LIM]
        call    PrintStrZ

        test    byte ptr [ebx+6],80h
        jz      @@lim_byte
        shl     eax,12
        or      eax,0FFFh
@@lim_byte:
        call    PrintHex32

        ; size = effective_limit + (G?1000h:1)
        push    edx                         ; save access/flags in DL/DH
        lea     esi,[ebp + offset S_SIZE]
        call    PrintStrZ

        xor     edx,edx
        test    byte ptr [ebx+6],80h
        jz      @@add1
        add     eax,1000h
        adc     edx,0
        lea     esi,[ebp + offset S_ADD1000]
        jmp     @@size_print
@@add1:
        add     eax,1
        adc     edx,0
        lea     esi,[ebp + offset S_ADD1]
@@size_print:
        push    esi
        call    PrintHex64
        pop     esi
        call    PrintStrZ
        pop     edx                         ; restore DL/DH

        call    NewLine

        ; NULL?
        cmp     dword ptr [esp+16],0
        jne     @@not_null
        lea     esi,[ebp + offset S_NULL]
        call    PrintStrZ
        call    NewLine
        jmp     @@done_block

@@not_null:
        ; INVALID #2: reserved bit in 2nd dword (L=1) => flags bit 5
        test    dh,20h
        jz      @@chk_sys
        lea     esi,[ebp + offset S_INV_L]
        call    PrintStrZ
        call    NewLine
        jmp     @@done_block

@@chk_sys:
        ; INVALID #1: system reserved types (S=0 and type in {0,8,Ah,Dh})
        test    dl,10h
        jnz     @@valid_access               ; S=1 -> code/data
        mov     al,dl
        and     al,0Fh
        cmp     al,00h
        je      @@inv_sys
        cmp     al,08h
        je      @@inv_sys
        cmp     al,0Ah
        je      @@inv_sys
        cmp     al,0Dh
        je      @@inv_sys
        jmp     @@valid_access
@@inv_sys:
        lea     esi,[ebp + offset S_INV_SYS]
        call    PrintStrZ
        call    NewLine
        jmp     @@done_block

@@valid_access:
        lea     esi,[ebp + offset S_P]
        call    PrintStrZ
        test    dl,80h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_DPL]
        call    PrintStrZ
        mov     al,dl
        shr     al,5
        and     al,03h
        call    PrintDigit

        lea     esi,[ebp + offset S_S]
        call    PrintStrZ
        test    dl,10h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_AVL]
        call    PrintStrZ
        test    dh,10h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_DB]
        call    PrintStrZ
        test    dh,40h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_G]
        call    PrintStrZ
        test    dh,80h
        call    PrintBitFromZF

        call    NewLine

        test    dl,10h
        jnz     @@code_data

        lea     esi,[ebp + offset S_SYS]
        call    PrintStrZ
        mov     al,dl
        and     al,0Fh
        call    PrintHex8
        call    NewLine
        jmp     @@done_block

@@code_data:
        mov     al,dl
        and     al,0Fh
        test    al,08h
        jnz     @@is_code

        lea     esi,[ebp + offset S_DATA]
        call    PrintStrZ

        lea     esi,[ebp + offset S_W]
        call    PrintStrZ
        test    dl,02h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_ED]
        call    PrintStrZ
        test    dl,04h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_A]
        call    PrintStrZ
        test    dl,01h
        call    PrintBitFromZF

        call    NewLine
        jmp     @@done_block

@@is_code:
        lea     esi,[ebp + offset S_CODE]
        call    PrintStrZ

        lea     esi,[ebp + offset S_R]
        call    PrintStrZ
        test    dl,02h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_C]
        call    PrintStrZ
        test    dl,04h
        call    PrintBitFromZF

        lea     esi,[ebp + offset S_A]
        call    PrintStrZ
        test    dl,01h
        call    PrintBitFromZF

        call    NewLine

@@done_block:
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret
ShowDescriptor endp

PM_STAGE2_END label byte
PM_STAGE2_SIZE  equ (PM_STAGE2_END - PM_STAGE2_START)

PM_CODE ends

PM_DATA segment para public 'DATA' use32
        assume ds:PM_DATA

PM_DATA_START label byte

cur_row dd 0
cur_col dd 0
cur_attr db 07h

GDT_BASE dd 0

GDTR_BUF dw 0
         dd 0

ColorTbl db 0Fh,0Eh,0Ah,0Bh,0Ch,0Dh,09h,07h

HexTbl   db '0123456789ABCDEF'

S_TITLE   db 'LAB6: PM + Paging. Video via VIRT = N*1000h mapped to B8000h.',0
S_GDT1    db 'GDT[',0
S_BASE    db '] BASE=',0
S_LIM     db ' LIM=',0
S_SIZE    db ' SIZE=',0
S_ADD1    db ' (+1)',0
S_ADD1000 db ' (+1000h)',0

S_NULL    db 'NULL DESCRIPTOR',0
S_INV_L   db 'INVALID DESCRIPTOR (reserved bit in 2nd dword)',0
S_INV_SYS db 'INVALID DESCRIPTOR (reserved system type)',0

S_P       db 'P=',0
S_DPL     db ' DPL=',0
S_S       db ' S=',0
S_AVL     db ' AVL=',0
S_DB      db ' DB=',0
S_G       db ' G=',0

S_SYS     db 'SYSTEM DESCRIPTOR, type=',0
S_CODE    db 'CODE: ',0
S_DATA    db 'DATA: ',0

S_R       db 'R=',0
S_C       db ' C=',0
S_W       db 'W=',0
S_ED      db ' ED=',0
S_A       db ' A=',0

PM_DATA_END label byte
PM_DATA_SIZE    equ (PM_DATA_END - PM_DATA_START)

PM_DATA ends

        end @@start
