// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 91200
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: Evaluate(Decimal, Text) and Evaluate(Integer, Text) when the text carries white space other than a plain space: a trailing and a leading line feed,
//   carriage return, carriage return plus line feed, tab, non-breaking space (char 160), vertical tab and form feed; white space between the digits; and
//   plain spaces as the reference. Each case records the answer of Evaluate, the value and the error text.
// BC versions: 27, 28, 29
codeunit 91200 "LT SC Eval Decimal WS"
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
        Ok := Evaluate(I, Source);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(I));
        if not Ok then
            Observer.ObserveError(Name + ' err');
    end;

    [Test]
    procedure Decimal_TrailingWhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDecimal(Observer, 'plain', '1.5');
        TryDecimal(Observer, 'trailing space', '1.5 ');
        TryDecimal(Observer, 'trailing LF', '1.5' + Ch(10));
        TryDecimal(Observer, 'trailing CR', '1.5' + Ch(13));
        TryDecimal(Observer, 'trailing CRLF', '1.5' + Ch(13) + Ch(10));
        TryDecimal(Observer, 'trailing TAB', '1.5' + Ch(9));
        TryDecimal(Observer, 'trailing NBSP', '1.5' + Ch(160));
        TryDecimal(Observer, 'trailing VT', '1.5' + Ch(11));
        TryDecimal(Observer, 'trailing FF', '1.5' + Ch(12));
        Observer.Expect('plain', 'Yes 1.5');
        Observer.Expect('trailing space', 'Yes 1.5');
        Observer.Expect('trailing LF', 'Yes 1.5');
        Observer.Expect('trailing CR', 'Yes 1.5');
        Observer.Expect('trailing CRLF', 'Yes 1.5');
        Observer.Expect('trailing TAB', 'Yes 1.5');
        Observer.Expect('trailing NBSP', 'No 99');
        Observer.Expect('trailing NBSP err|text', '');
        Observer.Expect('trailing NBSP err|code', '');
        Observer.Expect('trailing VT', 'Yes 1.5');
        Observer.Expect('trailing FF', 'Yes 1.5');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_LeadingWhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDecimal(Observer, 'leading space', ' 1.5');
        TryDecimal(Observer, 'leading LF', Ch(10) + '1.5');
        TryDecimal(Observer, 'leading CR', Ch(13) + '1.5');
        TryDecimal(Observer, 'leading CRLF', Ch(13) + Ch(10) + '1.5');
        TryDecimal(Observer, 'leading TAB', Ch(9) + '1.5');
        TryDecimal(Observer, 'leading NBSP', Ch(160) + '1.5');
        TryDecimal(Observer, 'both sides LF', Ch(10) + '1.5' + Ch(10));
        TryDecimal(Observer, 'only LF', Ch(10));
        TryDecimal(Observer, 'only spaces', '   ');
        TryDecimal(Observer, 'empty', '');
        Observer.Expect('leading space', 'Yes 1.5');
        Observer.Expect('leading LF', 'Yes 1.5');
        Observer.Expect('leading CR', 'Yes 1.5');
        Observer.Expect('leading CRLF', 'Yes 1.5');
        Observer.Expect('leading TAB', 'Yes 1.5');
        Observer.Expect('leading NBSP', 'No 99');
        Observer.Expect('leading NBSP err|text', '');
        Observer.Expect('leading NBSP err|code', '');
        Observer.Expect('both sides LF', 'Yes 1.5');
        Observer.Expect('only LF', 'No 99');
        Observer.Expect('only LF err|text', '');
        Observer.Expect('only LF err|code', '');
        Observer.Expect('only spaces', 'No 99');
        Observer.Expect('only spaces err|text', '');
        Observer.Expect('only spaces err|code', '');
        Observer.Expect('empty', 'No 99');
        Observer.Expect('empty err|text', '');
        Observer.Expect('empty err|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_InnerWhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryDecimal(Observer, 'inner space', '1 5');
        TryDecimal(Observer, 'inner LF', '1' + Ch(10) + '5');
        TryDecimal(Observer, 'inner TAB', '1' + Ch(9) + '5');
        TryDecimal(Observer, 'sign then space', '- 1.5');
        TryDecimal(Observer, 'sign then LF', '-' + Ch(10) + '1.5');
        TryDecimal(Observer, 'before decimal point LF', '1' + Ch(10) + '.5');
        TryDecimal(Observer, 'negative trailing LF', '-1.5' + Ch(10));
        TryDecimal(Observer, 'thousands separator trailing LF', '1,234.5' + Ch(10));
        Observer.Expect('inner space', 'No 99');
        Observer.Expect('inner space err|text', '');
        Observer.Expect('inner space err|code', '');
        Observer.Expect('inner LF', 'No 99');
        Observer.Expect('inner LF err|text', '');
        Observer.Expect('inner LF err|code', '');
        Observer.Expect('inner TAB', 'No 99');
        Observer.Expect('inner TAB err|text', '');
        Observer.Expect('inner TAB err|code', '');
        Observer.Expect('sign then space', 'No 99');
        Observer.Expect('sign then space err|text', '');
        Observer.Expect('sign then space err|code', '');
        Observer.Expect('sign then LF', 'No 99');
        Observer.Expect('sign then LF err|text', '');
        Observer.Expect('sign then LF err|code', '');
        Observer.Expect('before decimal point LF', 'No 99');
        Observer.Expect('before decimal point LF err|text', '');
        Observer.Expect('before decimal point LF err|code', '');
        Observer.Expect('negative trailing LF', 'Yes -1.5');
        Observer.Expect('thousands separator trailing LF', 'Yes 1234.5');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_WhiteSpace()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryInteger(Observer, 'plain', '15');
        TryInteger(Observer, 'trailing space', '15 ');
        TryInteger(Observer, 'trailing LF', '15' + Ch(10));
        TryInteger(Observer, 'trailing CRLF', '15' + Ch(13) + Ch(10));
        TryInteger(Observer, 'trailing TAB', '15' + Ch(9));
        TryInteger(Observer, 'leading LF', Ch(10) + '15');
        TryInteger(Observer, 'leading TAB', Ch(9) + '15');
        TryInteger(Observer, 'inner LF', '1' + Ch(10) + '5');
        Observer.Expect('plain', 'Yes 15');
        Observer.Expect('trailing space', 'Yes 15');
        Observer.Expect('trailing LF', 'Yes 15');
        Observer.Expect('trailing CRLF', 'Yes 15');
        Observer.Expect('trailing TAB', 'Yes 15');
        Observer.Expect('leading LF', 'Yes 15');
        Observer.Expect('leading TAB', 'Yes 15');
        Observer.Expect('inner LF', 'No 99');
        Observer.Expect('inner LF err|text', '');
        Observer.Expect('inner LF err|code', '');
        Observer.Verify();
    end;
}
