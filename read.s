read:
002000 012704 MOV #7000, R4       ; move read buffer address into R4
002002 007000
002004 105024 CLRB (R4)+          ; move null byte into buffer
get:
002006 032737 BIT #200, @#177560
002010 000200
002012 177560
002014 001774 BEQ get             ; loop until char ready
002016 113701 MOVB @#177562, R1   ; get the char
002020 177562
002022 120127 CMPB R1, "DEL"      ; delete char if backspace was pressed
002024 000177
002026 001004 BNE not_backspace
002030 005304 DEC R4              ; decrement buffer pointer
002032 004737 JSR PC, @backspace  ; send backspace char
002034 002144
002036 000763 BR get              ; keep getting chars
not_backspace:
002040 120127 CMPB R1, "\r"       ; done if enter was pressed
002042 000015
002044 001424 BEQ done
002046 120127 CMPB R1, " "        ; good if space
002050 000040
002052 001414 BEQ good
002054 120127 CMPB R1, "("        ; good if left paren
002056 000050
002060 001411 BEQ good
002062 120127 CMPB R1, ")"        ; good if right paren
002064 000051
002066 001406 BEQ good
002070 120127 CMPB R1, "A"        ; bad if lower than A
002072 000101
002074 103407 BLO bad
002076 120127 CMPB R1, "Z"        ; bad if higher than Z
002100 000132
002102 101004 BHI bad
good:
002104 110124 MOVB R1, (R4)+      ; move good char into buffer
002106 004737 JSR PC, @print_char ; echo good char
002110 002150
002112 000735 BR get              ; keep getting chars
bad:
002114 000734 BR get              ; ignore bad chars
done:
002116 112701 MOVB "\r", R1       ; send carriage return
002120 000015
002122 004737 JSR PC, @print_char
002124 002150
002126 112701 MOVB "\n", R1       ; send line feed
002130 000012
002132 004737 JSR PC, @print_char
002134 002150
002136 000137 JMP @parse_sexp
002140 002200

backspace:
002144 112701 MOVB "\b", R1
002146 000010
print_char:
002150 032737 BIT #200, @#177654
002152 000200
002154 177564
002156 001774 BEQ print_char
002160 110137 MOVB R1, @#177566
002162 177566
002164 000207 RTS PC

; R3 = sexps
parse_sexp:
002200 004737 JSR PC, #get_next       ; get a character
002202 002400
002204 120027 CMPB R0, ")"
002206 000051
002210 001022 BNE if_atom             ; if atom get the atom
; otherwise (if list)
; get the list
if_list:
002212 012703 MOV "NIL", R3           ; sexps <- empty list
002214 005000
loop:
002216 004737 JSR PC, #get_next
002220 002400
002222 120027 CMPB R0, "("
002224 000050
002226 001411 BEQ done                ; if "(" return the accumulated list
; if anything else:
002230 110024 MOVB R0, (R4)+          ; put back the char
002232 010346 MOV R3, -(SP)           ; push sexps
002234 004737 JSR PC, #parse_sexp     ; arg1 <- parse sexp
002236 002200
002240 012601 MOV (SP)+, R1           ; arg2 <- pop accum
002142 004737 JSR PC, #cons           ; cons result onto accum
002244 004400
002246 010003 MOV R0, R3              ; sexps <- result
002250 000762 BR loop                 ; continue recognizing list
done:
002252 010300 MOV R3, R0              ; result <- sexps
002254 000207 RTS PC
if_atom:
002256 105046 CLRB -(SP)    ; push null byte to stack
loop:
002260 110046 MOVB R0, -(SP)      ; push character to stack
002262 114400 MOVB -(R4), R0      ; get another character
002264 120027 CMPB R0, "A"        ;
002266 000101
002270 103404 BLO done            ; done if lower than A
002272 120027 CMPB R0, "Z"        ;
002274 000132
002276 101001 BHI done            ; done if higher than Z
002300 000767 BR loop             ; continue getting characters
done:
002302 110024 MOVB R0, (R4)+      ; put the non-letter back
002304 013702 MOV @#10000, R2     ; get free pointer
002306 010000
002310 010200 MOV R2, R0          ; result <- address of new atom
002312 010203 MOV R2, R3
002314 062703 ADD #3, R3
002316 000003
002320 010322 MOV R3, (R2)+       ; allocate atom tag and increment free pointer
loop:
002322 112622 MOVB (SP)+, (R2)+   ; pop a char off the stack and into the heap
                                  ; increment the free pointer (by 1)
002324 001376 BNE loop            ; if it wasn't null keep going
002326 005202 INC R2              ; align free pointer
002330 042702 BIC #1, R2
002332 000001
002334 010237 MOV R2, @#10000     ; store new free pointer
002336 010000
002340 000207 RTS PC

get_next:
loop:
002400 114400 MOVB -(R4), R0
002402 001404 BEQ bad             ; if null byte, no more input, very bad
002404 120027 CMPB R0, " "        ; check if space
002406 000040
002410 001773 BEQ loop            ; skip space
002412 000207 RTS PC              ; return the lexically-valid character
bad:
002414 000777 BR -2               ; infinite loop
