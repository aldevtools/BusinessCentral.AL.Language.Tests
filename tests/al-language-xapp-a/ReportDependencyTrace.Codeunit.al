// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-report-ext-object
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local trace codeunit
// BC versions: 27.5+

// local object: the trace captures trigger order across app boundaries.
codeunit 61134 "RPT Dependency Trace"
{
    SingleInstance = true;
    var
        Events: Text;

    procedure Push(Value: Text)
    begin
        Events += Value + '|';
    end;

    procedure Reset()
    begin
        Clear(Events);
    end;

    procedure Read(): Text
    begin
        exit(Events);
    end;
}
