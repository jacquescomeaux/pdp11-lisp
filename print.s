print:
004000 012704 MOV #7000, R4         ; store print buffer address in R4
004002 007000
004004 032710 BIT #1, (R0)          ; test if sexp is cons or atom
004006 000001
004010 001005 BNE 10
004012 112724 MOVB #"(", (R4)+      ; if cons output open paren
004014 000050
004016 004737 JSR PC, #handle_cons
004020 004100
004022 000402 BR 4
004024 004737 JSR PC, #handle_atom
004026 004200
004030 112724 MOVB #"\r", (R4)+     ; move carriage return into print buffer
004032 000015
004034 112724 MOVB #"\n", (R4)+     ; move line feed into print buffer
004036 000012
004040 112724 MOVB #"\0", (R4)+     ; move null byte into print buffer
004042 000000
004044 000137 JMP #print_buffer
004046 004300

handle_cons:
004100 016046 MOV 2(R0), -(SP)      ; push cdr onto stack
004102 000002
004104 011000 MOV @R0, R0           ; traverse to car
004106 032710 BIT #1, (R0)          ; test if car is cons or atom
004110 000001
004112 001005 BNE 12
004114 112724 MOVB #"(", (R4)+      ; if cons output open paren
004116 000050
004120 004737 JSR PC, #handle_cons  ; recurse
004122 004100
004124 000402 BR 4
004126 004737 JSR PC, #handle_atom  ; if atom output atom
004130 004200
004132 012600 MOV (SP)+, R0         ; pop cdr from stack
004134 032710 BIT #1, (R0)          ; test if cdr is cons or atom
004136 000001
004140 001005 BNE 12
004142 112724 MOVB #" ", (R4)+      ; if cons output space
004144 000040
004146 004737 JSR PC, #handle_cons  ; recurse
004150 004100
004152 000402 BR 4
004154 112724 MOVB #")", (R4)+      ; if atom output close paren
004156 000051
004160 000207 RTS PC

handle_atom:
004200 011000 MOV @R0, R0     ; 
004202 005300 DEC R0          ; get string address
004204 000401 BR 2            ;
004206 110124 MOVB R1, (R4)+  ; move char to print buffer
004210 112001 MOVB (R0)+, R1  ; get next byte
004212 001375 BNE -6          ; if not null continue
004214 000207 RTS PC          ;

print_buffer:
004300 012704 MOV #7000, R4       ; restore print buffer pointer
004302 007000
004304 000405 BR 12
004306 105737 TSTB @#177564       ; test if console ready
004310 177564
004312 001775 BEQ -6              ; loop while not ready
004314 110137 MOVB R1, @#177566   ; send char to console
004316 177566
004320 112401 MOVB (R4)+, R1      ; get next byte
004322 001371 BNE -14             ; if not null continue
004324 000207 RTS PC
