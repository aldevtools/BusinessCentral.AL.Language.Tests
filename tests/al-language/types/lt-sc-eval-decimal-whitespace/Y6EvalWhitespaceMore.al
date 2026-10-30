// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 91310
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: Evaluate(Decimal, Text) and Evaluate(Integer, Text) with a leading vertical tab (char 11) or form feed (char 12), with a carriage return, vertical
//   tab or form feed between the digits, and for Integer also with a trailing vertical tab, form feed and carriage return. Each case records the answer
//   of Evaluate, the value and the error text. ScEvalDecimalWhitespace.al pins the other white space characters.
// BC versions: 27, 28, 29
codeunit 91310 "LT Y6 Eval Whitespace More"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Ch(Code: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := Code;
        exit(C);
    end;

    local procedure TryDecimal(var Observer: Codeunit "Probe Observer"; Name: Text; Source: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := 99;
        ClearLastError();
        Ok := Evaluate(D, Source);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(D, 0, 9));
        if not Ok then
            Observer.ObserveError(Name + ' err');
    end;

    local procedure TryInteger(var Observer: Codeunit "Probe Observer"; Name: Text; Source: Text)
    var
        I: Integer;
        Ok: Boolean;
    begin
        I := 99;
        ClearLastError();
        Ok := Evaluate(I, Source);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(I));
        if not Ok then
            Observer.ObserveError(Name + ' err');
    end;

    [Test]
    procedure Decimal_LeadingVerticalTabAndFormFeed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDecimal(Observer, 'leading VT', Ch(11) + '1.5');
        TryDecimal(Observer, 'leading FF', Ch(12) + '1.5');
        TryDecimal(Observer, 'leading VT FF', Ch(11) + Ch(12) + '1.5');
        TryDecimal(Observer, 'both sides VT', Ch(11) + '1.5' + Ch(11));
        TryDecimal(Observer, 'leading FF negative', Ch(12) + '-1.5');
        TryDecimal(Observer, 'only VT', Ch(11));
        TryDecimal(Observer, 'only FF', Ch(12));
        Observer.Expect('leading VT', 'Yes 1.5');
        Observer.Expect('leading FF', 'Yes 1.5');
        Observer.Expect('leading VT FF', 'Yes 1.5');
        Observer.Expect('both sides VT', 'Yes 1.5');
        Observer.Expect('leading FF negative', 'Yes -1.5');
        Observer.Expect('only VT', 'No 99');
        Observer.Expect('only VT err|text', '');
        Observer.Expect('only VT err|code', '');
        Observer.Expect('only FF', 'No 99');
        Observer.Expect('only FF err|text', '');
        Observer.Expect('only FF err|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_InnerCarriageReturnVerticalTabFormFeed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDecimal(Observer, 'inner CR', '1' + Ch(13) + '5');
        TryDecimal(Observer, 'inner CRLF', '1' + Ch(13) + Ch(10) + '5');
        TryDecimal(Observer, 'inner VT', '1' + Ch(11) + '5');
        TryDecimal(Observer, 'inner FF', '1' + Ch(12) + '5');
        TryDecimal(Observer, 'CR before decimal point', '1' + Ch(13) + '.5');
        TryDecimal(Observer, 'CR after decimal point', '1.' + Ch(13) + '5');
        TryDecimal(Observer, 'sign then CR', '-' + Ch(13) + '1.5');
        Observer.Expect('inner CR', 'No 99');
        Observer.Expect('inner CR err|text', '');
        Observer.Expect('inner CR err|code', '');
        Observer.Expect('inner CRLF', 'No 99');
        Observer.Expect('inner CRLF err|text', '');
        Observer.Expect('inner CRLF err|code', '');
        Observer.Expect('inner VT', 'No 99');
        Observer.Expect('inner VT err|text', '');
        Observer.Expect('inner VT err|code', '');
        Observer.Expect('inner FF', 'No 99');
        Observer.Expect('inner FF err|text', '');
        Observer.Expect('inner FF err|code', '');
        Observer.Expect('CR before decimal point', 'No 99');
        Observer.Expect('CR before decimal point err|text', '');
        Observer.Expect('CR before decimal point err|code', '');
        Observer.Expect('CR after decimal point', 'No 99');
        Observer.Expect('CR after decimal point err|text', '');
        Observer.Expect('CR after decimal point err|code', '');
        Observer.Expect('sign then CR', 'No 99');
        Observer.Expect('sign then CR err|text', '');
        Observer.Expect('sign then CR err|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_VerticalTabFormFeedCarriageReturn()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryInteger(Observer, 'leading VT', Ch(11) + '15');
        TryInteger(Observer, 'leading FF', Ch(12) + '15');
        TryInteger(Observer, 'leading CR', Ch(13) + '15');
        TryInteger(Observer, 'trailing VT', '15' + Ch(11));
        TryInteger(Observer, 'trailing FF', '15' + Ch(12));
        TryInteger(Observer, 'trailing CR', '15' + Ch(13));
        TryInteger(Observer, 'inner CR', '1' + Ch(13) + '5');
        TryInteger(Observer, 'inner VT', '1' + Ch(11) + '5');
        TryInteger(Observer, 'inner FF', '1' + Ch(12) + '5');
        TryInteger(Observer, 'only FF', Ch(12));
        Observer.Expect('leading VT', 'Yes 15');
        Observer.Expect('leading FF', 'Yes 15');
        Observer.Expect('leading CR', 'Yes 15');
        Observer.Expect('trailing VT', 'Yes 15');
        Observer.Expect('trailing FF', 'Yes 15');
        Observer.Expect('trailing CR', 'Yes 15');
        Observer.Expect('inner CR', 'No 99');
        Observer.Expect('inner CR err|text', '');
        Observer.Expect('inner CR err|code', '');
        Observer.Expect('inner VT', 'No 99');
        Observer.Expect('inner VT err|text', '');
        Observer.Expect('inner VT err|code', '');
        Observer.Expect('inner FF', 'No 99');
        Observer.Expect('inner FF err|text', '');
        Observer.Expect('inner FF err|code', '');
        Observer.Expect('only FF', 'No 99');
        Observer.Expect('only FF err|text', '');
        Observer.Expect('only FF err|code', '');
        Observer.Verify();
    end;
}
