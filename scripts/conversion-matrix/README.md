# Implicit conversion matrix

What AL converts implicitly, by context and type pair, in two parts.

## Compile matrix

`gen.py` writes one line of AL per (context, source, target) and compiles each context as a one-app project with the real AL compiler.

- Contexts: `assign` (`t := s`), `compound_add` (`t += s`), `arg_byvalue`, `arg_var`, `exit`, `eq`, `ne`, `lt`, `add` and `sub`
  (`s + t`, `s - t`), `in_set` (`s in [t]`), `case_label` (`case s of t:`), `cond_branches` (`B ? s : t`).
- Sources and targets: variables of Integer, BigInteger, Decimal, Boolean, Char, Byte, two Option types, two Enum types, an Enum that
  implements an interface, Text, Text[10], Text[3], Code[10], Code[3], Code[250], Label, TextConst, Date, Time, DateTime, Duration,
  DateFormula, Guid, RecordId, Variant, TextBuilder and an Interface; table fields of the field types (with Media and MediaSet); literals
  (`lit.*`); a TestPage control value and `Media.MediaId()`.
- `compile-matrix.csv`: one row per (context, source), one column per target. A cell is `ok`, `ok/AL0603` (accepted with that warning),
  or the error codes on that line (`AL0122`, `AL0122+AL0698`). An empty cell is a target the context does not have (a Label is no
  parameter type).
- `compile-messages.csv`: the first three cells of every (context, code), with the compiler's message.

Run with the newest AL compiler (the corpus rule): `python3 gen.py --al <al> --symbols <folder with System.app> --runtime 18.0`.
Measured on 2026-10-31 with AL 30.0.44.47290-beta: the verdicts are the same for runtime 16.1, 17.1 and 18.0 (BC 27.5, 28.5, 29.0).
The conditional operator needs runtime 14.0 or later (AL0666 below).

BC recompiles an app when it is published, with the compiler of its own version. `compile-matrix-older-compilers.csv` lists the 110 cells
where the compilers of BC 27 (AL 16.2.28.57946, runtime 16.0) and BC 28 (AL 17.0.34.45391, runtime 17.0) differ from AL 30: BigInteger to
and from an Enum is AL0122 / AL0133 there (every context), and a `var` argument between Integer and BigInteger is AL0133. The run matrix
puts the BigInteger/Enum tests under `#if BC29PLUS`.

The rejected cell kinds that no case covered before are must-not-compile cases 2400 to 2431 (`tests/must-not-compile/`).

## Run matrix

`gen_run.py` writes `tests/al-language/types/lt-y31-conversion-matrix/` from the accepted cells: boundary values per source (empty,
too long for Text[10]/Code[10]/Text[3], lower case for Code, negative, zero, fractions, out of range for Byte, Char, Option and Enum
ordinals), each operation in a `[TryFunction]`, so a cell gives the value (`Format`, `StrLen` for text, the ordinal for Char, Option and
Enum, the `Is...` kinds of a Variant result) or the error text and code.

1. `python3 gen_run.py --matrix compile-matrix.csv --out <folder>` writes the observe form (every test ends in `Observer.Finish()`).
2. Run it on BC (the corpus CI); keep the result JSON (`legs.<major>.tests[].message`).
3. `python3 gen_run.py --matrix compile-matrix.csv --out <folder> --observed <result.json>` writes the final form with the values BC
   produced.

## Held

A part of a test without a BC result is written as a procedure `Held_<test>` with no `[Test]` attribute (`--hold-unobserved`); a codeunit
whose parts are all held is no test codeunit. On the corpus CI (BC 29.0 Linux container, 2026-10-31) these killed the session twice
("session killed twice by this codeunit: hub connection closed"), so they are Linux suspects and wait for a Windows check:

- an Enum value (with or without an interface, a variable or an enum literal) converted to BigInteger by `:=`, a by-value argument or
  `exit`, into a BigInteger variable or field (`LT Y31 Sus 1` to `6`);
- `B ? BigInteger : Enum` (the false branch converted to BigInteger), into a Variant (`LT Y31 Sus 9`, `10`);
- one of the tests of `LT Y31 Ar Byte` (Byte with Integer, Decimal, Char, Byte, Option, Date, Time, DateTime, Duration under `+`, `-`
  and `+=`); Byte with BigInteger, Enum and an Enum with an interface ran without a crash in codeunits of their own.
