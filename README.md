# LISP and beyond from bare metal

It's `eval`s all the way up

## Background

In 2022 I wrote a LISP interpreter in PDP-11 assembly,
hand-translated it into machine code,
and toggled it in directly to the front panel
of my PhD advisor's PiDP-11.
I kept as close as possible
to the system described in John McCarthy's original paper
(other than fixing the known bug in `eval`).

This is that project.
The original plan involved using it
to bootstrap an even better interpreter,
but I lost some momentum
when I realized
the thing I created had dynamic instead of lexical scoping,
and also when
the PiDP-11 got turned off
and lost its emulated memory contents.

I gave a little presentation on it anyway;
the slides for that can be found
[here](https://jacquescomeaux.xyz/lisp-from-scratch.pdf).
In short, S-Functions manipulate S-Expressions,
but descriptions of S-Functions *are* S-Expressions.
`eval` is the S-Function that reads an S-Expression
which describes an S-Function,
and does the thing that that description describes.

## Learning more

If you want to know more
and know how to find me in real life,
please do so
and I'd be happy to talk
about any of this stuff in more detail.
