// Fixture for TestPagePartAgcr_Tests.al. A SingleInstance codeunit so the host page and its
// FactBox part -- two different AL objects, with no other way to share state -- can both
// append to the SAME ordered trace within one test, without going through a table (and the
// positioning subtleties a shared record would introduce -- see the test's own header).

codeunit 60811 "Test Page Part Agcr Trace"
{
    SingleInstance = true;

    var
        Trace: Text;

    procedure Append(Marker: Text)
    begin
        Trace += Marker + ';';
    end;

    procedure GetTrace(): Text
    begin
        exit(Trace);
    end;

    procedure Reset()
    begin
        Trace := '';
    end;
}
