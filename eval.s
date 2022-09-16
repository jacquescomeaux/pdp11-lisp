R0 has e (s-exp to be evaluated)
a (the environment / symbol table) at a known location

; e to be evaluated in R0
; result of evaluation in R0
eval: (e) =
  BIT #1, (R0)          ; test if e is cons or atom
  BEQ not_atom          ; branch if not atom(e)
  JSR PC, #assoc        ; return assoc(e)
  RTS PC
not_atom:
  ; R7 = PC
  ; R6 = SP
  ; R5 = a (symbol table)
  ; R4 = e (original sexp)
  ; R3 = args = tl = cdr(e)
  ; R2 = hd, symbols = second = car(cdr(hd))
  ; R1 = arg2
  ; R0 = arg1, result
  MOV R0, R4            ; save e
  MOV @R4, R2           ; hd <- car(e)
  BIT #1, (R2)          ; test if hd is cons or atom
  BNE head_is_atom      ; branch if atom(hd)
  ;otherwise (if cons):
  MOV @R2, R0           ; arg1 <- car(hd) = first
  MOV "LABEL", R1       ; arg2 <- at"LABEL"
  JSR PC, #eq           ; test eq(first, at"LABEL")
  BNE not_label         ; branch if not label
  ; if is label
  MOV 2(R2), R2         ; rest <- cdr(hd)
  MOV 2(R2), R3         ; rest' <- cdr(rest)
  ; R2 = rest
  ; R3 = rest'
  ; push entry l[second, hd] onto symbol table a
  ; a <- cons(l[second, hd], a)
  MOV @R2, (R5)+        ; push second (=car(rest)) onto symbol table column 0
  MOV @R4, (R5)+        ; push hd onto symbol table column 1
  ; evaluate cons(third, tl) in extended environment
  ; R0 <- cons(third, tl)
  MOV @R3, R0           ; arg1 <- third (=car(rest'))
  MOV 2(R4), R1         ; arg2 <- tl = cdr(e)
  JSR PC, #cons         ; result in R0
  JSR PC, #eval         ; result <- eval(cons(third, tl))
  SUB 4, R5             ; pop off symbol table entry
  RTS PC                ; return result in R0

not_label:
  ; R2 = hd
  MOV @R2, R0           ; arg1 <- car(hd) = first
  MOV "LAMBDA", R1      ; arg2 <- at"LAMBDA"
  JSR PC, #eq           ; test eq(first, at"LAMBDA")
  BNE error             ; branch if not lambda
  ; if is lambda
  ; push onto a               ; a <- append(pair(second, evlis(tl)), a)
  MOV R5, -(SP)               ; push old symbol table pointer to stack
  MOV 2(R2), R1               ; rest <- cdr(hd)
  MOV @R1, R2                 ; symbols <- car(rest) = second
  MOV 2(R4), R3               ; args <- tl = cdr(e)
  MOV R1, -(SP)               ; save rest
  ; R2 = symbols
  ; R3 = args
  evlis: (symbols, args)
  BIT #1, (R2)                ; test if symbols is cons or atom
  BNE done                    ; if its atom jump to done
  ; if its cons:
  BIT #1, (R3)                ; test if args is cons or atom
  BNE done                    ; if its atom jump to done
  ; if both are cons:
  MOV @R3, R0                 ; arg1 <- car(args)
  MOV R2, -(SP)               ; save symbos
  MOV R3, -(SP)               ; save args
  JSR PC, #eval               ; result <- eval (arg1)
  MOV (SP)+, R3               ; restore args
  MOV (SP)+, R2               ; restore symbols
  ; push (symbol, eval(arg))
  MOV @R2, (R5)+              ; push symbol (=car(symbols)) to column 0
  MOV R0, (R5)+               ; push result to column 1
  MOV 2(R2), R2               ; args <- cdr(args)
  MOV 2(R3), R3               ; symbols <- cdr(symbols)
  BR -???                     ; jump to evlis(symbols, args)
  done:
  MOV (SP)+, R1               ; restore rest
  ; R1 = rest
  MOV 2(R1), R1               ; rest' <- cdr(rest)
  MOV @R1, R0                 ; arg1 <- third = car(rest')
  JSR PC, #eval               ; result <- eval(third)
  ; pop off argument entries
  MOV (SP)+, R5               ; restore symbol table pointer
  RTS PC
error:
  BR -2                       ; infinite loop

head_is_atom:
  ; R2 = hd
  ; R3 = tl
  ; R4 = e
  MOV 2(R4), R3         ; tl <- cdr(e)
  MOV R2, R0            ; arg1 <- hd
  MOV "QUOTE", R1       ; arg2 <- at"QUOTE"
  JSR PC, #eq           ; test eq(hd, at"QUOTE")
  BNE next              ; skip if not quote
  ; return car(tl)
  MOV @R3, R0
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "ATOM", R1        ; arg2 <- at"ATOM"
  JSR PC, #eq           ; test eq(hd, at"ATOM")
  BNE next              ; skip if not atom
  ; return atom(eval(car(tl)))
  MOV @R3, R0           ; arg1 <- car(tl)
  JSR PC, #eval         ; result <- eval(car(tl))
  BIT #1, (R0)          ; test if e is cons or atom
  BEQ not_atom          ; branch if not atom
  ; is atom
  MOV "T" R0
  BR return
  ; not_atom
  MOV "F" R0
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "EQ", R1          ; arg2 <- at"EQ"
  JSR PC, #eq           ; test eq(hd, at"EQ")
  BNE next              ; skip if not eq
  ; return eq(eval(car(tl)), eval(cadr(tl)))
  MOV @R3, R0           ; arg1 <- car(tl)
  MOV R3, -(SP)         ; save tl
  JSR PC, #eval         ; result <- eval(car(tl))
  MOV (SP)+, R3         ; restore tl
  MOV R0, -(SP)         ; push eq arg1 = result
  MOV 2(R3), R0         ; rest <- cdr(tl)
  MOV @R0, R0           ; arg1 <- car(rest)
  JSR PC, #eval         ; result <- eval(cadr(tl))
  MOV R0, R1            ; arg2 <- result
  MOV (SP)+, R0         ; pop arg1
  JSR PC, #eq           ; test if equal
  BNE not_eq
  ; eq
  MOV "T" R0
  BR return
  ; not_eq
  MOV "F" R0
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "COND", R1        ; arg2 <- at"COND"
  JSR PC, #eq           ; test eq(hd, at"COND")
  BNE next              ; skip if not cond
  ; return evcon(car(tl))
  MOV @R3, R2           ; arg1 <- car(tl)
  evcon:
  ; R1 = arg1 = at"T"
  ; R2 = c
  MOV @R2, R0           ; car(c)
  MOV @R0, R0           ; arg1 <- caar(c)
  MOV R2, -(SP)         ; save c
  JSR PC, #eval         ; arg1 <- eval(caar(c))
  MOV (SP)+, R2         ; restore c
  MOV "T" R1            ; arg2 <- at"T"
  JSR PC, #eq           ; check if it's at"T"
  BEQ is_true
  ; if not true
  MOV 2(R2), R2         ; c <- cdr(c)
  BR -???               ; evcon(c)
  ; if true
  MOV @R2, R0           ; car(c)
  MOV 2(R0), R0         ; cdar(c)
  MOV @R0, R0           ; arg1 <- cadar(c)
  JSR PC, #eval         ; result <- eval(cadar(c))
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "CAR", R1         ; arg2 <- at"CAR"
  JSR PC, #eq           ; test eq(hd, at"CAR")
  BNE next              ; skip if not car
  ; return car(eval(car(tl)))
  MOV @R3, R0           ; arg1 <- car(tl)
  JSR PC, #eval         ; result <- eval(car(tl))
  MOV @R0, R0           ; result <- car(result)
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "CDR", R1         ; arg2 <- at"CDR"
  JSR PC, #eq           ; test eq(hd, at"CDR")
  BNE next              ; skip if not cdr
  ; return cdr(eval(car(tl)))
  MOV @R3, R0           ; arg1 <- car(tl)
  JSR PC, #eval         ; result <- eval(car(tl))
  MOV 2(R0), R0         ; result <- cdr(result)
  RTS PC

  next:
  MOV R2, R0            ; arg1 <- hd
  MOV "CONS", R1        ; arg2 <- at"CONS"
  JSR PC, #eq           ; test eq(hd, at"CONS")
  BNE otherwise         ; skip if not cons
  ; return cons(eval(car(tl)), eval(cadr(tl)))
  MOV @R3, R0           ; arg1 <- car(tl)
  MOV R3, -(SP)         ; save tl
  JSR PC, #eval         ; result <- eval(car(tl))
  MOV (SP)+, R3         ; restore tl
  MOV R0, -(SP)         ; push cons arg1
  MOV 2(R3), R0         ; rest <- cdr(tl)
  MOV @R0, R0           ; arg1 <- car(rest)
  JSR PC, #eval         ; result <- eval(cadr(tl))
  MOV R0, R1            ; arg2 <- result
  MOV (SP)+, R0         ; pop arg1
  JSR PC, #cons
  RTS PC

  otherwise:
  return eval(cons(assoc(hd), tl)))
  RTS PC

; This one touches R0, R1
eq:
  ; R0 = arg1
  ; R1 = arg2

  BIT #1, (R0)            ; test if arg1 is cons or atom
  BEQ bad                 ; if its cons jump to error
  ; otherwise its atom
  BIT #1, (R1)            ; test if arg2 is cons or atom
  BEQ bad                 ; if its cons jump to error

  ; get the string pointers out of atoms arg1 and arg2
  MOV @(R0), R0
  DEC R0
  MOV @(R1), R1
  DEC R1
loop:
  CMPB (R0), (R1)+        ; compare a byte from each string
                          ; advance R1 pointer
  BNE not_equal
  ; if they are equal:
  TSTB (R0)+              ; check if null byte
                          ; advance R0 pointer
  BEQ done                ; if null byte, strings are equal
  ; otherwise, not done yet:
  BR loop
not_equal:
  ; the strings are not equal
  CLZ                     ; clear zero flag
  RTS PC
done:
  ; the strings are equal
  SEZ                     ; set zero flag
  RTS PC
bad:
  BR -2                   ; infinite loop


; THIS ONE TOUCHES R0, R2
cons:
  ; R0 = arg1
  ; R1 = arg2
  ; heap at 10000
  ; no garbage collection
  ; pretend heap is infinite
  MOV @#10000, R2     ; get free pointer
  MOV R0, @R2         ; move arg1 to car of new cons cell
  MOV R1, 2(R2)       ; move arg2 to cdr of new cons cell
  MOV R2, R0          ; result <- new cons cell
  TST (R2)+           ; increment free pointer
  MOV R2, @#10000     ; store new free pointer
  RTS PC


; This one touches R0, R1, R2, R4
assoc:
  MOV R5, R4
  MOV R0, R2
  ; R1 = key
  ; R2 = symbol
  ; R4 = symbol table pointer
  loop:
  CMP R4, #10000  ; beginning of symbol table
  BLOS bad        ; symbol not found
  ; otherwise check next row
  TST -(R4)       ; skip column 1
  MOV -(R4), R1   ; key <- column 0
  MOV R2, R0      ; arg1 <- symbol
  JSR PC, #eq     ; check if symbol equals key
  BNE loop
  ; otherwise they are equal
  MOV 2(R4), R0   ; result <- value
  RTS PC
  bad:
  BR -2           ; infinite loop
