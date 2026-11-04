// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-assertequals-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74878, page 74879, test codeunit 74885
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: (1) TestPage field AssertEquals with an Integer, Decimal, BigInteger, Text and Boolean argument on a Text control and on a Code control whose value is the
//   same digits (equal, leading zero, different digits, blank): no error or the error text. Settles testpage-assertequals-integer-on-text-control.
//   (2) SetValue on an Option control whose OptionCaption starts with a blank member (' ,A,B'): the blank member as an Option value, as ' ' and as '' text, then
//   the control value and the stored value after leaving the row. Settles testpage-setvalue-blank-option-member.
// BC versions: all (CI)

table 74878 "LT TAO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cde; Code[30]) { }
        field(4; Opt; Option) { OptionMembers = " ",A,B; OptionCaption = ' ,A,B'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 74879 "LT TAO Card"
{
    PageType = Card;
    SourceTable = "LT TAO Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Txt; Rec.Txt) { ApplicationArea = All; }
            field(Cde; Rec.Cde) { ApplicationArea = All; }
            field(Opt; Rec.Opt) { ApplicationArea = All; }
        }
    }
}

codeunit 74885 "LT TAO Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(TxtValue: Text; CdeValue: Text; OptValue: Option " ",A,B)
    var
        Row: Record "LT TAO Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Txt := CopyStr(TxtValue, 1, MaxStrLen(Row.Txt));
        Row.Cde := CopyStr(CdeValue, 1, MaxStrLen(Row.Cde));
        Row.Opt := OptValue;
        Row.Insert();
    end;

    local procedure OptNo(R: Record "LT TAO Row"): Integer
    var
        N: Integer;
    begin
        N := R.Opt;
        exit(N);
    end;

    [TryFunction]
    local procedure TryTxt(var TP: TestPage "LT TAO Card"; Expected: Variant)
    begin
        TP.Txt.AssertEquals(Expected);
    end;

    [TryFunction]
    local procedure TryCde(var TP: TestPage "LT TAO Card"; Expected: Variant)
    begin
        TP.Cde.AssertEquals(Expected);
    end;

    local procedure CaseTxt(var Observer: Codeunit "Probe Observer"; Tag: Text; Stored: Text; Expected: Variant)
    var
        TP: TestPage "LT TAO Card";
        Ok: Boolean;
    begin
        Seed(Stored, '', 0);
        TP.OpenEdit();
        Ok := TryTxt(TP, Expected);
        Observer.Observe(Tag, Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + 'Err');
        TP.Close();
    end;

    local procedure CaseCde(var Observer: Codeunit "Probe Observer"; Tag: Text; Stored: Text; Expected: Variant)
    var
        TP: TestPage "LT TAO Card";
        Ok: Boolean;
    begin
        Seed('', Stored, 0);
        TP.OpenEdit();
        Ok := TryCde(TP, Expected);
        Observer.Observe(Tag, Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + 'Err');
        TP.Close();
    end;

    [Test]
    procedure AssertEquals_TextControl_NumbersAndText()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
    begin
        Big := 5;
        Dec := 5.5;
        CaseTxt(Observer, 'text5-int5', '5', 5);
        CaseTxt(Observer, 'text5-text5', '5', '5');
        CaseTxt(Observer, 'text5-int6', '5', 6);
        CaseTxt(Observer, 'text05-int5', '05', 5);
        CaseTxt(Observer, 'text5-big5', '5', Big);
        CaseTxt(Observer, 'text5.5-dec5.5', '5.5', Dec);
        CaseTxt(Observer, 'text5-dec5', '5', 5.0);
        CaseTxt(Observer, 'textAbc-int5', 'abc', 5);
        CaseTxt(Observer, 'textBlank-int0', '', 0);
        CaseTxt(Observer, 'text0-int0', '0', 0);
        CaseTxt(Observer, 'textTrue-bool', 'Yes', true);
        Observer.Expect('text5-int5', 'Yes');
        Observer.Expect('text5-text5', 'Yes');
        Observer.Expect('text5-int6', 'No');
        Observer.Expect('text5-int6Err|text', 'AssertEquals for Field: Txt Expected = ''6'', Actual = ''5''');
        Observer.Expect('text5-int6Err|code', 'TestAssertEquals');
        Observer.Expect('text05-int5', 'No');
        Observer.Expect('text05-int5Err|text', 'AssertEquals for Field: Txt Expected = ''5'', Actual = ''05''');
        Observer.Expect('text05-int5Err|code', 'TestAssertEquals');
        Observer.Expect('text5-big5', 'Yes');
        Observer.Expect('text5.5-dec5.5', 'Yes');
        Observer.Expect('text5-dec5', 'Yes');
        Observer.Expect('textAbc-int5', 'No');
        Observer.Expect('textAbc-int5Err|text', 'AssertEquals for Field: Txt Expected = ''5'', Actual = ''abc''');
        Observer.Expect('textAbc-int5Err|code', 'TestAssertEquals');
        Observer.Expect('textBlank-int0', 'No');
        Observer.Expect('textBlank-int0Err|text', 'AssertEquals for Field: Txt Expected = ''0'', Actual = ''''');
        Observer.Expect('textBlank-int0Err|code', 'TestAssertEquals');
        Observer.Expect('text0-int0', 'Yes');
        Observer.Expect('textTrue-bool', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AssertEquals_CodeControl_NumbersAndText()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Dec: Decimal;
    begin
        Big := 5;
        Dec := 5.5;
        CaseCde(Observer, 'code5-int5', '5', 5);
        CaseCde(Observer, 'code5-text5', '5', '5');
        CaseCde(Observer, 'code5-int6', '5', 6);
        CaseCde(Observer, 'code05-int5', '05', 5);
        CaseCde(Observer, 'code5-big5', '5', Big);
        CaseCde(Observer, 'code5.5-dec5.5', '5.5', Dec);
        CaseCde(Observer, 'codeAbc-text-abc', 'ABC', 'abc');
        CaseCde(Observer, 'codeBlank-int0', '', 0);
        Observer.Expect('code5-int5', 'Yes');
        Observer.Expect('code5-text5', 'Yes');
        Observer.Expect('code5-int6', 'No');
        Observer.Expect('code5-int6Err|text', 'AssertEquals for Field: Cde Expected = ''6'', Actual = ''5''');
        Observer.Expect('code5-int6Err|code', 'TestAssertEquals');
        Observer.Expect('code05-int5', 'No');
        Observer.Expect('code05-int5Err|text', 'AssertEquals for Field: Cde Expected = ''5'', Actual = ''05''');
        Observer.Expect('code05-int5Err|code', 'TestAssertEquals');
        Observer.Expect('code5-big5', 'Yes');
        Observer.Expect('code5.5-dec5.5', 'Yes');
        Observer.Expect('codeAbc-text-abc', 'Yes');
        Observer.Expect('codeBlank-int0', 'No');
        Observer.Expect('codeBlank-int0Err|text', 'AssertEquals for Field: Cde Expected = ''0'', Actual = ''''');
        Observer.Expect('codeBlank-int0Err|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_BlankOption_AsMember()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TAO Row";
        TP: TestPage "LT TAO Card";
    begin
        Seed('', '', 1);
        TP.OpenEdit();
        Observer.Observe('start', TP.Opt.Value());
        TP.Opt.SetValue(Row.Opt::" ");
        Observer.Observe('afterMember', '[' + TP.Opt.Value() + ']');
        TP.Close();
        Row.Get(1);
        Observer.Observe('stored', Format(OptNo(Row)));
        Observer.Expect('start', 'A');
        Observer.Expect('afterMember', '[ ]');
        Observer.Expect('stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_BlankOption_AsSpaceText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TAO Row";
        TP: TestPage "LT TAO Card";
    begin
        Seed('', '', 1);
        TP.OpenEdit();
        TP.Opt.SetValue(' ');
        Observer.Observe('afterSpace', '[' + TP.Opt.Value() + ']');
        TP.Close();
        Row.Get(1);
        Observer.Observe('stored', Format(OptNo(Row)));
        Observer.Expect('afterSpace', '[ ]');
        Observer.Expect('stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_BlankOption_AsEmptyText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TAO Row";
        TP: TestPage "LT TAO Card";
    begin
        Seed('', '', 1);
        TP.OpenEdit();
        asserterror TP.Opt.SetValue('');
        Observer.ObserveError('setEmpty');
        Observer.Observe('afterEmpty', '[' + TP.Opt.Value() + ']');
        TP.Close();
        Row.Get(1);
        Observer.Observe('stored', Format(OptNo(Row)));
        Observer.Expect('setEmpty|text', 'Validation error for Field: Opt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('setEmpty|code', 'TestValidation');
        Observer.Expect('afterEmpty', '[1]');
        Observer.Expect('stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Option_AsOtherMemberTypes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT TAO Row";
        TP: TestPage "LT TAO Card";
    begin
        Seed('', '', 0);
        TP.OpenEdit();
        TP.Opt.SetValue('B');
        Observer.Observe('afterB', '[' + TP.Opt.Value() + ']');
        TP.Opt.SetValue(Row.Opt::A);
        Observer.Observe('afterMemberA', '[' + TP.Opt.Value() + ']');
        TP.Opt.SetValue(2);
        Observer.Observe('afterInteger2', '[' + TP.Opt.Value() + ']');
        TP.Close();
        Row.Get(1);
        Observer.Observe('stored', Format(OptNo(Row)));
        Observer.Expect('afterB', '[B]');
        Observer.Expect('afterMemberA', '[A]');
        Observer.Expect('afterInteger2', '[B]');
        Observer.Expect('stored', '2');
        Observer.Verify();
    end;
}
