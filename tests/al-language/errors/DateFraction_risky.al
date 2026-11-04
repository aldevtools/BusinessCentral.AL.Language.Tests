// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY (may not compile): Date + fractional Decimal.
// BC versions: 29 (27 and 28 by CI)

codeunit 70343 "LT P98 DateFraction"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_DatePlusFraction_Literal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(10, 3, 2021);
        asserterror Observer.Observe('plus25', Format(D + 2.5, 0, 9));
        Observer.ObserveError('af20');
        asserterror Observer.Observe('minus25', Format(D - 2.5, 0, 9));
        Observer.ObserveError('af22');
        asserterror Observer.Observe('plus15', Format(D + 1.5, 0, 9));
        Observer.ObserveError('af24');
        asserterror Observer.Observe('plus05', Format(D + 0.5, 0, 9));
        Observer.ObserveError('x1');
        asserterror Observer.Observe('minus05', Format(D - 0.5, 0, 9));
        Observer.ObserveError('x2');
        Observer.Expect('af20|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('af20|code', 'ConversionCast');
        Observer.Expect('af22|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.');
        Observer.Expect('af22|code', 'ConversionCast');
        Observer.Expect('af24|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1.5 to System.Int32.');
        Observer.Expect('af24|code', 'ConversionCast');
        Observer.Expect('x1|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Observer.Expect('x1|code', 'ConversionCast');
        Observer.Expect('x2|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -0.5 to System.Int32.');
        Observer.Expect('x2|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure P98_DatePlusFraction_Variable()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Dec: Decimal;
    begin
        D := DMY2Date(10, 3, 2021);
        Dec := 2.5;
        asserterror Observer.Observe('plus', Format(D + Dec, 0, 9));
        Observer.ObserveError('af38');
        asserterror Observer.Observe('minus', Format(D - Dec, 0, 9));
        Observer.ObserveError('af41');
        Dec := 2.4;
        asserterror Observer.Observe('plus24', Format(D + Dec, 0, 9));
        Observer.ObserveError('af45');
        Dec := 2.6;
        asserterror Observer.Observe('plus26', Format(D + Dec, 0, 9));
        Observer.ObserveError('x3');
        Dec := -2.5;
        asserterror Observer.Observe('plusNeg25', Format(D + Dec, 0, 9));
        Observer.ObserveError('x4');
        Observer.Expect('af38|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('af38|code', 'ConversionCast');
        Observer.Expect('af41|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.');
        Observer.Expect('af41|code', 'ConversionCast');
        Observer.Expect('af45|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.4 to System.Int32.');
        Observer.Expect('af45|code', 'ConversionCast');
        Observer.Expect('x3|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.6 to System.Int32.');
        Observer.Expect('x3|code', 'ConversionCast');
        Observer.Expect('x4|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2.5 to System.Int32.');
        Observer.Expect('x4|code', 'ConversionCast');
        Observer.Verify();
    end;
}
