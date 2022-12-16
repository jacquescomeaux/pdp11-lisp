; copy s-exp into big (permanent) heap
; R0 = arg1
; big heap at 11000
; touches R0, R1, R2
copy:
005400 032710 BIT #1, (R0)          ; test if cons or atom
005402 000001
005404 001016 BNE is_atom           ; branch if atom
; otherwise it's cons:
005406 011046 MOV @R0, -(SP)        ; save car to stack
005410 016000 MOV 2(R0), R0         ; arg1 <- cdr
005412 000002
005414 004737 JSR PC, @copy         ; result <- copy(cdr)
005416 005400
005420 010001 MOV R0, R1            ; arg2 <- result
005422 012600 MOV (SP)+, R0         ; arg1 <- car from stack
005424 010146 MOV R1, -(SP)         ; save arg2
005426 004737 JSR PC, @copy         ; arg1 <- copy(car)
005430 005400
005432 012601 MOV (SP)+, R1         ; restore arg2
005434 004737 JSR PC, @big_cons     ; allocate cons cell
005436 005600
005440 000207 RTS PC
is_atom:
005442 013702 MOV @#11000, R2       ; get free pointer
005444 011000
005446 010246 MOV R2, -(SP)         ; save new atom start address
005450 010201 MOV R2, R1
005452 062701 ADD #3, R1
005454 000003
005456 010122 MOV R1, (R2)+         ; allocate atom tag and increment free pointer
005460 011000 MOV @R0, R0
005462 005300 DEC R0                ; get string address
005464 112022 MOVB (R0)+, (R2)+     ; copy one byte
005466 001376 BNE -4                ; if not null continue copying chars
005470 005202 INC R2                ; align free pointer
005472 042702 BIC #1, R2
005574 000001
005576 010237 MOV R2, @#11000       ; store new free pointer
005500 011000
005502 012600 MOV (SP)+, R0         ; result <- address of new atom
005504 000207 RTS PC

big_cons:
005600 013702 MOV @#11000, R2       ; get free pointer
005602 011000
005604 010012 MOV R0, @R2           ; move arg1 to car of new cons cell
005606 010162 MOV R1, 2(R2)         ; move arg2 to cdr of new cons cell
005610 000002
005612 010200 MOV R2, R0            ; result <- new cons cell
005614 062702 ADD 4, R2             ; advance free pointer
005616 000004
005620 010237 MOV R2, @#11000       ; store new free pointer
005622 011000
005624 000207 RTS PC
