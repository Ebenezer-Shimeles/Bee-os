use16 ;The os starts at 16 bit so our instruction must meet that
[ org 0x7c00 ] ;Tell the assembler where the bootloader is loaded inorder to calculate the positions
start:
call cls
mov bx, booting
mov cx, 11
call print
call new_line
xor bx, bx
mov bx, bee_os_msg
mov cx, bee_os_msg_len
call print
prompt_loop:
  
    call read_kbd_and_eval
    jmp prompt_loop

jmp $ ;;CPU doesn't differentiate between data and instruction so stick here
;Here we write our functions


read_kbd_and_eval:
    mov ah, 0x00
    int 16h ; blocks 
    call is_enter
    mov ah, 0x0e ;print the characers
    int 0x10
    ;we need to store the new char in kdb_buffer 
    ret
is_enter:
    ; if the input is somehow enter we neet to make a new line
    ; also we check if the command starts with some commands
    cmp al, 0x0D
    
    jne enter_no
    enter_yes: 
        
        call is_echo
        
        call is_cls ; Check is the command is used to clear the screen
        call is_info ; Check if the command is an info command
         
        call clear_kbd_buffer
        call new_line
        mov bx, bee_os_msg
        mov cx, bee_os_msg_len
        call print
        jmp is_enter_avoid ; to avoid storing al in mem
    enter_no:
        call store_in_kbd_buffer
        call backspace
    is_enter_avoid:
        ret
restart: 

   jmp start
store_in_kbd_buffer:
   push bx
   cmp al, 0x08
   je dont_store
   
   mov bx, [curr_kbd]
   add bx, keyboard_buffer
   mov [bx], al
   mov bx, curr_kbd
   inc byte [bx]
   dont_store:
   pop bx
   ret



cls:
   mov al, 0x01
   mov ah, 0x00
   int 0x10
   ret
new_line:
    pusha
    mov ah, 0x0e
    mov al, 0x0D
    int 0x10
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    popa
   
    ret
is_restart:
    pusha
    mov cx, 0
    is_restart_loop:
       cmp cx, 7
       je is_restart_yes

       mov bx, keyboard_buffer
       add bx, cx
       mov ah, byte [bx]

       mov bx, restart_cmd
       add bx, cx

       cmp [bx], ah
       jne is_restart_no
       inc cx
       jmp is_restart_loop
   

    is_restart_yes:
       call restart
    is_restart_no:
    popa
    ret
is_echo:
    pusha
    mov cx, 0
    is_echo_loop:
       cmp cx, 4
       je is_echo_yes

       mov bx, keyboard_buffer
       add bx, cx
       mov ah, byte [bx]

       mov bx, echo_cmd
       add bx, cx

       cmp [bx], ah
       jne is_echo_no
       inc cx
       jmp is_echo_loop
   

    is_echo_yes:
       call echo
    is_echo_no:
    popa
    ret

is_info:
    pusha
    mov cx, 0

    is_info_loop:
       cmp  cx, 4
       je is_info_yes

       mov bx, keyboard_buffer
       add bx, cx
       mov ah, byte [bx]

       mov bx, info_cmd
       add bx, cx

       cmp [bx], ah
       jne is_info_no
       inc cx
       jmp is_info_loop




       
    is_info_yes:
        call new_line
        mov bx, bee_os_info
        mov cx, bee_os_info_len
        call print
    is_info_no:

    popa
   
    ret
is_cls:
    pusha
    mov cx, 0

    is_cls_loop:
       cmp  cx, 3
       je is_cls_yes

       mov bx, keyboard_buffer
       add bx, cx
       mov ah, byte [bx]

       mov bx, cls_cmd
       add bx, cx

       cmp [bx], ah
       jne is_cls_no
       inc cx
       jmp is_cls_loop
    is_cls_yes:

        call cls
    is_cls_no:
    popa
    ret
is_dskinfo:
   ret
is_shutdown:
   ret

clear_kbd_buffer:
    ; This clear the keyboard buffer
    pusha
    mov bx, keyboard_buffer
    mov cx, 0
    clear_kbd_buffer_loop:
        cmp cx, 20
        je  clear_kbd_buffer_exit
        mov byte [bx], 0x00
        inc bx
        inc cx
        jmp clear_kbd_buffer_loop
      
       

    clear_kbd_buffer_exit:
    popa
    mov byte [curr_kbd], 0
    ret
backspace:
   push bx

   cmp al, 0x08
   jne bs_not_needed
  
   bs_needed:
    
    
     
      mov bx, keyboard_buffer
      add bx, [curr_kbd]
      dec bx
      mov byte [bx], 0
      mov bx, curr_kbd
      dec byte [bx]
    
   bs_not_needed:

   pop bx
   ret
echo:
   call new_line
   mov bx, keyboard_buffer + 5
   mov cx, 10
   call print
   ret


print:
  ; This is used to print
  ; Get base address at bx
  ; Get char count at cx
  print_loop:
      cmp cx, 0
      jz exit_loop
      jl exit_loop
      dec cx
      mov byte al, [bx]
      mov ah, 0x0e
      int 0x10
      inc bx
      jmp print_loop
  exit_loop:
      ret

;; Strings and stuff should be here
DATA:
   info_cmd db 'info'
   cls_cmd db 'cls'
   echo_cmd db 'echo'
   restart_cmd db 'restart'
  
   booting db 'Booting ...'
   bee_os_info db 'Bee os version 0.1 on x86 cpu'
   bee_os_info_len equ 28
   bee_os_msg db 'Welcome to Bee os: '
   bee_os_msg_len equ 18
   keyboard_buffer  times 15 db 0
   ;keyboard_buffer db 'echo this is just for a test please suck this '
   ;Our keyboard buffer is 20 at max here since we need to fit it in 512 byte bootloader
   curr_kbd db 0
times 510 - ($- $$) db 0

magig dw 0xaa55