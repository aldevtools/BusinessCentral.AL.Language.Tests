// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): Option value where an Integer is expected, SelectStr.
// BC versions: 29 (27 and 28 by CI)

codeunit 70346 "LT P98 OptSelectStr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_SelectStr_Option()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two,Three;
    begin
        Opt := Opt::One;
        Observer.Observe('one', SelectStr(Opt, 'a,b,c'));
        Opt := Opt::Two;
        Observer.Observe('two', SelectStr(Opt, 'a,b,c'));
        Opt := Opt::Three;
        Observer.Observe('three', SelectStr(Opt, 'a,b,c'));
        Observer.Observe('three', 'no error');
        Opt := Opt::Zero;
        asserterror Observer.Observe('zero', SelectStr(Opt, 'a,b,c'));
        Observer.ObserveError('zero');
        Observer.Expect('one', 'a');
        Observer.Expect('two', 'b');
        Observer.Expect('three', 'c');
        Observer.Expect('three', 'no error');
        Observer.Expect('zero|text', 'The SELECTSTR comma-string a,b,c does not contain a value for index 0.');
        Observer.Expect('zero|code', 'InvalidStringFormat');
        Observer.Verify();
    end;
}
