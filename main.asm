[bits 16]
[org 0x7c00]

_DASTANSTART:
_DASTANSIZE equ _DASTANEND - _DASTANSTART

%define BLACK		0x0
%define BLUE		0x1
%define GREEN		0x2
%define CYAN		0x3
%define RED			0x4
%define MAGNETA		0x5
%define BROWN		0x6
%define LGREY		0x7
%define DGREY		0x8
%define LBLUE		0x9
%define LGREEN		0xA
%define LCYAN		0xB
%define LRED		0xC
%define LMAGENTA	0xD
%define YELLOW		0xE
%define WHITE		0xF

%define Colour(back,fore) (((back)*16)+(fore))

; ; (char, colour)
; %macro printColourChar 2
; 	push ax
; 	mov ax, 0xB800
; 	mov es, ax
; 	mov ah, 0
; 	mov al, [TTY.Y]
; 	mul TTYMaxCols
; 	add al, TTY.X
; 	mov di, ax
; 	mov ah, %2
; 	mov al, %1
; 	mov word es:[di], ax
; 	pop ax
; %endmacro

%macro printColourChar 2 ; (char, colour)
	push ax
	push bx
	push cx

	mov cx, 1
	mov bh, 0
	mov bl, %2
	mov al, %1
	mov ah, 0x09
	int 0x10									; print the character with the given colour data

	mov ah, 0x0E
	int 0x10									; above interrupt doesn't move the cursor

	pop cx
	pop bx
	pop ax
%endmacro

%macro printNewLine 0
	push ax

	mov ah, 0x0E
	mov al, 13
	int 0x10
	mov al, 10
	int 0x10

	pop ax
%endmacro

loader:
	mov [bootdisk], dl

	xor ax, ax
	mov es, ax
	mov ds, ax
	mov bp, 0x1000
	mov sp, bp

	mov bx, main
	mov dh, 2

	mov ah, (_DASTANSIZE / 512) + 1
	mov al, dh
	mov ch, 0x00
	mov dh, 0x00
	mov cl, 0x02
	mov dl, [bootdisk]
	int 0x13									; loads sectors into memory

	cld											; clear direction flag
	mov ax, 0x03								; 80x25 16-colour TTY mode
	int 0x10

	mov ah, 0x01								; hide the cursor
	mov ch, 0b00100000
	int 0x10

	jmp main

bootdisk: db 0

board:
	; POV: you're doing surgery in the dark - Kamran Jones
	; 00 10 00 00	 (the only reason we have 1 set here is so we can easily write the board in)
	;     -       => kotla flag
	;           - => kotla owner (0,1)
	;          -  => piece owner (0,1)
	;        -    => square occupied flag
	;       -     => nature of piece (0 = normal, 1 = mirza)
	db "   ?  "
	db " &&&& "
	db "      "
	db "      "
	db " $$$$ "
	db "  <   "

%define TTYMaxRows 25
%define TTYMaxCols 80
TTY.X:
	db 0
TTY.Y:
	db 0

printBoard:
	push ax
	push bx
	mov al, "6"
	mov bx, 0									; stores linear board offset
	printBoard.rows:
		mov ah, 0x0E
		cmp al, "0"
		je printBoard.end						; row 0 => write the letters
		int 0x10
		dec al
		mov dl, 0								; current column
		mov ah, 0								; free to use for colour
		printBoard.rows.loop:
			cmp dl, 6
			je printBoard.rows.rowEnd
			mov dh, [bx+board]					; access the required bit
			inc dl
			inc bx
			test dh, 0b00010000					; test if kotla
			jz printBoard.notKotla
			printBoard.Kotla:
				test dh, 0b00000001				; test which player the kotla belongs to
				jnz printBoard.Kotla.P1
				printBoard.Kotla.P0:
					mov ah, RED*16				; set to red background (P0 kotla)
					jmp printBoard.getPiece
				printBoard.Kotla.P1:
					mov ah, BLUE*16				; set to blue background (P1 kotla)
					jmp printBoard.getPiece
			printBoard.notKotla:
				mov ah, DGREY*16				; set to dark grey background (not a kotla)
				jmp printBoard.getPiece
			
			printBoard.getPiece:
				test dh, 0b00000100				; test if the square is occupied
				jz printBoard.printSquareWithoutPiece
				test dh, 0b00000010				; see which player occupies this square
				jnz printBoard.squareOccupiedP1
				printBoard.squareOccupiedP0:
					test dh, 0b00001000			; determine nature of piece
					jnz printBoard.squareOccupiedP0Mirza
					printBoard.squareOccupiedP0Normal:
						or ah, LGREY
						jmp printBoard.printSquareWithPiece
					printBoard.squareOccupiedP0Mirza:
						or ah, GREEN
						jmp printBoard.printSquareWithPiece
				printBoard.squareOccupiedP1:
					test dh, 0b00001000			; determine nature of piece
					jnz printBoard.squareOccupiedP1Mirza
					printBoard.squareOccupiedP1Normal:
						or ah, WHITE
						jmp printBoard.printSquareWithPiece
					printBoard.squareOccupiedP1Mirza:
						or ah, YELLOW
						jmp printBoard.printSquareWithPiece

			printBoard.printSquareWithoutPiece:
				printColourChar " ", ah
				jmp printBoard.rows.loop

			printBoard.printSquareWithPiece:
				printColourChar "*", ah
				jmp printBoard.rows.loop

		printBoard.rows.rowEnd:
			printNewLine
			jmp printBoard.rows
	
	printBoard.end:
		mov ah, 0x0E
		mov al, " "
		int 0x10
		%assign c "a"
		%rep 6
		mov al, c
		int 0x10
		%assign c c+1
		%endrep
	
	pop bx
	pop ax
	ret

times 510-($-$$) db 0x00
dw 0xAA55

main:
	call printBoard
	jmp $

_DASTANEND: