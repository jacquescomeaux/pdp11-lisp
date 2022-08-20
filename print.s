print:
004000 012705 MOV #6000, R5         ; store print buffer address in R5
004002 006000
004004 032700 BIT #1, R0            ; test if sexp is cons or atom
004006 000001
004010 001003 BNE 6
004012 004727 JSR PC, #handle_cons
004014 004100
004016 000402 BR 4
004020 004727 JSR PC, #handle_atom
004022 004200
004024 012725 MOV #"\n\0", (R5)+    ; move newline and null byte into print buffer
004026 000012
004030 000127 JMP #print_buffer
004032 004300

handle_cons:
004100 016046 MOV 2(R0), -(SP)      ; push cdr onto stack
004102 000002
004104 011000 MOV @R0, R0           ; traverse to car
004106 032700 BIT #1, R0            ; test if car is cons or atom
004110 000001
004112 001005 BNE 12
004114 112725 MOVB #"(", (R5)+      ; if cons output open paren
004116 000050
004120 004727 JSR PC, #handle_cons  ; recurse
004122 004100
004124 000402 BR 4
004126 004727 JSR PC, #handle_atom  ; if atom output atom
004130 004200
004132 012600 MOV (SP)+, R0         ; pop cdr from stack
004134 032700 BIT #1, R0            ; test if cdr is cons or atom
004136 001005 BNE 12
004140 112725 MOVB #" ", (R5)+      ; if cons output space
004142 000040
004144 004727 JSR PC, #handle_cons  ; recurse
004156 004100
004150 000402 BR 4
004152 112725 MOVB #")", (R5)+      ; if atom output close paren
004154 000051
004156 000207 RTS PC

handle_atom:
004200 000401 BR 2            ;
004202 110125 MOVB R1, (R5)+  ; move char to print buffer
004204 112001 MOVB (R0)+, R1  ; get next byte
004206 001372 BNE -6          ; if not null continue
004210 000207 RTS PC          ;

print_buffer:
004300 012705 MOV #6000, R5       ; restore print buffer pointer
004302 006000
004304 000404 BR 12
004306 105737 TSTB @#177564       ; test if console ready
004310 177564
004312 001772 BEQ -6              ; loop while not ready
004314 110137 MOVB R1, @#177566   ; send char to console
004316 177566
004320 112501 MOVB (R5)+, R1      ; get next byte
004322 001362 BNE -16             ; if not null continue
004324 000127 JMP #read (002000)
004326 002000
