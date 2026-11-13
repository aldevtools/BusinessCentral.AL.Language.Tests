// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

// local object: this object defines the page, record, or trigger behavior that the test exercises.
codeunit 51770 "Three Part Probe Trace"
{
    SingleInstance = true;
    var
        Value: Text;

    procedure Reset()
    begin
        Clear(Value);
    end;

    procedure Add(Origin: Text; CloseAction: Action)
    begin
        Value += StrSubstNo('%1:%2|', Origin, Format(CloseAction));
    end;

    procedure Read(): Text
    begin
        exit(Value);
    end;
}
