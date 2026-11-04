// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): Option value where an Integer is expected, CopyStr.
// BC versions: 29 (27 and 28 by CI)

codeunit 70347 "LT P98 OptCopyStr"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_CopyStr_Option()
    var
        Observer: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two,Three;
    begin
        Opt := Opt::Two;
        Observer.Observe('pos', CopyStr('abcdef', Opt));
        Observer.Observe('posLen', CopyStr('abcdef', Opt, Opt));
        Opt := Opt::One;
        Observer.Observe('one', CopyStr('abcdef', Opt, Opt));
        Opt := Opt::Zero;
        asserterror Observer.Observe('zero', CopyStr('abcdef', Opt, 2));
        Observer.ObserveError('zero');
        Observer.Observe('zeroLen', CopyStr('abcdef', 2, Opt));
        Observer.Expect('pos', 'bcdef');
        Observer.Expect('posLen', 'bc');
        Observer.Expect('one', 'a');
        Observer.Expect('zero|text', 'The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('zero|code', 'OutsidePermittedRange');
        Observer.Expect('zeroLen', '');
        Observer.Verify();
    end;
}
