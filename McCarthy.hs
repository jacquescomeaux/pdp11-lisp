module McCarthy where

import Prelude hiding ((^), (+), null)

data Sexp = Atom String | Pair Sexp Sexp deriving Show

at = Atom

l []       = at"NIL"
l (x : xs) = Pair x (l xs)

t = l[l[at"AB",at"C"],at"D"]

atom (Atom _ )  = at"T"
atom (Pair _ _) = at"F"

eq (Atom x, Atom y)
    | x == y    = at"T"
    | otherwise = at"F"
eq _ = error "undefined"

car (Pair e1 _) = e1
car _ = error "undefined"

cdr (Pair _ e2) = e2
cdr _ = error "undefined"

cons (e1, e2) = Pair e1 e2

cases ((Atom x, y) : ps)
  | x == "T" = y
  | x == "F" = cases ps
cases _ = error "undefined"

(^) p q = cases[(p, q), (at"T",at"F")]
(+) p q = cases[(p, at"T"), (at"T", q)]
n p = cases[(p, at"F"), (at"T", at"T")]
(-->) p q = cases[(p,q), (at"T",at"T")]

ff(x) = cases[(atom(x), x), (at"T",ff(car(x)))]

subst(x, y, z) = cases
    [ (atom(z), cases[(eq(z, y), x), (at"T", z)])
    , (at"T", cons(subst(x, y, car(z)), subst(x, y, cdr(z))))
    ]

equal(x, y) =
    (atom(x) ^ atom(y) ^ eq(x,y)) +
    (n (atom(x)) ^ n(atom(y)) ^ equal(car(x), car(y)) ^ equal(cdr(x), cdr(y)))

null(x) = atom(x) ^ eq(x, at"NIL")

append(x, y) = cases
    [ (null(x), y)
    , (at"T", cons(car(x), append(cdr(x),y)))
    ]

pair(x, y) = cases
    [ (null(x) ^ null(y), at"NIL")
    , (n(atom(x)) ^ n(atom(y)), cons(l[car(x), car(y)], pair(cdr(x), cdr(y))))
    ]

caar(x)   = car(car(x))
cadar(x)  = car(cdr(car(x)))
cadr(x)   = car(cdr(x))
caddr(x)  = car(cdr(cdr(x)))
caddar(x) = car(cdr(cdr(car(x))))

assoc(x, y) = cases
    [ (eq(caar(y), x), cadar(y))
    , (at"T", assoc(x, cdr(y)))
    ]

sub2(x, z) = cases
    [ (null(x), z)
    , (eq(caar(x), z), cadar(x))
    , (at"T", sub2(cdr(x), z))
    ]

sublis(x, y) = cases
    [ (atom(y), sub2(x, y))
    , (at"T", cons(sublis(x, car(y)),sublis(x, cdr(y))))
    ]

apply(f, args) = eval(cons(f, appq(args)), at"NIL")

appq(m) = cases
    [ (null(m), at"NIL")
    , (at"T", cons(l[at"QUOTE", car(m)], appq(cdr(m))))
    ]

eval(e, a) = cases
    [ (atom(e), assoc(e, a))
    , (atom(car(e)), cases
          [ (eq(car(e), at"QUOTE"), cadr(e))
          , (eq(car(e), at"ATOM"), atom(eval(cadr(e), a)))
          , (eq(car(e), at"EQ"), eq(eval(cadr(e), a), eval(caddr(e), a)))
          , (eq(car(e), at"COND"), evcon(cadr(e), a))
          , (eq(car(e), at"CAR"), car(eval(cadr(e), a)))
          , (eq(car(e), at"CDR"), cdr(eval(cadr(e), a)))
          , (eq(car(e), at"CONS"), cons(eval(cadr(e), a), eval(caddr(e), a)))
          , (at"T", eval(cons(assoc(car(e), a), cdr(e)), a))
          -- , (at"T", eval(cons(assoc(car(e), a), evlis(cdr(e), a)), a))
          ]
      )
    , (eq(caar(e), at"LABEL"), eval(cons(caddar(e), cdr(e)), cons(l[cadar(e), car(e)], a)))
    , (eq(caar(e), at"LAMBDA"), eval(caddar(e), append(pair(cadar(e), evlis(cdr(e), a)), a)))
    ]
  where
    evcon(c, a) = cases[(eval(caar(c), a), eval(cadar(c), a)), (at"T", evcon(cdr(c),a))]
    evlis(m, a) = cases[(null(m), at"NIL"), (at"T", cons(eval(car(m), a), evlis(cdr(m), a)))]
