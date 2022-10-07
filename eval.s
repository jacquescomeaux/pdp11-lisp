R0 has e (s-exp to be evaluated)
a (the environment / symbol table) at a known location

; e to be evaluated in R0
; result of evaluation in R0
eval: (e) =
003000 032710 BIT #1, (R0)          ; test if e is cons or atom
003002 000001
003004 001403 BEQ not_atom          ; branch if not atom(e)
003006 004737 JSR PC, #assoc        ; return assoc(e)
003010 004500
003012 000207 RTS PC
not_atom:
; R7 = PC
; R6 = SP
; R5 = a (symbol table)
; R4 = e (original sexp)
; R3 = args = tl = cdr(e)
; R2 = hd, symbols = second = car(cdr(hd))
; R1 = arg2
; R0 = arg1, result
003014 010004 MOV R0, R4            ; save e
003016 011402 MOV @R4, R2           ; hd <- car(e)
003020 032712 BIT #1, (R2)          ; test if hd is cons or atom
003022 000001
003024 001402 BEQ 4                 ; branch if cons
003026 000137 JMP head_is_atom      ; jump if atom(hd)
003030 003300
; otherwise (if cons):
003032 011200 MOV @R2, R0           ; arg1 <- car(hd) = first
003034 012701 MOV "LABEL", R1       ; arg2 <- at"LABEL"
003036 005100
003040 004737 JSR PC, #eq           ; test eq(first, at"LABEL")
003042 004600
003044 001020 BNE not_label         ; branch if not label
; if is label
003046 016202 MOV 2(R2), R2         ; rest <- cdr(hd)
003050 000002
003052 016203 MOV 2(R2), R3         ; rest' <- cdr(rest)
003054 000002
; R2 = rest
; R3 = rest'
; push entry l[second, hd] onto symbol table a
; a <- cons(l[second, hd], a)
003056 011225 MOV @R2, (R5)+        ; push second (=car(rest)) onto symbol table column 0
003060 011425 MOV @R4, (R5)+        ; push hd onto symbol table column 1
; evaluate cons(third, tl) in extended environment
; R0 <- cons(third, tl)
003062 011300 MOV @R3, R0           ; arg1 <- third (=car(rest'))
003064 016401 MOV 2(R4), R1         ; arg2 <- tl = cdr(e)
003066 000002
003070 004737 JSR PC, #cons         ; result in R0
003072 004400
003074 004737 JSR PC, #eval         ; result <- eval(cons(third, tl))
003076 003000
003100 162705 SUB 4, R5             ; pop off symbol table entry
003102 000004
003104 000207 RTS PC                ; return result in R0

not_label:
; R2 = hd
003106 011200 MOV @R2, R0           ; arg1 <- car(hd) = first
003110 012701 MOV "LAMBDA", R1      ; arg2 <- at"LAMBDA"
003112 005110
003114 004737 JSR PC, #eq           ; test eq(first, at"LAMBDA")
003116 004600
003120 001043 BNE error             ; branch if not lambda
; if is lambda
; push onto a               ; a <- append(pair(second, evlis(tl)), a)
003122 010546 MOV R5, -(SP)               ; push old symbol table pointer to stack
003124 016201 MOV 2(R2), R1               ; rest <- cdr(hd)
003126 000002
003130 011102 MOV @R1, R2                 ; symbols <- car(rest) = second
003132 016403 MOV 2(R4), R3               ; args <- tl = cdr(e)
003134 000002
003136 010146 MOV R1, -(SP)               ; save rest
; R2 = symbols
; R3 = args
evlis: (symbols, args)
003140 032712 BIT #1, (R2)                ; test if symbols is cons or atom
003142 000001
003144 001021 BNE done                    ; if its atom jump to done
; if its cons:
003146 032713 BIT #1, (R3)                ; test if args is cons or atom
003150 000001
003152 001016 BNE done                    ; if its atom jump to done
; if both are cons:
003154 011300 MOV @R3, R0                 ; arg1 <- car(args)
003156 010246 MOV R2, -(SP)               ; save symbos
003160 010346 MOV R3, -(SP)               ; save args
003162 004737 JSR PC, #eval               ; result <- eval (arg1)
003164 003000
003166 012603 MOV (SP)+, R3               ; restore args
003170 012602 MOV (SP)+, R2               ; restore symbols
; push (symbol, eval(arg))
003172 011225 MOV @R2, (R5)+              ; push symbol (=car(symbols)) to column 0
003174 010025 MOV R0, (R5)+               ; push result to column 1
003176 016202 MOV 2(R2), R2               ; args <- cdr(args)
003200 000002
003202 016303 MOV 2(R3), R3               ; symbols <- cdr(symbols)
003204 000002
003206 000754 BR evlis                    ; jump to evlis(symbols, args)
done:
003210 012601 MOV (SP)+, R1               ; restore rest
; R1 = rest
003212 016101 MOV 2(R1), R1               ; rest' <- cdr(rest)
003214 000002
003216 011100 MOV @R1, R0                 ; arg1 <- third = car(rest')
003220 004737 JSR PC, #eval               ; result <- eval(third)
003222 003000
; pop off argument entries
003224 012605 MOV (SP)+, R5               ; restore symbol table pointer
003226 000207 RTS PC
error:
003230 000777 BR -2                       ; infinite loop

head_is_atom:
; R2 = hd
; R3 = tl
; R4 = e
003300 016403 MOV 2(R4), R3         ; tl <- cdr(e)
003302 000002
003304 010200 MOV R2, R0            ; arg1 <- hd
003306 012701 MOV "QUOTE", R1       ; arg2 <- at"QUOTE"
003310 005016
003312 004737 JSR PC, #eq           ; test eq(hd, at"QUOTE")
003314 004600
003316 001002 BNE next              ; skip if not quote
; return car(tl)
003320 011300 MOV @R3, R0
003322 000207 RTS PC

next:
003324 010200 MOV R2, R0            ; arg1 <- hd
003326 012701 MOV "ATOM", R1        ; arg2 <- at"ATOM"
003330 005026
003332 004737 JSR PC, #eq           ; test eq(hd, at"ATOM")
003334 004600
003336 001014 BNE next              ; skip if not atom
; return atom(eval(car(tl)))
003340 011300 MOV @R3, R0           ; arg1 <- car(tl)
003342 004737 JSR PC, #eval         ; result <- eval(car(tl))
003344 003000
003346 032710 BIT #1, (R0)          ; test if e is cons or atom
003350 000001
003352 001403 BEQ not_atom          ; branch if not atom
; is atom
003354 012700 MOV "T" R0
003356 005006
003360 000207 RTS PC
; not_atom
003362 012700 MOV "F" R0
003364 005012
003366 000207 RTS PC

next:
003370 010200 MOV R2, R0            ; arg1 <- hd
003372 012701 MOV "EQ", R1          ; arg2 <- at"EQ"
003374 005036
003376 004737 JSR PC, #eq           ; test eq(hd, at"EQ")
003400 004600
003402 001026 BNE next              ; skip if not eq
; return eq(eval(car(tl)), eval(cadr(tl)))
003404 011300 MOV @R3, R0           ; arg1 <- car(tl)
003406 010346 MOV R3, -(SP)         ; save tl
003410 004737 JSR PC, #eval         ; result <- eval(car(tl))
003412 003000
003414 012603 MOV (SP)+, R3         ; restore tl
003416 010046 MOV R0, -(SP)         ; push eq arg1 = result
003420 016300 MOV 2(R3), R0         ; rest <- cdr(tl)
003422 000002
003424 011000 MOV @R0, R0           ; arg1 <- car(rest)
003426 004737 JSR PC, #eval         ; result <- eval(cadr(tl))
003430 003000
003432 010001 MOV R0, R1            ; arg2 <- result
003134 012600 MOV (SP)+, R0         ; pop arg1
003436 004737 JSR PC, #eq           ; test if equal
003440 004600
003442 001003 BNE not_eq
; eq
003444 012700 MOV "T" R0
003446 005006
003450 000207 RTS PC
; not_eq
003452 012700 MOV "F" R0
003454 005012
003456 000207 RTS PC

next:
003460 010200 MOV R2, R0            ; arg1 <- hd
003462 012701 MOV "COND", R1        ; arg2 <- at"COND"
003464 005044
003466 004737 JSR PC, #eq           ; test eq(hd, at"COND")
003470 004600
003472 001026 BNE next              ; skip if not cond
; return evcon(tl)
00474 010302 MOV R3, R2            ; c <- tl
evcon:
; R1 = arg1 = at"T"
; R2 = c
003476 011200 MOV @R2, R0           ; car(c)
003500 011000 MOV @R0, R0           ; arg1 <- caar(c)
003502 010246 MOV R2, -(SP)         ; save c
003504 004737 JSR PC, #eval         ; arg1 <- eval(caar(c))
003506 003000
003510 012602 MOV (SP)+, R2         ; restore c
003512 012701 MOV "T" R1            ; arg2 <- at"T"
003514 005006
003516 004737 JSR PC, #eq           ; check if it's at"T"
003520 004600
003522 001403 BEQ is_true
; if not true
003524 016202 MOV 2(R2), R2         ; c <- cdr(c)
003526 000002
003530 000762 BR evcon              ; evcon(c)
; if true
003532 011200 MOV @R2, R0           ; car(c)
003534 016000 MOV 2(R0), R0         ; cdar(c)
003536 000002
003540 011000 MOV @R0, R0           ; arg1 <- cadar(c)
003542 004737 JSR PC, #eval         ; result <- eval(cadar(c))
003544 003000
003546 000207 RTS PC

next:
003550 010200 MOV R2, R0            ; arg1 <- hd
003552 012701 MOV "CAR", R1         ; arg2 <- at"CAR"
003554 005054
003556 004737 JSR PC, #eq           ; test eq(hd, at"CAR")
003560 004600
003562 001005 BNE next              ; skip if not car
; return car(eval(car(tl)))
003564 011300 MOV @R3, R0           ; arg1 <- car(tl)
003566 004737 JSR PC, #eval         ; result <- eval(car(tl))
003570 003000
003572 011000 MOV @R0, R0           ; result <- car(result)
003574 000207 RTS PC

next:
003576 010200 MOV R2, R0            ; arg1 <- hd
003600 012701 MOV "CDR", R1         ; arg2 <- at"CDR"
003602 005062
003604 004737 JSR PC, #eq           ; test eq(hd, at"CDR")
003606 004600
003610 001006 BNE next              ; skip if not cdr
; return cdr(eval(car(tl)))
003612 011300 MOV @R3, R0           ; arg1 <- car(tl)
003614 004737 JSR PC, #eval         ; result <- eval(car(tl))
003616 003000
003620 016000 MOV 2(R0), R0         ; result <- cdr(result)
003622 000002
003624 000207 RTS PC

next:
003626 010200 MOV R2, R0            ; arg1 <- hd
003630 012701 MOV "CONS", R1        ; arg2 <- at"CONS"
003632 005070
003634 004737 JSR PC, #eq           ; test eq(hd, at"CONS")
003636 004600
003640 001020 BNE otherwise         ; skip if not cons
; return cons(eval(car(tl)), eval(cadr(tl)))
003642 011300 MOV @R3, R0           ; arg1 <- car(tl)
003644 010346 MOV R3, -(SP)         ; save tl
003646 004737 JSR PC, #eval         ; result <- eval(car(tl))
003650 003000
003652 012603 MOV (SP)+, R3         ; restore tl
003654 010046 MOV R0, -(SP)         ; push cons arg1
003656 016300 MOV 2(R3), R0         ; rest <- cdr(tl)
003660 000002
003662 011000 MOV @R0, R0           ; arg1 <- car(rest)
003664 004737 JSR PC, #eval         ; result <- eval(cadr(tl))
003666 003000
003670 010001 MOV R0, R1            ; arg2 <- result
003672 012600 MOV (SP)+, R0         ; pop arg1
003674 004737 JSR PC, #cons
003676 004400
003700 000207 RTS PC

otherwise:
; return eval(cons(assoc(hd), tl))
003702 010200 MOV R2, R0            ; arg <- hd
003704 004737 JSR PC, #assoc        ; arg1 <- assoc(hd)
003706 004500
003710 010301 MOV R3, R1            ; arg2 <- tl
003712 004737 JSR PC, #cons         ; arg <- cons(assoc(hd), tl)
003714 004400
003716 004737 JSR PC, #eval         ; result <- eval(arg)
003720 003000
003722 000207 RTS PC

; This one touches R0, R1
eq:
; R0 = arg1
; R1 = arg2
004600 032710 BIT #1, (R0)            ; test if arg1 is cons or atom
004602 000001
004604 001420 BEQ bad                 ; if its cons jump to error
; otherwise its atom
004606 032711 BIT #1, (R1)            ; test if arg2 is cons or atom
004610 000001
004612 001415 BEQ bad                 ; if its cons jump to error
; get the string pointers out of atoms arg1 and arg2
004614 011000 MOV @(R0), R0
004616 005300 DEC R0
004620 011101 MOV @(R1), R1
004622 005301 DEC R1
loop:
004624 121021 CMPB (R0), (R1)+        ; compare a byte from each string
                                      ; advance R1 pointer
004626 001003 BNE not_equal
; if they are equal:
004630 105720 TSTB (R0)+              ; check if null byte
                                      ; advance R0 pointer
004632 001403 BEQ done                ; if null byte, strings are equal
; otherwise, not done yet:
004634 000773 BR loop
not_equal:
; the strings are not equal
004636 000244 CLZ                     ; clear zero flag
004640 000207 RTS PC
done:
; the strings are equal
004642 000264 SEZ                     ; set zero flag
004644 000207 RTS PC
bad:
004646 000777 BR -2                   ; infinite loop

; THIS ONE TOUCHES R0, R2
cons:
; R0 = arg1
; R1 = arg2
; heap at 10000
; no garbage collection
; pretend heap is infinite
004400 013702 MOV @#10000, R2     ; get free pointer
004402 010000
004404 010012 MOV R0, @R2         ; move arg1 to car of new cons cell
004406 010162 MOV R1, 2(R2)       ; move arg2 to cdr of new cons cell
004410 000002
004412 010200 MOV R2, R0          ; result <- new cons cell
004414 062702 ADD 4, R2           ; advance free pointer
004416 000004
004420 010237 MOV R2, @#10000    ; store new free pointer
004422 010000
004424 000207 RTS PC

; This one touches R0, R1, R2, R4
assoc:
004500 010504 MOV R5, R4
004502 010002 MOV R0, R2
; R1 = key
; R2 = symbol
; R4 = symbol table pointer
loop:
004504 020427 CMP R4, #6000  ; beginning of symbol table
004506 006000
004510 101411 BLOS bad        ; symbol not found
; otherwise check next row
004512 005744 TST -(R4)       ; skip column 1
004514 014401 MOV -(R4), R1   ; key <- column 0
004516 010200 MOV R2, R0      ; arg1 <- symbol
004520 004737 JSR PC, #eq     ; check if symbol equals key
004522 004600
004524 001367 BNE loop
; otherwise they are equal
004526 016400 MOV 2(R4), R0   ; result <- value
004530 000002
004532 000207 RTS PC
bad:
004534 000777 BR -2           ; infinite loop
