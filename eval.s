R0 has e (s-exp to be evaluated)
a (the environment / symbol table) at a known location

; e to be evaluated in R0
; result of evaluation in R0
eval: (e) =
  BIT #1, R0            ; test if e is cons or atom
  BEQ not_atom          ; branch if not atom(e)
  JSR PC, #assoc        ; return assoc(e)
  ; TODO assumes assoc puts result in R0
  RTS PC
not_atom:
  MOV @R0, R2           ; hd <- car(e) ; R2
  MOV 2(R0), R3         ; tl <- cdr(e) ; R3
  BIT #1, R1            ; test if hd is cons or atom
  BNE head_is_atom      ; branch if atom(hd)
  ;otherwise:
  MOV @R2, R0           ; arg1 <- car(hd)     ; R0 (first)
  MOV 2(R2), R4         ; rest <- cdr(hd)     ; R4
  MOV 2(R4), R5         ; rest' <- cdr(rest)  ; R5
  MOV @(R4), R4         ; second <- car(rest) ; R4
  MOV @(R5), R5         ; third <- car(rest') ; R5

  MOV "LABEL", R1       ; arg2 <- at"LABEL"
  JSR PC, #eq           ; test eq(first, at"LABEL")
                        ; result is in R1
  BEQ not_label         ; branch if not label
  ;if is label
  ; push entry l[second, hd] onto symbol table a
  ; a <- cons(l[second, hd], a)
  MOV R2, (#symbol_table); push hd onto symbol table column 1
  MOV R4, (#symbol_table); push second onto symbol table column 0

  ; r0 <- cons(third, tl)
  MOV R5, R0        ; arg1 <- third
  MOV R3, R1        ; arg2 <- tl
  JSR PC, #cons     ; result in R0
  JSR PC, #eval     ; result <- eval(cons(third, tl))
  pop off of a      ; a <- cdr a
  RTS PC            ; return result in R0

not_label:
                        ; first still in R0
  MOV "LAMBDA", R1      ; arg2 <- at"LAMBDA"
  JSR PC, #eq           ; test eq(first, at"LAMBDA")
                        ; result is in R1
  BEQ error             ; branch if not lambda

  ;if is lambda
  save old a

  ; push onto a ; a <- append(pair(second, evlis(tl)), a)
  evlis: (symbols, args)
  BIT #1, R0    ; test if args is cons or atom
  if its atom jump to done
  ; if its cons:
  BIT #1, R1    ; test if symbols is cons or atom
  if its atom jump to done
  ; if both are cons:
  symbol <- car(symbols)
  symbols <- cdr(symbols)
  arg1 <- car(args)
  args <- cdr(args)
  JSR PC, #eval               ; eval (arg1) ; result in R0
  ; push (symbol, eval(arg))
  MOV R0, (#symbol_table)     ; push R0 to column 1
  MOV   , (#symbol_table)     ; push symbol to column 0
  jump to evlis(symbols, args)
  done:

  MOV R5, R0                  ; arg1 <- third
  JSR PC, #eval               ; result <- eval(third)

  pop off of a ; a <- old a

  return result

error:
  this should never happen. ill-formed s-exp
  return bad ; maybe just return the original s-exp
head_is_atom: (hd, tl)
  return cases
    [ (eq(hd, at"QUOTE"), car(tl))
    , (eq(hd, at"ATOM"), atom(eval(car(tl))))
    , (eq(hd, at"EQ"), eq(eval(car(tl)), eval(cadr(tl))))
    , (eq(hd, at"COND"), evcon(car(tl)))
    , (eq(hd, at"CAR"), car(eval(car(tl))))
    , (eq(hd, at"CDR"), cdr(eval(car(tl))))
    , (eq(hd, at"CONS"), cons(eval(car(tl)), eval(cadr(tl))))
    , (at"T", eval(cons(assoc(hd), tl)))
    ]

evcon(c) =
  cases
    [ (eval(caar(c)), eval(cadar(c)))
    , (at"T", evcon(cdr(c)))
    ]

evlis(m) =
  cases
    [ (null(m), at"NIL")
    , (at"T", cons(eval(car(m)), evlis(cdr(m))))
    ]

eq
assoc
cons

at"QUOTE"
at"ATOM"
at"EQ"
at"COND"
at"CAR"
at"CDR"
at"CONS"
at"LABEL"
at"LAMBDA"
