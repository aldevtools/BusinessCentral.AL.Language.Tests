// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), own codeunits 72886, 72887, 72888
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the number of nested Codeunit.Run calls reached before the ceiling, error text and code. Risky: deep recursion through Codeunit.Run (own file so a runner problem drops only this one).
// BC versions: 29 (27 and 28 by CI)

codeunit 72886 "LT CallDepth RunCounter"
{
    SingleInstance = true;

    var
        Counter: Integer;

    procedure Reset()
    begin
        Counter := 0;
    end;

    procedure Bump()
    begin
        Counter += 1;
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;
}

codeunit 72887 "LT CallDepth RunSelf"
{
    trigger OnRun()
    var
        C: Codeunit "LT CallDepth RunCounter";
    begin
        C.Bump();
        Codeunit.Run(Codeunit::"LT CallDepth RunSelf");
    end;
}

