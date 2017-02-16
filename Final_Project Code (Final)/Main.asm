;TITLE MASM FinalProject.asm
;-------------------------------------------------------------------------
; Encryption assembler project: this project utilizes multiple encryption 
; algorithms to encrypt a user input string and displays the original
; message followed by the three encrypted strings.
;-------------------------------------------------------------------------
; Jason Pinales & Samuel Wynsma
; 12/1/2016


INCLUDE Irvine32.inc

.data
ourMessage BYTE 100 DUP(?), 0 ; original message input by user
shiftString BYTE 100 DUP(?), 0 ; String used for method 1
shiftStringKey BYTE ?
shiftStringPrompt BYTE "Shift Key: ",0

keyString DWORD 100 DUP(?), 0 ; String used for method 2
keyStringKey BYTE ?
keyStringPrompt BYTE "Private Key: ", 0

bitString BYTE 100 DUP(?), 0 ; String used for method 3

prompt BYTE "Please input a string/message you wish to encryt: ", 0
endPrompt BYTE "Your original message: ", 0
endPrompt1 BYTE "Your message after Shift Encryption: ",0
endPrompt2 BYTE "Your message after Public-key Encryption: ",0
endPrompt3 BYTE "Your message after Bitwise Encryption: ",0

; text files we will call to explain the different encryption methods
method_1 BYTE "Method_1.txt", 0
method_2 BYTE "Method_2.txt", 0
method_3 BYTE "Method_3.txt", 0

EC BYTE "EC.txt", 0
welcome BYTE "Welcome.txt", 0 
buffer BYTE 1500 DUP(?), 0

.code
main PROC

	call welcomePrompt

	; promts user for input
	mov edx, OFFSET prompt
	call WriteString ; display prompt
	call crlf
	mov edx, OFFSET ourMessage    ; Pointer to our string.
	mov ecx, LENGTHOF ourMessage
	call readString ; reads string into EDX
	call StrLength ; finds length of string
		mov ecx, eax ; copys string length into dec counter
    

	; copies string from ourMessage into shiftString, keyString
	; and bitString for editing to allow us to change them without
	; changing the original string.
	INVOKE Str_copy, 
		ADDR ourMessage, 
		ADDR shiftString 

	INVOKE Str_copy, 
		ADDR ourMessage, 
		ADDR keyString

	INVOKE Str_copy, 
		ADDR ourMessage, 
		ADDR bitString 

	call Clrscr ; clears screan

	; displays original message
	mov edx, OFFSET endPrompt
	call writeString
	call crlf
	mov edx, OFFSET ourMessage
	call writeString
	call crlf
	call crlf

	call shift ; calls function to perform Method 1
	call prKey ; calls function to perform Method 2
	call bitwise ; calls function to perform Method 3


	exit
main ENDP

; Method 1: Shift Encryption
;-----------------------------
; This shift encryption generates a random integer from 1 to 26.
; This value is then used to shift every character in the string.
; -----------------------------
shift PROC USES eax ebx ecx esi
	; generates random number from 0-24 to determine a shift key
	call Randomize
	mov eax, 25 
	call randomRange
	inc eax ; adds 1 to eax incase shift key is 0
	push eax

	mov esi, 0
	mov ebx, 26

	L1: 
		; Checks to make sure the character is a letter. Character shifting
		; will only apply to letters
		; Character is not a letter if above ASCII value is below 41h, above 5Ah & below 61h
		; or above 7Ah
		cmp shiftString[esi], 41h
		jb nonLetter ; jumps to next letter if value is below 41h
		; jump to shifting procedure after checking for a possible shift passed 'Z'
		cmp shiftString[esi], 5Ah ; if value is above 5A (= 'Z') we check to see if it is lowercase
		ja lowercase 
		add DWORD PTR shiftString[esi], eax 

		cmp shiftString[esi], 5Ah
		jle next ; no overflow
		sub DWORD PTR shiftString[esi], ebx; otherwise start letter at ASCII value 'A' and continue shift
		jmp next
		lowercase:
			cmp shiftString[esi], 7Ah 
			ja nonLetter ; jumps if value is above ASCII value of 'z'
			cmp shiftString[esi], 61h ; if not in range of lowercase letters either it is
			; not a letter
			jb nonLetter

			add DWORD PTR shiftString[esi], eax
			cmp shiftString[esi], 7Ah
			jbe next ; no overflow
			sub shiftString[esi], 26; otherwise start letter at ASCII value 'a' and continue shift

		next:
		nonLetter:
		inc esi
	loop L1

	; displays message after shift encryprion
	mov edx, OFFSET endPrompt1 ; Delivers the string to output.
	call WriteString
	call crlf

	mov edx, OFFSET shiftString ; Delivers the string to output.
	call WriteString
	call crlf

	mov edx, OFFSET shiftStringPrompt
	call WriteString
	pop eax
	call WriteInt
	call crlf
	call crlf
	ret
shift ENDP


; Method 2: Public-Key Encryption
;-----------------------------
; This is a simplified version of the typical public string encryption.
; It generates a random number, then multiplies the string by that number.
; -----------------------------
prKey PROC USES eax ecx esi edx
	
	; Public Key encryption generates a number from 1 to 255
	mov esi, 0
	mov eax, 256
	call RandomRange			; Random integer between 0 and 255
	add eax, 1					; To prevent null values
		
	L2:
				
		mul keyString[esi]		; Multiply ax and our character
		mov BYTE PTR keyString[esi], al
		inc esi
	loop L2
	
	; displays message after public-key encryprion
	mov edx, OFFSET endPrompt2 ; Delivers the string to output.
	call WriteString
	call crlf

	mov edx, OFFSET keyString ; Delivers the string to output.
	call WriteString
	call crlf

	mov edx, OFFSET keyStringPrompt
	call WriteString
	pop eax
	call WriteInt
	call crlf
	call crlf
	
	ret

prKey ENDP

; Method 3: Bitwise Encryption
;-----------------------------
; This is an improved bitwise encryption over the one from class.
; This form of encryption xors the string, then adds to it in order to avoid numerical analysis of letter frequency.
; -----------------------------
bitwise PROC USES eax ecx esi edx

	mov esi, 0
	L3:	; A combined bitwise encryption with variable addition.
		xor bitString[esi], 00010101b		; This is a bitwise xor on specific bits of our string.
		add bitString[esi], cl				; We then add the ecx value to this variable. This makes it so 
											; that the string will not follow the rule that the previous one followed
											; The main problem of frequencies is not present here without special observation.
		inc esi
	loop L3

	; displays message after bitwise encryprion
	mov edx, OFFSET endPrompt3 ; Delivers the string to output.
	call WriteString
	call crlf

	mov edx, OFFSET bitString ; Delivers the string to output.
	call WriteString
	call crlf
	call crlf
	ret
bitwise ENDP

; Welcome Prompt
;-----------------------------
; reads and outputs premade text files that prepare the user for future input
; and explains what the encrytion algorithms in use will entail 
;------------------------------
welcomePrompt PROC USES eax edx esi

	; outputs group name graphic from premade file
	mov edx, OFFSET EC
	call OpenInputFile
	mov edx, OFFSET buffer
	mov ecx, LENGTHOF buffer

	call ReadFromFile
	mov edx, OFFSET buffer
	call WriteString
	call CloseFile
	call crlf
	call WaitMsg
	call clrscr

	; clears buffer
	mov esi,0
	mov ecx, LENGTHOF buffer
	L4:
		mov buffer[esi], 0h
		inc esi
	loop L4

	; explains what this program will do
	mov edx, OFFSET welcome
	call OpenInputFile
	mov edx, OFFSET buffer
	mov ecx, LENGTHOF buffer

	call ReadFromFile
	mov edx, OFFSET buffer
	call WriteString
	call CloseFile
	call crlf
	call crlf
	call WaitMsg
	call clrscr

	; imports and displays discription for method 1 from premade text file
	mov edx, OFFSET method_1
	call OpenInputFile
	mov edx, OFFSET buffer
	mov ecx, LENGTHOF buffer

	call ReadFromFile
	mov edx, OFFSET buffer
	call WriteString
	call CloseFile
	call crlf
	call crlf
	call WaitMsg
	call clrscr

	; imports and displays discription for method 2 from premade text file
	mov edx, OFFSET method_2
	call OpenInputFile
	mov edx, OFFSET buffer
	mov ecx, LENGTHOF buffer

	call ReadFromFile
	mov edx, OFFSET buffer
	call WriteString
	call CloseFile
	call crlf
	call crlf
	call WaitMsg
	call clrscr

	; imports and displays discription for method 3 from premade text file
	mov edx, OFFSET method_3
	call OpenInputFile
	mov edx, OFFSET buffer
	mov ecx, LENGTHOF buffer

	call ReadFromFile
	mov edx, OFFSET buffer
	call WriteString
	call CloseFile
	call crlf
	call crlf
	call WaitMsg
	call clrscr

	ret
welcomePrompt ENDP
END main 