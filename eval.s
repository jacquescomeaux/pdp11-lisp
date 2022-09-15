R0 has e (s-exp to be evaluated)
a (the environment / symbol table) at a known location

; e to be evaluated in R0
; result of evaluation in R0
eval: (e) =
  BIT #1, (R0)          ; test if e is cons or atom
  BEQ not_atom          ; branch if not atom(e)
  JSR PC, #assoc        ; return assoc(e)
  ; TODO assumes assoc puts result in R0
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
                        ; first still in R0
  MOV "LAMBDA", R1      ; arg2 <- at"LAMBDA"
  JSR PC, #eq           ; test eq(first, at"LAMBDA")
  BNE error             ; branch if not lambda

  ;if is lambda

  ; push onto a               ; a <- append(pair(second, evlis(tl)), a)

  MOV R5, -(SP)               ; push old symbol table pointer to stack

  MOV 2(R2), R1               ; rest <- cdr(hd)
  MOV @R1, R2                 ; symbols <- car(rest) = second
  MOV 2(R4), R3               ; args <- tl = cdr(e)

  ; R1 = rest

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
  JSR PC, #eval               ; result <- eval (arg1)

  ; push (symbol, eval(arg))
  MOV @R2, (R5)+              ; push symbol (=car(symbols)) to column 0
  MOV R0, (R5)+               ; push result to column 1

  MOV 2(R2), R2               ; args <- cdr(args)
  MOV 2(R3), R3               ; symbols <- cdr(symbols)

  BR -???                     ; jump to evlis(symbols, args)
  done:

  MOV 2(R1), R1               ; rest' <- cdr(rest)
  MOV @R1, R0                 ; arg1 <- third = car(rest')
  JSR PC, #eval               ; result <- eval(third)

  ; pop off argument entries
  MOV (SP)+, R5               ; restore symbol table pointer

  RTS PC

error:
  MOV R4, R0
  BR -2                       ; infinite loop
  ; this should never happen. ill-formed s-exp
  ; return bad ; maybe just return the original s-exp
  RTS PC
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
  MOV R2, R0            ; arg1 <- hd
  MOV "QUOTE", R1       ; arg2 <- at"QUOTE"
  JSR PC, #eq           ; test eq(hd, at"QUOTE")
  BNE next              ; skip if not quote
  ...
  RTS PC

  next:
  MOV "ATOM", R1        ; arg2 <- at"ATOM"
  JSR PC, #eq           ; test eq(hd, at"ATOM")
  BNE next              ; skip if not atom
  ...
  RTS PC

  next:
  MOV "EQ", R1          ; arg2 <- at"EQ"
  JSR PC, #eq           ; test eq(hd, at"EQ")
  BNE next              ; skip if not eq
  ...
  RTS PC

  next:
  MOV "COND", R1        ; arg2 <- at"COND"
  JSR PC, #eq           ; test eq(hd, at"COND")
  BNE next              ; skip if not cond
  ...
  RTS PC

  next:
  MOV "CAR", R1         ; arg2 <- at"CAR"
  JSR PC, #eq           ; test eq(hd, at"CAR")
  BNE next              ; skip if not car
  ...
  RTS PC

  next:
  MOV "CDR", R1         ; arg2 <- at"CDR"
  JSR PC, #eq           ; test eq(hd, at"CDR")
  BNE next              ; skip if not cdr
  ...
  RTS PC

  next:
  MOV "CONS", R1       ; arg2 <- at"CONS"
  JSR PC, #eq          ; test eq(hd, at"CONS")
  BNE next             ; skip if not cons
  ...
  RTS PC

  otherwise:
  ...
  RTS PC


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
