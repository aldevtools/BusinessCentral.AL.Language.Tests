// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-singleinstance-property
// Scope: in-scope
// Overwrites the three globals from a later test codeunit than the one that read them.

codeunit 73478 "SIR Keep Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Run()
    var
        S: Codeunit "SIR State";
        K: Codeunit "SIR Keep";
        Observer: Codeunit "Probe Observer";
    begin
        S.WInt();
        S.WTxt();
        S.WListNew();
        Observer.Observe('global int', Format(S.GetInt()));
        Observer.Observe('global text', S.GetTxt());
        Observer.Observe('global list', Format(S.GetListNew().Count()));
        Observer.Observe('kept int', Format(K.KeptIntNow()));
        Observer.Finish();
    end;
}
