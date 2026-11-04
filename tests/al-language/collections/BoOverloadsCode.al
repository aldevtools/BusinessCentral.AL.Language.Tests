// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-method-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (69160), self-contained codeunits 82354 (overloads) and 82357 (test)
// Corpus issue #664 item 79 (second half): overloads that differ only in the length of a Code element type
// (List of [Code[10]] and List of [Code[50]]). The compiler accepts the pair; the question is whether the app publishes
// (both are List of [Code] at run time, which could give C# CS0111) and which overload runs.
// Result (BC 29.0): the app publishes (no CS0111) and each list type runs its own overload.

codeunit 82354 "LT BO Code Overload Host"
{
    procedure InitCode(L: List of [Code[10]]): Text
    begin
        exit('code10 list ' + Format(L.Count()));
    end;

    procedure InitCode(L: List of [Code[50]]): Text
    begin
        exit('code50 list ' + Format(L.Count()));
    end;
}

codeunit 82357 "LT BO Code Overloads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CodeLengthListOverloads_WhichRuns()
    var
        Host: Codeunit "LT BO Code Overload Host";
        Observer: Codeunit "Probe Observer";
        L10: List of [Code[10]];
        L50: List of [Code[50]];
    begin
        L10.Add('A');
        L50.Add('B');
        L50.Add('C');
        Observer.Observe('list of code10', Host.InitCode(L10));
        Observer.Observe('list of code50', Host.InitCode(L50));
        Observer.Expect('list of code10', 'code10 list 1');
        Observer.Expect('list of code50', 'code50 list 2');
        Observer.Verify();
    end;
}
