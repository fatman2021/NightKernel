; Night Kernel version 0.04
; Copyright 1995 - 2016 by mercury0x000d
; hardware.asm is a part of the Night Kernel

; The Night Kernel is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as published
; by the Free Software Foundation, either version 3 of the License, or (at
; your option) any later version.

; The Night Kernel is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
; for more details.

; You should have received a copy of the GNU General Public License along
; with the Night Kernel. If not, see <http://www.gnu.org/licenses/>.

; See the included file <GPL License.txt> for the complete text of the
; GPL License by which this program is covered.



bits 16



PrintFail:
 ; Prints an ASCIIZ failure message directly to the screen.
 ; Note: Uses text mode (assumed already set) not VESA.
 ; Note: For use in Real Mode only.
 ;  input:
 ;   address of string to print
 ;
 ;  output:
 ;   n/a

 ; set the proper mode
 mov ah, 0x00
 mov al, 0x03
 sti
 int 0x10
 cli
 
 pop ax
 pop si
 push ax

 ; write the string
 mov bl, 0x04
 mov ax, 0xB800
 mov ds, ax
 mov di, 0x0000
 mov ax, 0x0000
 mov es, ax
 
 .loopBegin:
 mov al, [es:si]

 ; have we reached the string end? if yes, exit the loop
 cmp al, 0x00
 je .end

 mov byte[ds:di], al
 inc di
 mov byte[ds:di], bl
 inc di
 inc si
 jmp .loopBegin
 .end:
 
ret



bits 32



PICDisableIRQs:
 ; Disables all IRQ lines across both PICs
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov al, 0xFF                     ; disable IRQs
 mov dx, [kPIC1DataPort]          ; set up PIC 1
 out dx, al
 mov dx, [kPIC2DataPort]          ; set up PIC 2
 out dx, al
ret



PICInit:
 ; Init & remap both PICs to use int numbers 0x20 - 0x2f
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov al, 0x11                     ; set ICW1
 mov dx, [kPIC1CmdPort]           ; set up PIC 1
 out dx, al
 mov dx, [kPIC2CmdPort]           ; set up PIC 2
 out dx, al

 mov al, 0x20                     ; set base interrupt to 0x20 (ICW2)
 mov dx, [kPIC1DataPort]
 out dx, al

 mov al, 0x28                     ; set base interrupt to 0x28 (ICW2)
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0x04                     ; set ICW3 to cascade PICs together
 mov dx, [kPIC1DataPort]
 out dx, al
 mov al, 0x02                     ; set ICW3 to cascade PICs together
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0x05                     ; set PIC 1 to x86 mode with ICW4
 mov dx, [kPIC1DataPort]
 out dx, al

 mov al, 0x01                     ; set PIC 2 to x86 mode with ICW4
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0                        ; zero the data register
 mov dx, [kPIC1DataPort]
 out dx, al
 mov dx, [kPIC2DataPort]
 out dx, al

 mov al, 0xFD
 mov dx, [kPIC1DataPort]
 out dx, al
 mov al, 0xFF
 mov dx, [kPIC2DataPort]
 out dx, al

ret



PICIntComplete:
 ; Tells both PICs the interrupt has been handled
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov al, 0x20                     ; sets the interrupt complete bit
 mov dx, [kPIC1CmdPort]           ; write bit to PIC 1
 out dx, al

 mov dx, [kPIC2CmdPort]           ; write bit to PIC 2
 out dx, al

ret



PICMaskAll:
 ; Masks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov dx, [kPIC1DataPort]
 in al, dx
 and al, 0xff
 out dx, al

 mov dx, [kPIC2DataPort]
 in al, dx
 and al, 0xff
 out dx, al

ret



PICMaskSet:
 ; Masks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov dx, [kPIC1DataPort]
 in al, dx
 and al, 0xff
 out dx, al

 mov dx, [kPIC2DataPort]
 in al, dx
 and al, 0xff
 out dx, al

ret



PICUnmaskAll:
 ; Masks all interrupts
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov al, 0x00
 mov dx, [kPIC1DataPort]
 out dx, al

 mov dx, [kPIC2DataPort]
 out dx, al

ret



PITInit:
 ; Init the PIT for our timing purposes
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov ax, 1193180 / 128

 mov al, 00110110b
 out 0x43, al

 out 0x40, al
 xchg ah,al
 out 0x40, al

ret



Reboot:
 ; Performs a warm reboot of the PC
 ;  input:
 ;   n/a
 ;
 ;  output:
 ;   n/a

 mov dx, 0x92
 in al, dx
 or al, 00000001b
 out dx, al

 ; and now, for the return we'll never reach...
ret



VESAPlot:
 ; Draws a pixel directly to the VESA linear framebuffer
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;
 ;  output:
 ;   n/a

 pop esi                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get color attribute
 push esi                         ; push return address back on the stack

 ; calculate write position
 mov dx, [VESAModeInfo.XResolution]
 mul edx
 add ax, bx
 mov edx, 4
 mul edx
 add eax, [VESAModeInfo.PhysBasePtr]

 ; do the write
 mov [eax], ecx
ret



VESAPrint:
 ; Prints an ASCIIZ string directly to the framebuffer
 ;  input:
 ;   horizontal position
 ;   vertical position
 ;   color attribute
 ;   address of string to print
 ;
 ;  output:
 ;   n/a

 pop edx                          ; get return address for end ret
 pop ebx                          ; get horizontal position
 pop eax                          ; get vertical position
 pop ecx                          ; get color attribute
 pop esi                          ; get string address
 push edx                         ; push return address back on the stack

 ; calculate write position into edi and save to the stack
 mov edx, 0
 mov dx, [VESAModeInfo.XResolution] ; can probably be optimized to use bytes per scanline field to eliminate doing multiply
 mul edx
 add ax, bx
 mov edx, 4
 mul edx
 add eax, [VESAModeInfo.PhysBasePtr]
 mov edi, eax
 push edi

 ; keep the number of bytes in a scanline handy in edx for later
 mov edx, 0
 mov dx, [VESAModeInfo.BytesPerScanline]

 ; time to step through the string and draw it
 .StringDrawLoop:
 ; put the first character of the string into bl
 mov byte bl, [esi]

 ; see if the char we just got is null - if so, we exit
 cmp bl, 0x00
 jz .End

 ; it wasn't, so we need to calculate the beginning of the data for this char in the font table into eax
 mov eax, 0
 mov al, bl
 mov bh, 16
 mul bh
 add eax, kernelFont

 .FontBytesLoop:
 ; save the contents of edx and move font byte 1 into dl, making a backup copy in dh
 push edx
 mov byte dl, [eax]
 mov byte dh, dl

 ; plot accordingly
 and dl, 10000000b
 cmp dl, 0
 jz .PointSkipA
 .PointPlotA:
 mov [edi], ecx
 .PointSkipA:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 01000000b
 cmp dl, 0
 jz .PointSkipB
 .PointPlotB:
 mov [edi], ecx
 .PointSkipB:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00100000b
 cmp dl, 0
 jz .PointSkipC
 .PointPlotC:
 mov [edi], ecx
 .PointSkipC:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00010000b
 cmp dl, 0
 jz .PointSkipD
 .PointPlotD:
 mov [edi], ecx
 .PointSkipD:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00001000b
 cmp dl, 0
 jz .PointSkipE
 .PointPlotE:
 mov [edi], ecx
 .PointSkipE:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000100b
 cmp dl, 0
 jz .PointSkipF
 .PointPlotF:
 mov [edi], ecx
 .PointSkipF:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000010b
 cmp dl, 0
 jz .PointSkipG
 .PointPlotG:
 mov [edi], ecx
 .PointSkipG:
 add edi, 4
 mov byte dl, dh

 ; plot accordingly
 and dl, 00000001b
 cmp dl, 0
 jz .PointSkipH
 .PointPlotH:
 mov [edi], ecx
 .PointSkipH:
 add edi, 4
 mov byte dl, dh

 ; increment the font pointer
 inc eax

 ; set the framebuffer pointer to the next line
 sub edi, 32
 pop edx
 add edi, edx

 dec bh
 cmp bh, 0
 jne .FontBytesLoop


 ; increment the string pointer
 inc esi

 ;restore the framebuffer pointer to its original value, save a copy adjusted for the next loop
 pop edi
 add edi, 32
 push edi

 jmp .StringDrawLoop

 .End:

 ;get rid of that extra saved value
 pop edi
ret




















