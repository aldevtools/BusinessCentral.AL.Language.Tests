// Fixture of the cross-app DefaultTestHandler probes (al-runner 7181): the log the handler apps A, C and D write to.
// One entry list per test codeunit id, kept in a SingleInstance codeunit so every app of the session shares it.
// singleinstance-shared-on-purpose: the log is written by the handler apps while three test codeunits run and read back by "LT BI XH Reader" in a later one; that is the measurement.
#if BC29PLUS
codeunit 97830 "XH Log"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Integer, Text];

    procedure Add(CodeunitId: Integer; Entry: Text)
    begin
        if Entries.ContainsKey(CodeunitId) then
            Entries.Set(CodeunitId, Entries.Get(CodeunitId) + Entry + ';')
        else
            Entries.Add(CodeunitId, Entry + ';');
    end;

    procedure Take(CodeunitId: Integer): Text
    begin
        if Entries.ContainsKey(CodeunitId) then
            exit(Entries.Get(CodeunitId));
        exit('');
    end;
}
#endif
