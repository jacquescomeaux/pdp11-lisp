read:
002000 012705 MOV #7000, R5     ; move read buffer address into R5
002002 007000
002004 105025 CLRB (R5)+        ; move null byte into buffer
loop:
002006 032737 BIT #000200, @#177560
002010 000200
002012 177560
002014 001774 BEQ loop          ; loop until char ready
002016 113701 MOVB @#177562, R1
002020 120127 CMPB R1, "\n"     ; done if enter was pressed
002022 000012
002024 001422 BEQ done
002026 120127 CMPB R1, " "      ; good if space
002030 000040
002032 001414 BEQ good
002034 120127 CMPB R1, "("      ; good if left paren
002036 000050
002040 001411 BEQ good
002042 120127 CMPB R1, ")"      ; good if right paren
002044 000051
002046 001406 BEQ good
002050 120127 CMPB R1, "A"      ; bad if lower than A
002052 000101
002054 103405 BLO bad
002056 120127 CMPB R1, "Z"      ; bad if higher than Z
002060 000132
002062 101002 BHI bad
good:
002064 110125 MOVB R1, (R5)+    ; move good char into buffer
002066 000747 BR loop           ; keep getting chars
bad:
002070 000777 BR -2             ; infinite loop
done:
002072 000137 JMP #parse_sexp
002074 002100

; R4 = sexps
parse_sexp:
002100 004737 JSR PC, #get_next       ; get a character
002102 002300
002104 120027 CMPB R0, ")"
002106 000051
002110 001020 BNE if_atom             ; if atom get the atom
; otherwise (if list)
; get the list
if_list:
002112 012704 MOV "NIL", R4           ; sexps <- empty list
002114 005000
loop:
002116 004737 JSR PC, #get_next
002120 002300
002122 120027 CMPB R0, "("
002124 000050
002126 001407 BEQ done                ; if "(" return the accumulated list
; if anything else:
002130 010446 MOV R4, -(SP)           ; push sexps
002132 004737 JSR PC, #parse_sexp     ; arg1 <- parse sexp
002134 012601 MOV (SP)+, R1           ; arg2 <- pop accum
002136 004737 JSR PC, #cons           ; cons result onto accum
002140 004400
002142 010004 MOV R0, R4              ; sexps <- result
002144 000764 BR loop                 ; continue recognizing list
done:
002146 010400 MOV R4, R0              ; result <- sexps
002150 000207 RTS PC
if_atom:
002152 105046 CLRB -(SP)    ; push null byte to stack
loop:
002154 110046 MOVB R0, -(SP)      ; push character to stack
002156 114500 MOVB -(R5), R0      ; get another character
002160 120027 CMPB R0, "A"        ;
002162 000101
002164 103404 BLO done            ; done if lower than A
002166 120027 CMPB R0, "Z"        ;
002170 000132
002172 101001 BHI done            ; done if higher than Z
002174 000767 BR loop             ; continue getting characters
done:
002176 110026 MOVB R0, (R5)+      ; put the non-letter back
002200 013702 MOV @#10000, R2     ; get free pointer
002202 010200 MOV R2, R0          ; result <- address of new atom
002204 016222 MOV 3(R2), (R2)+    ; allocate atom tag and increment free pointer
002206 000003
loop:
002210 112622 MOVB (SP)+, (R2)+   ; pop a char off the stack and into the heap
                                  ; increment the free pointer (by 1)
002212 001376 BNE loop            ; if it wasn't null keep going
002214 005722 TST (R2)+           ; align free pointer
002216 010237 MOV R2, @#10000     ; store new free pointer
002230 000207 RTS PC
get_next:
loop:
002300 114500 MOVB -(R5), R0
002302 001404 BEQ bad             ; if null byte, no more input, very bad
002304 120027 CMPB R0, " "        ; check if space
002306 000040
002310 001773 BEQ loop            ; skip space
002312 000207 RTS PC              ; return the lexically-valid character
bad:
002314 000777 BR -2               ; infinite loop
