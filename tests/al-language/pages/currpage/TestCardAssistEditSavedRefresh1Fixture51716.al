// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51716 "Next Refresh Trace"
{
    SingleInstance = true;

    var
        Reads: Integer;

    procedure RecordRead()
    begin
        Reads += 1;
    end;

    procedure Reset()
    begin
        Reads := 0;
    end;

    procedure CheckNoRead()
    begin
        if Reads <> 0 then
            Error('Expected no current-record trigger after AssistEdit, got %1', Reads);
    end;
}
