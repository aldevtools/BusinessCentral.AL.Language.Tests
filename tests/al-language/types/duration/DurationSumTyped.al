// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74937 "LT DurSum Typed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Sum_AssignedToDecimalAndBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        Dec: Decimal;
        Big: BigInteger;
    begin
        D1 := 1500;
        D2 := 2500;
        Dec := D1 + D2;
        Observer.Observe('decimal', Format(Dec, 0, 9));
        Big := D1 + D2;
        Observer.Observe('biginteger', Format(Big));
        Dec := D1 - D2;
        Observer.Observe('decimal difference', Format(Dec, 0, 9));
        Observer.Expect('decimal', '4000');
        Observer.Expect('biginteger', '4000');
        Observer.Expect('decimal difference', '-1000');
        Observer.Verify();
    end;

    [Test]
    procedure Sum_ComparedWithIntegerAndBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        Big: BigInteger;
    begin
        D1 := 1500;
        D2 := 2500;
        Observer.Observe('equal integer', Format(D1 + D2 = 4000));
        Observer.Observe('less integer', Format(D1 + D2 < 4001));
        Observer.Observe('greater integer', Format(D1 + D2 > 4000));
        Observer.Observe('not equal integer', Format(D1 + D2 <> 4000));
        Observer.Observe('negative difference less than 0', Format(D1 - D2 < 0));
        Observer.Observe('difference equal -1000', Format(D1 - D2 = -1000));
        Evaluate(Big, '4000');
        Observer.Observe('equal biginteger', Format(D1 + D2 = Big));
        D1 := 2000000000;
        D2 := 2000000000;
        Observer.Observe('beyond integer greater', Format(D1 + D2 > 2147483647));
        Evaluate(Big, '4000000000');
        Observer.Observe('beyond integer equal biginteger', Format(D1 + D2 = Big));
        Observer.Expect('equal integer', 'Yes');
        Observer.Expect('less integer', 'Yes');
        Observer.Expect('greater integer', 'No');
        Observer.Expect('not equal integer', 'No');
        Observer.Expect('negative difference less than 0', 'Yes');
        Observer.Expect('difference equal -1000', 'Yes');
        Observer.Expect('equal biginteger', 'Yes');
        Observer.Expect('beyond integer greater', 'Yes');
        Observer.Expect('beyond integer equal biginteger', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Sum_FormatWithFormatString()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
    begin
        D1 := 1500000;
        D2 := 2500000;
        Observer.Observe('default', Format(D1 + D2));
        Observer.Observe('format 0', Format(D1 + D2, 0, 0));
        Observer.Observe('format 1', Format(D1 + D2, 0, 1));
        Observer.Observe('format 9', Format(D1 + D2, 0, 9));
        Observer.Observe('length 5', Format(D1 + D2, 5));
        Observer.Observe('integer thousand', Format(D1 + D2, 0, '<Integer Thousand>'));
        Observer.Observe('precision', Format(D1 + D2, 0, '<Precision,2:2><Standard Format,0>'));
        asserterror Observer.Observe('duration variable thousand', Format(D1, 0, '<Integer Thousand>'));
        Observer.ObserveError('af74');
        Observer.Expect('default', '4000000');
        Observer.Expect('format 0', '4000000');
        Observer.Expect('format 1', '4000000');
        Observer.Expect('format 9', '4000000');
        Observer.Expect('length 5', '40000');
        Observer.Expect('integer thousand', '4,000,000');
        Observer.Expect('precision', '4000000');
        Observer.Expect('af74|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand>');
        Observer.Expect('af74|code', 'InvalidFormatString');
        Observer.Verify();
    end;
}
