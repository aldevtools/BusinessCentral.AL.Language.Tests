// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): Option value where an Integer is expected, PadStr.
// BC versions: 29 (27 and 28 by CI)

codeunit 70348 "LT P98 OptPadStr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_PadStr_Option()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two,Three;
    begin
        Opt := Opt::Three;
        Observer.Observe('len', PadStr('ab', Opt));
        Observer.Observe('lenFill', PadStr('ab', Opt, 'x'));
        Opt := Opt::Zero;
        Observer.Observe('zero', '[' + PadStr('ab', Opt) + ']');
        Opt := Opt::One;
        Observer.Observe('shorter', PadStr('abc', Opt));
        Observer.Expect('len', 'ab ');
        Observer.Expect('lenFill', 'abx');
        Observer.Expect('zero', '[]');
        Observer.Expect('shorter', 'a');
        Observer.Verify();
    end;
}
