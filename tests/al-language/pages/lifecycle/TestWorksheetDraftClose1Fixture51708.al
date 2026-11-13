// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51708 "Draft Probe Trace"
{
    SingleInstance = true;
    var
        Calls: Text;

    procedure Add(Entry: Text)
    begin
        Calls += Entry + '|';
    end;

    procedure Reset()
    begin
        Calls := '';
    end;

    procedure Read(): Text
    begin
        exit(Calls);
    end;
}
