// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73889
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "SelectStr(Option, Text) and other text builtins that take an Integer" (Tests-SCM round 2)
// Facts: an Option value as the Integer argument of SelectStr, CopyStr (position and length), PadStr, CopyStr with Option, Substring; an Option into an Integer parameter of a procedure
// BC versions: 29 (27 and 28 by CI)

codeunit 73889 "LT PnF Option As Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Choice: Option Zero,One,Two,Three;

    [TryFunction]
    local procedure TrySelectStr(O: Option Zero,One,Two,Three; var R: Text)
    begin
        R := SelectStr(O, 'a,b,c,d');
    end;

    [TryFunction]
    local procedure TryCopyStrPos(O: Option Zero,One,Two,Three; var R: Text)
    begin
        R := CopyStr('abcdef', O);
    end;

    [TryFunction]
    local procedure TryCopyStrLen(O: Option Zero,One,Two,Three; var R: Text)
    begin
        R := CopyStr('abcdef', 2, O);
    end;

    [TryFunction]
    local procedure TryPadStr(O: Option Zero,One,Two,Three; var R: Text)
    begin
        R := PadStr('ab', O, '*');
    end;

    [TryFunction]
    local procedure TryStrPos(O: Option Zero,One,Two,Three; var R: Text)
    begin
        R := Format(StrPos('abcabc', 'c') + O);
    end;

    [TryFunction]
    local procedure TryCopyText(O: Option Zero,One,Two,Three; var R: Text)
    var
        T: Text;
    begin
        T := 'abcdef';
        R := T.Substring(O);
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TakeInteger(I: Integer): Text
    begin
        exit(Format(I));
    end;

    [Test]
    procedure OptionAsInteger_SelectStr()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Choice := Choice::Zero;
        Ok := TrySelectStr(Choice, R);
        Observer.Observe('zero', Res(Ok, R));
        Choice := Choice::One;
        Ok := TrySelectStr(Choice, R);
        Observer.Observe('one', Res(Ok, R));
        Choice := Choice::Two;
        Ok := TrySelectStr(Choice, R);
        Observer.Observe('two', Res(Ok, R));
        Choice := Choice::Three;
        Ok := TrySelectStr(Choice, R);
        Observer.Observe('three', Res(Ok, R));
        Observer.Expect('zero', 'error:The SELECTSTR comma-string a,b,c,d does not contain a value for index 0.|InvalidStringFormat');
        Observer.Expect('one', 'a');
        Observer.Expect('two', 'b');
        Observer.Expect('three', 'c');
        Observer.Verify();
    end;

    [Test]
    procedure OptionAsInteger_CopyStr()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Choice := Choice::Two;
        Ok := TryCopyStrPos(Choice, R);
        Observer.Observe('pos_two', Res(Ok, R));
        Ok := TryCopyStrLen(Choice, R);
        Observer.Observe('len_two', Res(Ok, R));
        Choice := Choice::Zero;
        Ok := TryCopyStrPos(Choice, R);
        Observer.Observe('pos_zero', Res(Ok, R));
        Ok := TryCopyStrLen(Choice, R);
        Observer.Observe('len_zero', Res(Ok, R));
        Choice := Choice::Three;
        Ok := TryCopyStrLen(Choice, R);
        Observer.Observe('len_three', Res(Ok, R));
        Observer.Expect('pos_two', 'bcdef');
        Observer.Expect('len_two', 'bc');
        Observer.Expect('pos_zero', 'error:The value of COPYSTR parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2048.|OutsidePermittedRange');
        Observer.Expect('len_zero', '');
        Observer.Expect('len_three', 'bcd');
        Observer.Verify();
    end;

    [Test]
    procedure OptionAsInteger_PadStrStrPosSubstring()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Choice := Choice::Three;
        Ok := TryPadStr(Choice, R);
        Observer.Observe('padstr_three', Res(Ok, R));
        Choice := Choice::One;
        Ok := TryPadStr(Choice, R);
        Observer.Observe('padstr_one', Res(Ok, R));
        Choice := Choice::Two;
        Ok := TryStrPos(Choice, R);
        Observer.Observe('strpos_plus_two', Res(Ok, R));
        Ok := TryCopyText(Choice, R);
        Observer.Observe('substring_two', Res(Ok, R));
        Observer.Expect('padstr_three', 'ab*');
        Observer.Expect('padstr_one', 'a');
        Observer.Expect('strpos_plus_two', '5');
        Observer.Expect('substring_two', 'bcdef');
        Observer.Verify();
    end;

    [Test]
    procedure OptionAsInteger_ProcedureParameter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Choice := Choice::Two;
        Observer.Observe('param', TakeInteger(Choice));
        Observer.Observe('param_literal_member', TakeInteger(Choice::Three));
        Observer.Observe('format_default', Format(Choice));
        Observer.Observe('format_ordinal', Format(Choice, 0, 2));
        Observer.Expect('param', '2');
        Observer.Expect('param_literal_member', '3');
        Observer.Expect('format_default', 'Two');
        Observer.Expect('format_ordinal', '2');
        Observer.Verify();
    end;
}
