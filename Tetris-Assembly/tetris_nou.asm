.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern printf:proc
extern fprintf:proc
extern fopen:proc
extern fclose:proc

extern fscanf:proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data

include digits.inc
include letters.inc
include patratel.inc



;aici declaram date
piece struct
pieceXarray dd 0
pieceYarray dd 0
indicematrice dd 0
piece ends

numarpiese dd 0
indice dd 0
pieces piece {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}

window_title DB "Tetris",0
area_width EQU 640
area_height EQU 480
area DD 0
format db " ",0
format2  db "Score: %d",10,0
counter DD 0 ; numara evenimentele de tip timer

scor DD 0
;scor_final dd 0
arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20


symbol_width EQU 10
symbol_height EQU 20
cordXpiece dd 290
cordYpiece dd 20 ;40 

indicerandom dd 0; modificat
afisareindice dd 1

y dd 0

pozafisarey dd 40
pozafisarex dd 525



button_x EQU 170
button_y EQU 15
button_size1 EQU 270
button_size2 EQU 440   

button_x_mic EQU 500
button_y_mic EQU 15
button_size1_mic EQU 80
button_size2_mic EQU 100

tip0 EQU 0
tip1 EQU 1
tip2 EQU 2

rotatieindice dd 0
lungime_patratel equ 15


titluw equ 150
titluh equ 69

mode_write db "a+",0
mode_read db "r",0
filename  db "scor.txt"

f dd 0
.code
  
  make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa 
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

linie_horizontal macro x, y,len, color
local bucla_linie
   mov eax, y; EAX=y
   mov ebx, area_width
   mul ebx; EAX=y*area_width
   add eax,x; EAX=y*area_width+x
   shl eax,2; EAX=(y*area_width+x)*4
   add eax,area
   mov ecx,len
  bucla_linie:
  mov dword ptr[eax], color
  add eax,4
  loop bucla_linie
 endm
   
 linie_vertical macro x, y,len, color
local bucla_linie
   mov eax, y; EAX=y
   mov ebx, area_width
   mul ebx; EAX=y*area_width
   add eax,x; EAX=y*area_width+x
   shl eax,2; EAX=(y*area_width+x)*4
   add eax,area
   mov ecx,len
  bucla_linie:
  mov dword ptr[eax], color
  add eax,area_width*4
  loop bucla_linie
 endm  
 


;**********************************************************************************************************
;************************************************		PATRAT    *****************************************
;******************************************************************************************************
make_patratel_0 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,galben_0

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_0 endp

;simple macro to call the procedure easier
make_patratel_macro_0 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_0
	add esp, 12
endm  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 piesa_patrat MACRO darea,x,y
   pusha
   make_patratel_macro_0 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   push x
    
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   
   make_patratel_macro_0 darea, x, y
   pop x
   
   push y
   
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_0 darea, x, y
   
   push x
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_0 darea, x, y
   pop x
   pop y
      	
    popa

endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

miscare_patrat MACRO x,y

 LOCAL  moveright,nimic2,moveleft,nimic,nuschimb1,verifpiesajos,nimic3
pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,425
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:

	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,405
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_patrat area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rotire_patrat MACRO	  x,y
LOCAL afisare1, afisare2,rotatie,afisare3, rotatie2, rotatie1,nimic
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_patrat x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_patrat x,y
	jmp nimic
	afisare2:
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_patrat x,y
	jmp nimic
	
	rotatie1:
	cmp rotatieindice,2
	jne rotatie2
	miscare_patrat x,y
	jmp nimic
	
	
	rotatie2:
	mov rotatieindice,0
	nimic:
		
endm


;***********************************
;***********************************************************************
;************************************************		LINIE    *****************************************
;******************************************************************************************************
make_patratel_1 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,albastrud_1 
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_1 endp

;simple macro to call the procedure easier
make_patratel_macro_1 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_1
	add esp, 12
endm 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

piesa_linie MACRO darea,x,y
   pusha
   push y
   
   make_patratel_macro_1 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_1 darea, x, y
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_1 darea, x, y
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_1 darea, x, y
   
   
   pop y
   popa

endm


piesa_linie_orz MACRO darea,x,y
   pusha
   push x
   
   make_patratel_macro_1 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_1 darea, x, y
   
   mov eax, x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_1 darea, x, y
   
   mov eax, x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_1 darea, x, y
   
   
   pop x
   popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

miscare_linie MACRO x,y
 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
  pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,60
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],1
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,395
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],1
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'; apas dreapta
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,425
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12
;piesa_goala area x, y	 
	 piesa_linie area,x,y
endm


	miscare_linie_orz MACRO x,y
 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
     pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,15
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],2
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,437; 
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],2
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'; apas dreapta
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,380
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_linie_orz area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rotire_linie MACRO	x,y  
LOCAL afisare1, afisare2,rotatie,afisare3, rotatie2, rotatie3,nimic
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_linie x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_linie_orz x,y
	jmp nimic
	afisare2:
	
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_linie x,y
	jmp nimic
	
	rotatie1:
	cmp rotatieindice,2
	jne rotatie2
	miscare_linie_orz x,y
	jmp nimic
	
	
	rotatie2:
	mov rotatieindice,0
	nimic:
		
endm

;**********************************************************************************************************
;************************************************		L_ST   *****************************************
;******************************************************************************************************

make_patratel_2 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,albastrui_2 
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_2 endp
;simple macro to call the procedure easier
make_patratel_macro_2 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_2
	add esp, 12
endm 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

piesa_L_st MACRO darea,x,y
   pusha
   push y
   
   make_patratel_macro_2 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_2 darea, x, y
   
   
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_2 darea, x, y
   
   push x
   mov eax, x
   sub eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   
   
   pop x
   pop y
   popa

endm
piesa_L_st_sus MACRO darea,x,y
   pusha
   push y
   
   make_patratel_macro_2 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
  make_patratel_macro_2 darea, x, y
   
   
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_2 darea, x, y
   pop y
     push x
   mov eax, x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   pop x
   
   popa

endm

piesa_L_st_culcat_sus MACRO darea,x,y
   pusha
   push y
    
    make_patratel_macro_2 darea, x, y
	
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
  make_patratel_macro_2 darea, x, y
   
   push x
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   
   pop x
   pop y
   popa

endm


piesa_L_st_culcat_jos MACRO darea,x,y
   pusha
   push y
    
    make_patratel_macro_2 darea, x, y
	
   mov eax, y
   sub eax,lungime_patratel
   mov y,eax
   make_patratel_macro_2 darea, x, y
   
   push x
   mov eax,x
   sub eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   
   
   mov eax,x
   sub eax,lungime_patratel
   mov x,eax
   make_patratel_macro_2 darea, x, y
   
   pop x
   pop y
   popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


miscare_L_st MACRO x,y
 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],3
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,408
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],3
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,185
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,415
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_st area,x,y
endm

miscare_L_st_sus MACRO x,y
 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],4
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,408 
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],4
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,400
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_st_sus area,x,y
endm

miscare_L_st_culcat_sus MACRO x,y
  LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],5
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,423
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],5
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,385
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_st_culcat_sus area,x,y
endm


miscare_L_st_culcat_jos MACRO x,y
 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
          pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],6
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,438
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],6
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,200
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,415
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_st_culcat_jos area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


rotire_L_st MACRO	 x,y 
LOCAL afisare1, afisare2,afisare3, rotatie,rotatie1, rotatie2, rotatie3,nimic
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_L_st_sus x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_L_st_culcat_jos x,y
	jmp nimic
	afisare2:
	cmp rotatieindice,2
	jne afisare3
	miscare_L_st x,y
	jmp nimic
	afisare3:
	miscare_L_st_culcat_sus x,y
	jmp nimic
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_L_st_culcat_jos x,y
	jmp nimic
	
	rotatie1:
	cmp rotatieindice,2
	jne rotatie2
	miscare_L_st x,y
	jmp nimic
	
	rotatie2:
	cmp rotatieindice,3
	jne rotatie3
	miscare_L_st_culcat_sus x,y
	jmp nimic
	
	rotatie3:
	mov rotatieindice,0
	nimic:
		
endm


;**********************************************************************************************************
;************************************************		L_DR   *****************************************
;******************************************************************************************************

make_patratel_3 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,portocaliu_3
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_3 endp
;simple macro to call the procedure easier
make_patratel_macro_3 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_3
	add esp, 12
endm 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


piesa_L_dr_sus MACRO darea,x,y
   pusha
   push y
   
   make_patratel_macro_3 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   sub eax,lungime_patratel
   mov y,eax
    make_patratel_macro_3 darea, x, y
   
   mov eax,y
   sub eax,lungime_patratel
   mov y,eax
    make_patratel_macro_3 darea, x, y
   
   push x
   mov eax, x
   sub eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   
   
   pop x
   pop y
   popa

endm

piesa_L_dr_culcat_sus MACRO darea,x,y
   pusha
   push y
   
    make_patratel_macro_3 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   sub eax,lungime_patratel
   mov y,eax
    make_patratel_macro_3 darea, x, y
   
   push x
   mov eax,x
   sub eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   

   mov eax, x
   sub eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   
   
   pop x
   pop y
   popa

endm

piesa_L_dr_culcat_jos MACRO darea,x,y
   pusha
   push y
   
    make_patratel_macro_3 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_3 darea, x, y
   
   push x
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   

   mov eax, x
   add eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   
   
   pop x
   pop y
   popa

endm

piesa_L_dr MACRO darea,x,y
   pusha
   push y
   
    make_patratel_macro_3 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax, y
   add eax,lungime_patratel
   mov y,eax
    make_patratel_macro_3 darea, x, y
   
   
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_3 darea, x, y
   
   push x
   mov eax, x
   add eax,lungime_patratel
   mov x,eax
    make_patratel_macro_3 darea, x, y
   
   
   pop x
   pop y
   popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

miscare_L_dr_sus MACRO x,y

LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,15    
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],7
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,438
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],7
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,185
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,415
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_dr_sus area,x,y
endm



miscare_L_dr_culcat_sus MACRO x,y

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],8
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,440
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],8
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,200
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,415
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_dr_culcat_sus area,x,y
endm

miscare_L_dr_culcat_jos MACRO x,y

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],9
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,425
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],9
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,385
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_dr_culcat_jos area,x,y
endm


miscare_L_dr MACRO x,y  

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],10
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,407
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],10
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,400
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_L_dr area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rotire_L_dr MACRO	 x,y  
LOCAL afisare1, afisare2,afisare3, rotatie,rotatie1, rotatie2, rotatie3,nimic
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_L_dr_sus x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_L_dr_culcat_jos x,y
	jmp nimic
	afisare2:
	cmp rotatieindice,2
	jne afisare3
	miscare_L_dr x,y
	jmp nimic
	afisare3:
	miscare_L_dr_culcat_sus x,y
	jmp nimic
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_L_dr_culcat_jos x,y
	jmp nimic
	
	rotatie1:
	cmp rotatieindice,2
	jne rotatie2
	miscare_L_dr x,y
	jmp nimic
	
	rotatie2:
	cmp rotatieindice,3
	jne rotatie3
	miscare_L_dr_culcat_sus x,y
	jmp nimic
	
	rotatie3:
	mov rotatieindice,0
	nimic:

endm

;**********************************************************************************************************
;************************************************		Z_DR   *****************************************
;******************************************************************************************************

make_patratel_4 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,verde_4
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_4 endp
;simple macro to call the procedure easier
make_patratel_macro_4 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_4
	add esp, 12
endm 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

piesa_Z_dr MACRO darea,x,y
  pusha
   push x
   
   make_patratel_macro_4 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_4 darea, x, y 
   
   push y
   mov eax,y
   sub eax,lungime_patratel
   mov y,eax
   make_patratel_macro_4 darea, x, y 

	
    mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_4 darea, x, y 
   
   
    pop y
    pop x
	
    popa

endm

piesa_Z_dr_sus MACRO darea,x,y 
  pusha
   push y
   
   make_patratel_macro_4 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_4 darea, x, y 
   
   push x
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_4 darea, x, y 
   
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_4 darea, x, y 
   
    pop x
   pop y

    popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

miscare_Z_dr MACRO x,y

LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,15
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],11
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,437
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],11
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,385
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_Z_dr area,x,y
endm

miscare_Z_dr_sus MACRO x,y

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],12
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,410
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],12
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,400
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_Z_dr_sus area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rotire_Z_dr MACRO	x,y  
LOCAL afisare1, afisare2,rotatie,afisare3, rotatie2, rotatie3,nimic,rotatie1
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_Z_dr x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_Z_dr_sus x,y
	jmp nimic
	afisare2:
	cmp rotatieindice,2
	jne afisare3
	miscare_Z_dr x,y
	jmp nimic
	 afisare3:

	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_Z_dr x,y
	jmp nimic
	
	rotatie1:

	
	
	rotatie3:
	mov rotatieindice,0
	nimic:
		
endm

;**********************************************************************************************************
;************************************************		Z_ST   *****************************************
;******************************************************************************************************


make_patratel_5 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,rosu_5
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_5 endp
;simple macro to call the procedure easier
make_patratel_macro_5 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_5
	add esp, 12
endm 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

piesa_Z_st MACRO darea,x,y 
  pusha
   push x
   
   make_patratel_macro_5 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_5 darea, x, y 
   
   push y
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_5 darea, x, y 
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_5 darea, x, y 
   
    pop y
   pop x

    popa

endm

piesa_Z_st_sus MACRO darea,x,y 
  pusha
   push y
   
  make_patratel_macro_5 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,y
   sub eax,lungime_patratel
   mov y,eax
   make_patratel_macro_5 darea, x, y 
   
   push x
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_5 darea, x, y 
   
   mov eax,y
   sub eax,lungime_patratel
   mov y,eax
   make_patratel_macro_5 darea, x, y 
   
    pop x
   pop y

    popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
miscare_Z_st_sus MACRO x,y
LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],13
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,440
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],13
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,400
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_Z_st_sus area,x,y
endm

miscare_Z_st MACRO x,y

  LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
  pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],14
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,425
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],14
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,400
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_Z_st area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rotire_Z_st MACRO	x,y  
LOCAL afisare1, afisare2,rotatie,afisare3, rotatie2, rotatie3,nimic,rotatie1
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_Z_st x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_Z_st_sus x,y
	jmp nimic
	afisare2:
	cmp rotatieindice,2
	jne afisare3
	miscare_Z_st x,y
	jmp nimic
	 afisare3:
	; miscare_L_st_culcat_sus
	; jmp nimic
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_Z_st x,y
	jmp nimic
	
	rotatie1:
	; cmp rotatieindice,2
	; jne rotatie2
	; miscare_L_dr_sus
	; jmp nimic
	
	
	rotatie3:
	mov rotatieindice,0
	nimic:
		
endm
;**********************************************************************************************************
;************************************************		T     *****************************************
;******************************************************************************************************

make_patratel_6 proc
	push ebp
	mov ebp, esp
	pusha

    
	lea esi,mov_6
	

draw_image:
	mov ecx, lungime_patratel
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg3] ; pointer to coordinate y
	
	add eax, lungime_patratel
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg2] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, lungime_patratel ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_patratel_6 endp
;simple macro to call the procedure easier
make_patratel_macro_6 macro drawArea, x, y,color
	push y
	push x
	push drawArea
	call make_patratel_6
	add esp, 12
endm 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;         PIESA       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
piesa_T MACRO darea,x,y 
 pusha
   push x
   
   make_patratel_macro_6 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
   
   push y
   mov eax,y
   sub eax,lungime_patratel
   mov y,eax
   make_patratel_macro_6 darea, x, y 
    pop y
	
	
	
    mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
   
    pop x
 

    popa

endm

piesa_T_jos MACRO darea,x,y 
 pusha
   push x
   
   make_patratel_macro_6 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
   
   push y
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_6 darea, x, y 
    pop y
	
	
	
    mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
   
    pop x
 

    popa

endm

piesa_T_st MACRO darea,x,y 
 pusha
   push y
   
  make_patratel_macro_6 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_6 darea, x, y 
   
   push x
   mov eax,x
   sub eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
    pop x
	
	
	
    mov eax,y
   add eax,lungime_patratel
   mov y,eax
  make_patratel_macro_6 darea, x, y 
   
    pop y
 

    popa

endm

piesa_T_dr MACRO darea,x,y 


   pusha
   push y
   
   make_patratel_macro_6 darea, x, y    ;se poate apela o data dar nu de mai multe ori
   
   mov eax,y
   add eax,lungime_patratel
   mov y,eax
   make_patratel_macro_6 darea, x, y 
   
   push x
   mov eax,x
   add eax,lungime_patratel
   mov x,eax
   make_patratel_macro_6 darea, x, y 
    pop x
	
	
	
    mov eax,y
    add eax,lungime_patratel
    mov y,eax
    make_patratel_macro_6 darea, x, y 
     pop y
	    
    popa

endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     MISCARE      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

miscare_T MACRO x,y

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],15
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,410
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],15
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,385
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_T area,x,y
endm

miscare_T_jos MACRO x,y

LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,30
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],16
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,425
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],16
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,385
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_T_jos area,x,y
endm

miscare_T_st MACRO x,y

 LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],17
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,410
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],17
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,185
	
	jle nimic
	sub x,15
	add y,10
	
	jmp nimic
	
	moveright:
	cmp x,425
	jge nimic
	add x,15
	add y,10
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_T_st area,x,y
endm

miscare_T_dr MACRO x,y

LOCAL  moveright,moveleft,nimic,verifpiesajos,nimic2,nimic3,nuschimb1
	
        pusha
	mov ecx,numarpiese
	cmp ecx,0
	je nimic3
	mov ebp,0
	verifpiesajos:
	mov eax,x
	cmp eax,[pieces.pieceXarray+ebp]
	jne nimic2
	mov ebx,y
	cmp ebx,[pieces.pieceYarray+ebp]
	jne nimic2
mov eax,numarpiese
mov esi,12
mul esi
mov ebp,eax
mov eax,x
mov [pieces.pieceXarray+ebp],eax
mov ebx,y
sub ebx,45
mov [pieces.pieceYarray+ebp],ebx
  mov [pieces.indicematrice+ebp],18
jmp schimbpiesa
	nimic2:
	dec ecx
	add ebp,12
	cmp ecx,0
	jg verifpiesajos

	popa
	nimic3:
	cmp y,410
	 jl nuschimb1
	   mov eax,x
	   mov ebp,indice
	   mov edx,y
	    mov [pieces.indicematrice+ebp],18
	   mov [pieces.pieceXarray+ebp],eax
	   mov [pieces.pieceYarray+ebp],edx
	   add ebp,12
	   mov indice,ebp
	jmp schimbpiesa
	nuschimb1:
	
	mov edx,[ebp+arg2]    
	cmp edx,'D'
	je moveright
	
    mov edx,[ebp+arg2]    
	cmp edx,'A'
	je moveleft
	
	add y,5
	jmp nimic
	
	moveleft:
	cmp x,170
	
	jle nimic
	sub x,15
	add y,3
	
	jmp nimic
	
	moveright:
	cmp x,405
	jge nimic
	add x,15
	add y,3
	 
	nimic:
	
	 mov eax, area_width
	 mov ebx, area_height
	 mul ebx
	 shl eax,2
	 push eax
     push 255
     push area
	 call memset
     add esp,12	
	 piesa_T_dr area,x,y
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      ROTIRI      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rotire_T MACRO	 x,y 
LOCAL afisare1, afisare2,rotatie,rotatie1,afisare3, rotatie2, rotatie3,nimic
	 mov edx,[ebp+arg2]    
	cmp edx,'R'
	
	je rotatie
	cmp rotatieindice,0
	jne afisare1
	miscare_T_dr x,y
	jmp nimic
	afisare1:
	cmp rotatieindice,1
	jne afisare2
	miscare_T_jos x,y
	jmp nimic
	afisare2:
	cmp rotatieindice,2
	jne afisare3
	miscare_T_st x,y
	jmp nimic
	 afisare3:
	miscare_T x,y
	jmp nimic
	
	rotatie:
	inc rotatieindice
	
	cmp rotatieindice,1
	jne rotatie1
	miscare_T_dr x,y
	jmp nimic
	
	rotatie1:
	 cmp rotatieindice,2
	jne rotatie2
 miscare_T_jos x,y
	jmp nimic
	
	rotatie2:
	cmp rotatieindice,3
	jne rotatie3
	miscare_T_st x,y
	jmp nimic
	
	rotatie3:
	mov rotatieindice,0
	miscare_T x,y
	nimic:
		
endm





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  RAAAAAANDOOOOOOOOM     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
afisarepiesamatrice macro x,y,z
local nimic,indice1,indice2,indice3,indice4,indice5,indice6,indice7
cmp z,0
jne indice2
indice1:
piesa_patrat area,x,y
jmp nimic

indice2:
cmp z,1
jne indice3
piesa_linie area,x,y
jmp nimic

indice3:
cmp z,2
jne indice4
piesa_linie_orz area,x,y
jmp nimic

indice4:
cmp z,3
jne indice5
piesa_L_st area,x,y
jmp nimic

indice5:
cmp z,4
jne indice6
piesa_L_st_sus area,x,y
jmp nimic

indice6:
cmp z,5
jne indice7
piesa_L_st_culcat_sus area,x,y
jmp nimic

indice7:
cmp z, 6
jne indice8
piesa_L_st_culcat_jos area,x,y
jmp nimic


indice8:
cmp z, 7
jne indice9
piesa_L_dr_sus area,x,y
jmp nimic

indice9:
cmp z, 8
jne indice10
piesa_L_dr_culcat_sus area,x,y
jmp nimic

indice10:
cmp z, 9
jne indice11
piesa_L_dr_culcat_jos area,x,y
jmp nimic

indice11:
cmp z, 10
jne indice12
piesa_L_dr area,x,y
jmp nimic

indice12:
cmp z, 11
jne indice13
piesa_Z_dr area,x,y
jmp nimic

indice13:
cmp z, 12
jne indice14
piesa_Z_dr_sus area,x,y
jmp nimic

indice14:
cmp z, 14
jne indice15
piesa_Z_st area,x,y
jmp nimic

indice15:
cmp z, 13
jne indice16
piesa_Z_st_sus area,x,y
jmp nimic

indice16:
cmp z, 15
jne indice17
piesa_T area,x,y
jmp nimic

indice17:
cmp z, 16
jne indice18
piesa_T_jos area,x,y
jmp nimic

indice18:
cmp z, 17
jne indice19
piesa_T_st area,x,y
jmp nimic

indice19:
cmp z, 18
jne nimic
piesa_T_dr area,x,y


nimic:
endm



afisarepiesa macro x
local nimic,indice1,indice2,indice3,indice4,indice5,indice6,indice7
cmp x,0
jne indice2
indice1:
piesa_patrat area,pozafisarex,pozafisarey
jmp nimic

indice2:
cmp x,1
jne indice3
piesa_linie area,pozafisarex,pozafisarey
jmp nimic

indice3:
cmp x,2
jne indice4
piesa_L_st area,pozafisarex,pozafisarey
jmp nimic

indice4:
cmp x,3
jne indice5
piesa_L_dr area,pozafisarex,pozafisarey
jmp nimic

indice5:
cmp x,4
jne indice6
piesa_Z_dr area,pozafisarex,pozafisarey
jmp nimic

indice6:
cmp x,5
jne indice7
piesa_Z_st area,pozafisarex,pozafisarey
jmp nimic

indice7:
piesa_T area,pozafisarex,pozafisarey
nimic:
endm


movementpiesa macro x
local nimic,indice1,indice2,indice3,indice4,indice5,indice6,indice7,nimic2
;;;;;;;;;;;;modi
cmp afisareindice,1
jne nimic2
 inc scor;
 rdtsc
 xor edx,edx
 mov ecx,10
 div ecx
 mov y,edx

 mov afisareindice,0
 
 nimic2:
 
cmp x,0
jne indice2
indice1:
rotire_patrat cordXpiece,cordYpiece
jmp nimic

indice2:
cmp x,1
jne indice3
rotire_linie cordXpiece,cordYpiece

jmp nimic

indice3:
cmp x,2
jne indice4
rotire_L_st  cordXpiece,cordYpiece
jmp nimic

indice4:
cmp x,3
jne indice5
rotire_L_dr cordXpiece,cordYpiece
jmp nimic

indice5:
cmp x,4
jne indice6
rotire_Z_dr  cordXpiece,cordYpiece
jmp nimic

indice6:
cmp x,5
jne indice7
rotire_Z_st  cordXpiece,cordYpiece
jmp nimic

indice7:
rotire_T cordXpiece,cordYpiece
jmp nimic


 
 schimbpiesa:
xor eax,eax
mov eax,numarpiese
inc eax
mov numarpiese,eax

 mov ecx,y;-------
 mov x,ecx;--------
 mov afisareindice,1
 mov cordXpiece,290
 mov cordYpiece,40
 
nimic:
 afisarepiesa y
 
 
endm

;==================================================================================================================


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	jmp afisare_litere
evt_click:
	
	jmp afisare_litere
	
evt_timer:
	inc counter
	 afisare_litere:
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
; randompiece ;---------------------------------------------------------------------------------------------------------------------------------------------------------
 makerandompieceappear:
 pusha
 movementpiesa indicerandom
 popa
 

 mov ebx,0
 mov ecx,numarpiese
 cmp ecx,0
 je final
  afisarepiese:
   cmp [pieces.pieceYarray + ebx],60;    compar piesa pt a sari la end game
   jge notendgame1
   cmp [pieces.pieceYarray + ebx],20
   jle notendgame1
	jmp endgame1   
   notendgame1:
   afisarepiesamatrice [pieces.pieceXarray + ebx],[pieces.pieceYarray + ebx],[pieces.indicematrice+ebx]; memo piesa

  
  dec ecx
  add ebx,12
  cmp ecx,0
  je final
  jmp afisarepiese
  final:


;make_background_macro area, titluw, titluh 
make_text_macro 'T', area, 10, 10
	make_text_macro 'E', area, 20, 10
	make_text_macro 'T', area, 30, 10
	make_text_macro 'R', area, 40, 10
	make_text_macro 'I', area, 50, 10
	make_text_macro 'S', area, 60, 10
	
    make_text_macro 'S', area, 10, 40
	make_text_macro 'C', area, 20, 40
	make_text_macro 'O', area, 30, 40
	make_text_macro 'R', area, 40, 40

	linie_horizontal button_x_mic, button_y_mic, button_size1_mic,100
	linie_horizontal button_x_mic, button_size2_mic+button_y_mic, button_size1_mic,100
	linie_vertical button_x_mic, button_y_mic, button_size2_mic,100
	linie_vertical button_x_mic + button_size1_mic, button_y_mic, button_size2_mic,100
	
	linie_horizontal button_x, button_y, button_size1,100
	linie_horizontal button_x, button_size2+button_y, button_size1,100
	linie_vertical button_x, button_y, button_size2,100
	linie_vertical button_x + button_size1, button_y, button_size2,100

	linie_horizontal button_x, button_y, button_size1,100
	linie_horizontal button_x, button_size2+button_y, button_size1,100
	linie_vertical button_x, button_y, button_size2,100
	linie_vertical button_x + button_size1, button_y, button_size2,100
	
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, scor
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 80, 40
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 70, 40
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 60, 40
	
	jmp final_draw
	
endgame1:
	
	;;;;DESCHID FISIERUL

push offset mode_read
push offset filename
call fopen
add esp, 8
mov f, eax

push offset scor
push offset format2
push f
call fscanf
add esp, 12

push f
call fclose
add esp, 4



push  scor
push offset format2
call printf
add esp,8
	
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	
	
	endgame2:  
	;terminarea programului
	push 0
	call exit
end start

