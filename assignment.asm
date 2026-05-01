  ; students names  -- ID 
; noor asfour ------ 1232349
; masa inabe  ----- 1231024
.model small
.stack 100h  

.data
; IDs of employees,we have 10, two empty spaces  for now
EmpIDs      dw 65, 48, 26, 36, 15, 82, 12, 28, 94, 29

; encrypted passwords
; original: 12, 84, 29, 37, 87, 19, 62, 75, -, -        
EncPass     db 3, 21, 156, 164, 213, 146, 143, 202, 0, 0  ; last two empty for now

EmpCount    dw 10

;menu and messages
msgMenu     db 0Dh,0Ah,"--- Login as: ---"
db 0Dh,0Ah,"1. Employee"
db 0Dh,0Ah,"2. Manager"
db 0Dh,0Ah,"3. Exit"
db 0Dh,0Ah,"select from the menu: $"
msgID  db 0Dh,0Ah,"enter employee ID: $"
msgPass db 0Dh,0Ah,"enter Password: $"
msgNewPass db 0Dh,0Ah,"enter new Password for this employee: $"
msgAllow db 0Dh,0Ah,"access allowed:)$"
msgDeny db 0Dh,0Ah,"access denied:($"
msgList db 0Dh,0Ah,"employee List (ID - Encrypted Pass):$"
msgSpace db "  -  $"
msgNewLine db 0Dh,0Ah,"$" 
msgTooBig db 0Dh,0Ah,"Password too big! Enter a number <= 255:", "$"

;variables for input
inputID     dw ?
inputPass   db ?
choice      db ?

.code
main proc
mov ax, @DATA
mov ds, ax

ShowMenu:
lea dx, msgMenu
mov ah, 09h
int 21h
mov ah, 01h     
int 21h
mov choice, al  

;simple check menu
cmp choice, '1'
je EmployeeMode
cmp choice, '2'
je ManagerMode
cmp choice, '3'
je ExitProg
jmp ShowMenu 

EmployeeMode:

;ask for ID
lea dx, msgID
mov ah, 09h
int 21h
call ReadNumber
mov inputID, ax 

;ask for password
lea dx, msgPass
mov ah, 09h
int 21h
call ReadHiddenNumber    ;returns ax
mov al, al             ;just al
call Encrypt             ;do   encrypton
mov inputPass, al       ;store encrypted

;look for employee
call FindEmployee
cmp si, 0FFFFh 
je EmpDenied
    
;check password
mov al, inputPass
cmp al, [di]
je EmpAllowed
jmp EmpDenied

EmpDenied:
lea dx, msgDeny
mov ah, 09h
int 21h
jmp ShowMenu

EmpAllowed:
lea dx, msgAllow
mov ah, 09h
int 21h
jmp ShowMenu
             
ManagerMode:
;print employee list
lea dx, msgList
mov ah, 09h
int 21h    
lea dx, msgNewLine
mov ah, 09h
int 21h    
mov cx, EmpCount
lea si, EmpIDs
lea di, EncPass

PrintLoop:
;print ID
mov ax, [si]
call PrintNumber
call PrintSpace
    
;print encrypted password
mov al, [di]
xor ah, ah
call PrintNumber
    
;new line
lea dx, msgNewLine
mov ah, 09h
int 21h    
add si, 2
inc di
loop PrintLoop

;change password part
lea dx, msgID
mov ah, 09h
int 21h
call ReadNumber
mov inputID,ax
call FindEmployee
cmp si,0FFFFh
je EmpDenied

; new password
lea dx, msgNewPass
mov ah, 09h
int 21h
call ReadHiddenNumber
mov al, al 
call Encrypt
mov [di], al

lea DX, msgAllow 
mov AH, 09h
int 21h
jmp ShowMenu

ExitProg:
mov ah, 4Ch
int  21h
main endp

;simple search for employee by ID
FindEmployee proc
mov cx, EmpCount
lea si, EmpIDs
lea di, EncPass
SearchL:
mov ax, [si]
cmp ax, inputID
je Found
add si, 2
inc di
loop SearchL
mov si,0FFFFh 
ret
Found:
ret
FindEmployee endp

;read number from keyboard
ReadNumber proc
push bx
push cx
xor bx,bx
R_Loop:
mov ah, 01h
int 21h
cmp al, 0Dh
je R_Done
cmp al, '0'
jb R_Loop
cmp al, '9'
ja R_Loop
sub al, '0'
mov cl, al
mov ch, 0
mov ax, 10
mul bx
add ax,cx
mov bx,ax
jmp R_Loop
R_Done:
mov ax, bx
pop cx
pop bx
ret
ReadNumber endp

; read password without showing
ReadHiddenNumber proc
RetryInput:
    xor bx, bx
H_Loop:
mov ah, 08h
int 21h
cmp al, 0Dh
je H_Done
cmp al, '0'
jb H_Loop
cmp al, '9'
ja H_Loop
    
;print & to take place of showing the password 
push ax
mov dl, '&'
mov ah, 02h
int 21h
pop ax
sub al, '0'
mov cl, al
mov ch, 0
mov ax, bx
mov dx, 10
mul dx
add ax, cx
cmp ax, 255
ja TooBig   
mov bx,ax
jmp H_Loop
    
TooBig:
lea dx,msgTooBig
mov ah,09h
int 21h
jmp RetryInput
    
H_Done:
mov ax,bx
ret
ReadHiddenNumber endp

;simple encrypt function
Encrypt proc
push bx
push cx    
mov bl,al
mov cl,bl
and cl,01h  ;get lsb   
mov ch, bl
and ch, 80h  ;get msb
shr ch, 7
cmp cl, ch
je RotateRight    
;swap lsband msb
and bl, 7Eh
shl cl, 7
or bl, cl
or bl, ch
mov al, bl
jmp Done
    
RotateRight:
mov al, bl
ror al, 2
    
Done:
pop cx
pop bx
ret
Encrypt endp
       
       
       
;print number
PrintNumber proc
push ax
push bx
push cx
push dx   
mov bx, 10
xor cx, cx
cmp ax, 0
jne ConvertLoop
mov dl, '0'
mov ah, 02h
int 21h
jmp PrintDone
    
ConvertLoop:
xor dx,dx
div bx
push dx
inc cx
test ax,ax
jnz ConvertLoop
  
  
    
PrintDigits:
pop dx
add dl, '0'
mov ah, 02h
int 21h
loop PrintDigits
    
PrintDone:
pop dx
pop cx
pop bx
pop ax
ret
PrintNumber endp


;print single space
PrintSpace proc
push ax
push dx
mov dl, ' '
mov ah, 02h
int 21h
pop dx
pop ax
ret
PrintSpace endp


end main
