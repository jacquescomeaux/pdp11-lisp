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
003024 000137 JMP head_is_atom      ; branch if atom(hd)
003026 003300
; otherwise (if cons):
003030 011200 MOV @R2, R0           ; arg1 <- car(hd) = first
003032 012701 MOV "LABEL", R1       ; arg2 <- at"LABEL"
003034 005076
003036 004737 JSR PC, #eq           ; test eq(first, at"LABEL")
003040 003700
000042 001020 BNE not_label         ; branch if not label
; if is label
003044 016202 MOV 2(R2), R2         ; rest <- cdr(hd)
003046 000002
003050 016203 MOV 2(R2), R3         ; rest' <- cdr(rest)
003052 000002
; R2 = rest
; R3 = rest'
; push entry l[second, hd] onto symbol table a
; a <- cons(l[second, hd], a)
003054 011225 MOV @R2, (R5)+        ; push second (=car(rest)) onto symbol table column 0
003056 011425 MOV @R4, (R5)+        ; push hd onto symbol table column 1
; evaluate cons(third, tl) in extended environment
; R0 <- cons(third, tl)
003060 011300 MOV @R3, R0           ; arg1 <- third (=car(rest'))
003062 016401 MOV 2(R4), R1         ; arg2 <- tl = cdr(e)
003064 000002
003066 004737 JSR PC, #cons         ; result in R0
003070 004400
003072 004737 JSR PC, #eval         ; result <- eval(cons(third, tl))
003074 003000
003076 162705 SUB 4, R5             ; pop off symbol table entry
003100 000004
003102 000207 RTS PC                ; return result in R0

not_label:
; R2 = hd
003104 011200 MOV @R2, R0           ; arg1 <- car(hd) = first
003106 012701 MOV "LAMBDA", R1      ; arg2 <- at"LAMBDA"
003110 005104 
003112 004737 JSR PC, #eq           ; test eq(first, at"LAMBDA")
003114 003700
003116 001043 BNE error             ; branch if not lambda
; if is lambda
; push onto a               ; a <- append(pair(second, evlis(tl)), a)
003120 010546 MOV R5, -(SP)               ; push old symbol table pointer to stack
003122 016201 MOV 2(R2), R1               ; rest <- cdr(hd)
003124 000002
003126 011102 MOV @R1, R2                 ; symbols <- car(rest) = second
003130 016403 MOV 2(R4), R3               ; args <- tl = cdr(e)
003132 000002
003134 010146 MOV R1, -(SP)               ; save rest
; R2 = symbols
; R3 = args
evlis: (symbols, args)
003134 032712 BIT #1, (R2)                ; test if symbols is cons or atom
003136 000001
003140 001021 BNE done                    ; if its atom jump to done
; if its cons:
003142 032713 BIT #1, (R3)                ; test if args is cons or atom
003144 000001
003146 001016 BNE done                    ; if its atom jump to done
; if both are cons:
003150 011300 MOV @R3, R0                 ; arg1 <- car(args)
003152 010246 MOV R2, -(SP)               ; save symbos
003154 010346 MOV R3, -(SP)               ; save args
003156 004737 JSR PC, #eval               ; result <- eval (arg1)
003160 003000
003162 012603 MOV (SP)+, R3               ; restore args
003164 012602 MOV (SP)+, R2               ; restore symbols
; push (symbol, eval(arg))
003166 011225 MOV @R2, (R5)+              ; push symbol (=car(symbols)) to column 0
003170 010025 MOV R0, (R5)+               ; push result to column 1
003172 016202 MOV 2(R2), R2               ; args <- cdr(args)
003174 000002
003176 016303 MOV 2(R3), R3               ; symbols <- cdr(symbols)
003200 000002
003202 000754 BR -40                      ; jump to evlis(symbols, args)
done:
003204 012601 MOV (SP)+, R1               ; restore rest
; R1 = rest
003206 016101 MOV 2(R1), R1               ; rest' <- cdr(rest)
003210 000002
003212 011100 MOV @R1, R0                 ; arg1 <- third = car(rest')
003214 004737 JSR PC, #eval               ; result <- eval(third)
003216 003000
; pop off argument entries
003220 012605 MOV (SP)+, R5               ; restore symbol table pointer
003222 000207 RTS PC
error:
003224 000777 BR -2                       ; infinite loop

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
003314 003700
003316 001002 BNE next              ; skip if not quote
; return car(tl)
003320 011300 MOV @R3, R0
003322 000207 RTS PC

next:
003324 010200 MOV R2, R0            ; arg1 <- hd
003326 012701 MOV "ATOM", R1        ; arg2 <- at"ATOM"
003330 005026
003332 004737 JSR PC, #eq           ; test eq(hd, at"ATOM")
003334 003700
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
003160 000207 RTS PC
; not_atom
003362 012700 MOV "F" R0
003364 005012
003366 000207 RTS PC

next:
003370 010200 MOV R2, R0            ; arg1 <- hd
003372 012701 MOV "EQ", R1          ; arg2 <- at"EQ"
003374 005036
003376 004737 JSR PC, #eq           ; test eq(hd, at"EQ")
003400 003700
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
003440 003700
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
003470 003700
003472 001025 BNE next              ; skip if not cond
; return evcon(car(tl))
003474 011302 MOV @R3, R2           ; arg1 <- car(tl)
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
003514 004737 JSR PC, #eq           ; check if it's at"T"
003516 003700
003520 001403 BEQ is_true
; if not true
003522 016202 MOV 2(R2), R2         ; c <- cdr(c)
003524 000002
003526 000763 BR -26                ; evcon(c)
; if true
003530 011200 MOV @R2, R0           ; car(c)
003532 012700 MOV 2(R0), R0         ; cdar(c)
003534 000002
003536 011000 MOV @R0, R0           ; arg1 <- cadar(c)
003540 004737 JSR PC, #eval         ; result <- eval(cadar(c))
003542 003000
003544 000207 RTS PC

next:
003546 010200 MOV R2, R0            ; arg1 <- hd
003550 012701 MOV "CAR", R1         ; arg2 <- at"CAR"
003552 005052
003554 004737 JSR PC, #eq           ; test eq(hd, at"CAR")
003556 003700
003560 001005 BNE next              ; skip if not car
; return car(eval(car(tl)))
003562 011300 MOV @R3, R0           ; arg1 <- car(tl)
003564 004737 JSR PC, #eval         ; result <- eval(car(tl))
003566 003000
003570 011000 MOV @R0, R0           ; result <- car(result)
003572 000207 RTS PC

next:
003574 010200 MOV R2, R0            ; arg1 <- hd
003576 012701 MOV "CDR", R1         ; arg2 <- at"CDR"
003600 005062
003602 004737 JSR PC, #eq           ; test eq(hd, at"CDR")
003604 003700
003606 001006 BNE next              ; skip if not cdr
; return cdr(eval(car(tl)))
003610 011300 MOV @R3, R0           ; arg1 <- car(tl)
003612 004737 JSR PC, #eval         ; result <- eval(car(tl))
003614 003000
003616 016000 MOV 2(R0), R0         ; result <- cdr(result)
003620 000002
003622 000207 RTS PC

next:
003624 010200 MOV R2, R0            ; arg1 <- hd
003626 012701 MOV "CONS", R1        ; arg2 <- at"CONS"
003630 004737 JSR PC, #eq           ; test eq(hd, at"CONS")
003632 003700
003634 001020 BNE otherwise         ; skip if not cons
; return cons(eval(car(tl)), eval(cadr(tl)))
003636 011300 MOV @R3, R0           ; arg1 <- car(tl)
003640 010346 MOV R3, -(SP)         ; save tl
003642 004737 JSR PC, #eval         ; result <- eval(car(tl))
003644 003000
003646 012603 MOV (SP)+, R3         ; restore tl
003650 010046 MOV R0, -(SP)         ; push cons arg1
003652 016300 MOV 2(R3), R0         ; rest <- cdr(tl)
003654 000002
003656 011000 MOV @R0, R0           ; arg1 <- car(rest)
003660 004737 JSR PC, #eval         ; result <- eval(cadr(tl))
003662 003000
003664 010001 MOV R0, R1            ; arg2 <- result
003666 012600 MOV (SP)+, R0         ; pop arg1
003670 004737 JSR PC, #cons
003672 004400
003674 000207 RTS PC

otherwise:
; return eval(cons(assoc(hd), tl)))
003676 000207 RTS PC

; This one touches R0, R1
eq:
; R0 = arg1
; R1 = arg2
003700 032710 BIT #1, (R0)            ; test if arg1 is cons or atom
003700 000001
003700 001420 BEQ bad                 ; if its cons jump to error
; otherwise its atom
003700 032701 BIT #1, (R1)            ; test if arg2 is cons or atom
003710 000001
003712 001415 BEQ bad                 ; if its cons jump to error
; get the string pointers out of atoms arg1 and arg2
003714 011000 MOV @(R0), R0
003716 005300 DEC R0
003720 011101 MOV @(R1), R1
003722 005301 DEC R1
loop:
003724 121021 CMPB (R0), (R1)+        ; compare a byte from each string
                                      ; advance R1 pointer
003726 001003 BNE not_equal
; if they are equal:
003730 105720 TSTB (R0)+              ; check if null byte
                                      ; advance R0 pointer
003732 001403 BEQ done                ; if null byte, strings are equal
; otherwise, not done yet:
003734 000773 BR loop
not_equal:
; the strings are not equal
003736 000244 CLZ                     ; clear zero flag
003740 000207 RTS PC
done:
; the strings are equal
003742 000264 SEZ                     ; set zero flag
003744 000207 RTS PC
bad:
003746 000777 BR -2                   ; infinite loop

; THIS ONE TOUCHES R0, R2
cons:
; R0 = arg1
; R1 = arg2
; heap at 10000
; no garbage collection
; pretend heap is infinite
004400 013702 MOV @#010000, R2     ; get free pointer
004402 010000
004404 010012 MOV R0, @R2         ; move arg1 to car of new cons cell
004406 010162 MOV R1, 2(R2)       ; move arg2 to cdr of new cons cell
004410 000002
004412 010200 MOV R2, R0          ; result <- new cons cell
004414 062702 ADD 4, R2           ; advance free pointer
004416 000004
004420 010237 MOV R2, @#010000    ; store new free pointer
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
004504 020437 CMP R4, #10000  ; beginning of symbol table
004506 010000
004510 101411 BLOS bad        ; symbol not found
; otherwise check next row
004512 005744 TST -(R4)       ; skip column 1
004514 014401 MOV -(R4), R1   ; key <- column 0
004516 010200 MOV R2, R0      ; arg1 <- symbol
004520 004737 JSR PC, #eq     ; check if symbol equals key
004522 003700
004524 001367 BNE loop
; otherwise they are equal
004526 016400 MOV 2(R4), R0   ; result <- value
004530 000002
004532 000207 RTS PC
bad:
004534 000777 BR -2           ; infinite loop
