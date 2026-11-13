// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51753 "Probe Part Trace"
{
    SingleInstance = true;
    var Calls: Integer;

    procedure Reset()
    begin
        Clear(Calls);
    end;

    procedure Hit()
    begin
        Calls += 1;
    end;

    procedure Count(): Integer
    begin
        exit(Calls);
    end;
}
