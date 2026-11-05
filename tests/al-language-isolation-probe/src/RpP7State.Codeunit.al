namespace ALLanguage.IsolationProbe;

// singleinstance-shared-on-purpose: probe P7 itself is what "LT RP P7 First" (61343) leaves for "LT RP P7 Second" (61344) here.

// Probe P7 (ADR-066 of al-runtime-rs): the SingleInstance state "LT RP P7 First" (61343) sets
// and "LT RP P7 Second" (61344) reads in the next test codeunit.
codeunit 61335 "LT RP P7 State"
{
    SingleInstance = true;

    procedure SetMark(NewMark: Integer)
    begin
        Mark := NewMark;
    end;

    procedure GetMark(): Integer
    begin
        exit(Mark);
    end;

    var
        Mark: Integer;
}
