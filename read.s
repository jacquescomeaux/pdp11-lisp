read:
MOV #7000, R5     ; move read buffer address into R5
; populate read buffer with console input until enter key is pressed
; filter out bad characters here.
; increment R5 along the way.
; and start with null byte.
; what we are left with is just (, ), A-Z, and space
JSR PC, #parse_sexp
JMP #eval

; R4 = sexps

parse_sexp:
JSR PC, #get_next       ; get a character
CMPB R0, ")"
BNE if_atom             ; if atom get the atom
; otherwise (if list)
; get the list
if_list:
MOV "NIL", R4           ; sexps <- empty list
loop:
JSR PC, #get_next
CMPB R0, "("
BEQ done                ; if "(" return the accumulated list
; if anything else:
MOV R4, -(SP)           ; push sexps
JSR PC, #parse_sexp     ; arg1 <- parse sexp
MOV (SP)+, R1           ; arg2 <- pop accum
JSR PC, #cons           ; cons result onto accum
MOV R0, R4              ; sexps <- result
BR -???                 ; continue recognizing list
done:
MOV R4, R0              ; result <- sexps
RTS PC
if_atom:
MOVB "\0", -(SP)    ; push null byte to stack
loop:
MOVB R0, -(SP)      ; push character to stack ;
MOVB -(R5), R0      ; get another character
CMPB R0, "A"        ;
BLO done            ; done if lower than A
CMPB R0, "Z"        ;
BHI done            ; done if higher than Z
BR -???             ; continue getting characters
done:
MOVB R0, (R5)+      ; put the non-letter back
MOV @#10000, R2     ; get free pointer
MOV R2, R0          ; result <- address of new atom
MOV 3(R2), (R2)+    ; allocate atom tag and increment free pointer
MOVB (SP)+, (R2)+   ; pop a char off the stack and into the heap ; increment the free pointer (by 1)
BNE -4              ; if it wasn't null keep going
TST (R2)+           ; align free pointer
MOV R2, @#10000     ; store new free pointer
RTS PC

get_next:
loop:
MOVB -(R5), R0 
BEQ bad             ; if null byte, no more input, very bad
CMPB R0, " "        ; check if space
BEQ loop            ; skip space
RTS PC              ; return the lexically-valid character
bad:
BR -2               ; infinite loop
