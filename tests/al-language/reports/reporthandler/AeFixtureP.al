// Fixture of AeProcessingOnlyRequestPage.al: a copy of log 73840 (lt-report-requestpage) so that no SingleInstance log is shared between test codeunits.

codeunit 78213 "LT AE Log P"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}
