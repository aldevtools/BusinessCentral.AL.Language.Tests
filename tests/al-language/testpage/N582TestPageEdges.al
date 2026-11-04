// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 67604, pages 67604 and 67605, codeunit 67604
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// The calls run inside TryFunctions, so a call that raises and one that does not are both observed.
// Facts: TestPage SetValue of a text that is not an Option member (error code, text, Value() afterwards);
// AssertEquals of a number (Integer and Decimal, 10 or more, negative, 1000 or more) against a Text control;
// (SetValue on a FlowField page field crashes the service tier with a NullReferenceException that no TryFunction catches: not pinned.)
// Editable() of a page field over a FlowField with Editable = false.
// BC versions: 27, 28, 29

table 67604 "LT N582 Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(3; Txt; Text[50]) { }
        field(4; Flow; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT N582 Page Row".Dec);
            Editable = false;
        }
        field(5; FlowDefault; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT N582 Page Row".Dec);
        }
        field(6; Plain; Integer)
        {
            Editable = false;
        }
        field(7; Dec; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 67604 "LT N582 Page Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT N582 Page Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Opt; Rec.Opt) { }
            field(Txt; Rec.Txt) { }
            field(Flow; Rec.Flow) { }
            field(FlowDefault; Rec.FlowDefault) { }
            field(Plain; Rec.Plain) { }
            field(Dec; Rec.Dec) { }
        }
    }
}

page 67605 "LT N582 Page List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT N582 Page Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(Flow; Rec.Flow) { }
                field(FlowDefault; Rec.FlowDefault) { }
                field(Plain; Rec.Plain) { }
            }
        }
    }
}

codeunit 67604 "LT N582 Test Page Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT N582 Page Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TrySetOpt(var Pg: TestPage "LT N582 Page Card"; Txt: Text)
    begin
        Pg.Opt.SetValue(Txt);
    end;

    [TryFunction]
    local procedure TryOptValue(var Pg: TestPage "LT N582 Page Card"; var Result: Text)
    begin
        Result := Pg.Opt.Value();
    end;

    [TryFunction]
    local procedure TryTxtAssert(var Pg: TestPage "LT N582 Page Card"; Expected: Variant)
    begin
        Pg.Txt.AssertEquals(Expected);
    end;

    local procedure SetOpt(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Pg: TestPage "LT N582 Page Card";
        Shown: Text;
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Opt.SetValue('One');
        if TrySetOpt(Pg, Txt) then
            Observer.Observe(Name, 'no error')
        else
            Observer.ObserveError(Name);
        if TryOptValue(Pg, Shown) then
            Observer.Observe(Name + '|value', Shown)
        else
            Observer.ObserveError(Name + '|value');
    end;

    local procedure NumVsText(var Observer: Codeunit "Probe Observer"; Name: Text; Shown: Text; Expected: Variant)
    var
        Pg: TestPage "LT N582 Page Card";
    begin
        Seed();
        Pg.OpenEdit();
        Pg.Txt.SetValue(Shown);
        Observer.Observe(Name + '|shown', Pg.Txt.Value());
        if TryTxtAssert(Pg, Expected) then
            Observer.Observe(Name, 'equal')
        else
            Observer.ObserveError(Name);
        Pg.Close();
    end;

    [Test]
    procedure N582_SetValue_OptionText_NotAMember()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetOpt(Observer, 'Nope', 'Nope');
        SetOpt(Observer, 'lower case member', 'two');
        SetOpt(Observer, 'empty', '');
        SetOpt(Observer, 'out of range number', '5');
        SetOpt(Observer, 'in range number', '2');
        SetOpt(Observer, 'member with blank', 'Two ');
        SetOpt(Observer, 'prefix of member', 'Tw');
        Observer.Expect('Nope|text', 'Validation error for Field: Opt,  Message = ''Your entry of ''Nope'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('Nope|code', 'TestValidation');
        Observer.Expect('Nope|value', '1');
        Observer.Expect('lower case member', 'no error');
        Observer.Expect('lower case member|value', 'Two');
        Observer.Expect('empty|text', 'Validation error for Field: Opt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('empty|code', 'TestValidation');
        Observer.Expect('empty|value', '1');
        Observer.Expect('out of range number|text', 'Validation error for Field: Opt,  Message = ''Your entry of ''5'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('out of range number|code', 'TestValidation');
        Observer.Expect('out of range number|value', '1');
        Observer.Expect('in range number|text', 'Validation error for Field: Opt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('in range number|code', 'TestValidation');
        Observer.Expect('in range number|value', '1');
        Observer.Expect('member with blank', 'no error');
        Observer.Expect('member with blank|value', 'Two');
        Observer.Expect('prefix of member|text', 'Validation error for Field: Opt,  Message = ''Your entry of ''Tw'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('prefix of member|code', 'TestValidation');
        Observer.Expect('prefix of member|value', '1');
        Observer.Verify();
    end;

    [Test]
    procedure N582_AssertEquals_NumberOnTextControl_Integer()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 5;
        NumVsText(Observer, 'int 5 vs 5', '5', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs 10', '10', I);
        I := 123;
        NumVsText(Observer, 'int 123 vs 123', '123', I);
        I := 12345;
        NumVsText(Observer, 'int 12345 vs 12345', '12345', I);
        I := 1234567;
        NumVsText(Observer, 'int 1234567 vs 1234567', '1234567', I);
        I := 1234567;
        NumVsText(Observer, 'int 1234567 vs grouped', '1,234,567', I);
        I := -5;
        NumVsText(Observer, 'int -5 vs -5', '-5', I);
        I := -10;
        NumVsText(Observer, 'int -10 vs -10', '-10', I);
        I := -1234;
        NumVsText(Observer, 'int -1234 vs -1234', '-1234', I);
        I := 0;
        NumVsText(Observer, 'int 0 vs 0', '0', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs 11', '11', I);
        I := 10;
        NumVsText(Observer, 'int 10 vs text', 'ten', I);
        Observer.Expect('int 5 vs 5|shown', '5');
        Observer.Expect('int 5 vs 5', 'equal');
        Observer.Expect('int 10 vs 10|shown', '10');
        Observer.Expect('int 10 vs 10', 'equal');
        Observer.Expect('int 123 vs 123|shown', '123');
        Observer.Expect('int 123 vs 123', 'equal');
        Observer.Expect('int 12345 vs 12345|shown', '12345');
        Observer.Expect('int 12345 vs 12345', 'equal');
        Observer.Expect('int 1234567 vs 1234567|shown', '1234567');
        Observer.Expect('int 1234567 vs 1234567', 'equal');
        Observer.Expect('int 1234567 vs grouped|shown', '1,234,567');
        Observer.Expect('int 1234567 vs grouped|text', 'AssertEquals for Field: Txt Expected = ''1234567'', Actual = ''1,234,567''');
        Observer.Expect('int 1234567 vs grouped|code', 'TestAssertEquals');
        Observer.Expect('int -5 vs -5|shown', '-5');
        Observer.Expect('int -5 vs -5', 'equal');
        Observer.Expect('int -10 vs -10|shown', '-10');
        Observer.Expect('int -10 vs -10', 'equal');
        Observer.Expect('int -1234 vs -1234|shown', '-1234');
        Observer.Expect('int -1234 vs -1234', 'equal');
        Observer.Expect('int 0 vs 0|shown', '0');
        Observer.Expect('int 0 vs 0', 'equal');
        Observer.Expect('int 10 vs 11|shown', '11');
        Observer.Expect('int 10 vs 11|text', 'AssertEquals for Field: Txt Expected = ''10'', Actual = ''11''');
        Observer.Expect('int 10 vs 11|code', 'TestAssertEquals');
        Observer.Expect('int 10 vs text|shown', 'ten');
        Observer.Expect('int 10 vs text|text', 'AssertEquals for Field: Txt Expected = ''10'', Actual = ''ten''');
        Observer.Expect('int 10 vs text|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure N582_AssertEquals_NumberOnTextControl_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 5;
        NumVsText(Observer, 'dec 5 vs 5', '5', D);
        D := 10;
        NumVsText(Observer, 'dec 10 vs 10', '10', D);
        D := 1.5;
        NumVsText(Observer, 'dec 1.5 vs 1.5', '1.5', D);
        D := 999.99;
        NumVsText(Observer, 'dec 999.99 vs 999.99', '999.99', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs 1000', '1000', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs grouped', '1,000', D);
        D := 1234.5;
        NumVsText(Observer, 'dec 1234.5 vs 1234.5', '1234.5', D);
        D := 1234.5;
        NumVsText(Observer, 'dec 1234.5 vs grouped', '1,234.5', D);
        D := 1234567.89;
        NumVsText(Observer, 'dec 1234567.89 vs plain', '1234567.89', D);
        D := 1234567.89;
        NumVsText(Observer, 'dec 1234567.89 vs grouped', '1,234,567.89', D);
        D := -1000;
        NumVsText(Observer, 'dec -1000 vs -1000', '-1000', D);
        D := -1234.5;
        NumVsText(Observer, 'dec -1234.5 vs grouped', '-1,234.5', D);
        D := -0.5;
        NumVsText(Observer, 'dec -0.5 vs -0.5', '-0.5', D);
        D := 0;
        NumVsText(Observer, 'dec 0 vs 0', '0', D);
        D := 1000;
        NumVsText(Observer, 'dec 1000 vs 1001', '1001', D);
        Observer.Expect('dec 5 vs 5|shown', '5');
        Observer.Expect('dec 5 vs 5', 'equal');
        Observer.Expect('dec 10 vs 10|shown', '10');
        Observer.Expect('dec 10 vs 10', 'equal');
        Observer.Expect('dec 1.5 vs 1.5|shown', '1.5');
        Observer.Expect('dec 1.5 vs 1.5', 'equal');
        Observer.Expect('dec 999.99 vs 999.99|shown', '999.99');
        Observer.Expect('dec 999.99 vs 999.99', 'equal');
        Observer.Expect('dec 1000 vs 1000|shown', '1000');
        Observer.Expect('dec 1000 vs 1000|text', 'AssertEquals for Field: Txt Expected = ''1,000'', Actual = ''1000''');
        Observer.Expect('dec 1000 vs 1000|code', 'TestAssertEquals');
        Observer.Expect('dec 1000 vs grouped|shown', '1,000');
        Observer.Expect('dec 1000 vs grouped', 'equal');
        Observer.Expect('dec 1234.5 vs 1234.5|shown', '1234.5');
        Observer.Expect('dec 1234.5 vs 1234.5|text', 'AssertEquals for Field: Txt Expected = ''1,234.5'', Actual = ''1234.5''');
        Observer.Expect('dec 1234.5 vs 1234.5|code', 'TestAssertEquals');
        Observer.Expect('dec 1234.5 vs grouped|shown', '1,234.5');
        Observer.Expect('dec 1234.5 vs grouped', 'equal');
        Observer.Expect('dec 1234567.89 vs plain|shown', '1234567.89');
        Observer.Expect('dec 1234567.89 vs plain|text', 'AssertEquals for Field: Txt Expected = ''1,234,567.89'', Actual = ''1234567.89''');
        Observer.Expect('dec 1234567.89 vs plain|code', 'TestAssertEquals');
        Observer.Expect('dec 1234567.89 vs grouped|shown', '1,234,567.89');
        Observer.Expect('dec 1234567.89 vs grouped', 'equal');
        Observer.Expect('dec -1000 vs -1000|shown', '-1000');
        Observer.Expect('dec -1000 vs -1000|text', 'AssertEquals for Field: Txt Expected = ''-1,000'', Actual = ''-1000''');
        Observer.Expect('dec -1000 vs -1000|code', 'TestAssertEquals');
        Observer.Expect('dec -1234.5 vs grouped|shown', '-1,234.5');
        Observer.Expect('dec -1234.5 vs grouped', 'equal');
        Observer.Expect('dec -0.5 vs -0.5|shown', '-0.5');
        Observer.Expect('dec -0.5 vs -0.5', 'equal');
        Observer.Expect('dec 0 vs 0|shown', '0');
        Observer.Expect('dec 0 vs 0', 'equal');
        Observer.Expect('dec 1000 vs 1001|shown', '1001');
        Observer.Expect('dec 1000 vs 1001|text', 'AssertEquals for Field: Txt Expected = ''1,000'', Actual = ''1001''');
        Observer.Expect('dec 1000 vs 1001|code', 'TestAssertEquals');
        Observer.Verify();
    end;

    [Test]
    procedure N582_Editable_FlowFieldNotEditable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT N582 Page Card";
        List: TestPage "LT N582 Page List";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('card flow Editable=false', Format(Card.Flow.Editable()));
        Observer.Observe('card flow default', Format(Card.FlowDefault.Editable()));
        Observer.Observe('card plain Editable=false', Format(Card.Plain.Editable()));
        Observer.Observe('card id', Format(Card.Id.Editable()));
        Observer.Observe('card flow value', Card.Flow.Value());
        Card.Close();
        List.OpenEdit();
        Observer.Observe('list flow Editable=false', Format(List.Flow.Editable()));
        Observer.Observe('list flow default', Format(List.FlowDefault.Editable()));
        Observer.Observe('list plain Editable=false', Format(List.Plain.Editable()));
        List.Close();
        Card.OpenView();
        Observer.Observe('view card flow', Format(Card.Flow.Editable()));
        Observer.Observe('view card id', Format(Card.Id.Editable()));
        Card.Close();
        Observer.Expect('card flow Editable=false', 'No');
        Observer.Expect('card flow default', 'Yes');
        Observer.Expect('card plain Editable=false', 'No');
        Observer.Expect('card id', 'Yes');
        Observer.Expect('card flow value', '0.00');
        Observer.Expect('list flow Editable=false', 'No');
        Observer.Expect('list flow default', 'Yes');
        Observer.Expect('list plain Editable=false', 'No');
        Observer.Expect('view card flow', 'No');
        Observer.Expect('view card id', 'No');
        Observer.Verify();
    end;

    // Corpus issue 668 item 62 (writer br): a FlowFilter field as the source of a page control: Editable() on a card in edit and view
    // mode and on a list, and what SetValue on it does to the control and to a FlowField that uses the filter.
    local procedure BrSeed()
    var
        Row: Record "LT BR FF Page Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Amt := 5;
        Row.Insert();
        Row.Id := 2;
        Row.Amt := 7;
        Row.Insert();
    end;

    [Test]
    procedure BR_Editable_FlowFilterControl()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT BR FF Page Card";
        List: TestPage "LT BR FF Page List";
    begin
        BrSeed();
        Card.OpenEdit();
        Observer.Observe('card edit amtfilter', Format(Card.AmtFilter.Editable()));
        Observer.Observe('card edit datefilter', Format(Card.DateFilter.Editable()));
        Observer.Observe('card edit total', Format(Card.Total.Editable()));
        Observer.Observe('card edit amt', Format(Card.Amt.Editable()));
        Observer.Observe('card edit amtfilter value', Card.AmtFilter.Value());
        Card.Close();
        Card.OpenView();
        Observer.Observe('card view amtfilter', Format(Card.AmtFilter.Editable()));
        Card.Close();
        List.OpenEdit();
        Observer.Observe('list edit amtfilter', Format(List.AmtFilter.Editable()));
        List.Close();
        Observer.Expect('card edit amtfilter', 'Yes');
        Observer.Expect('card edit datefilter', 'Yes');
        Observer.Expect('card edit total', 'No');
        Observer.Expect('card edit amt', 'Yes');
        Observer.Expect('card edit amtfilter value', '');
        Observer.Expect('card view amtfilter', 'No');
        Observer.Expect('list edit amtfilter', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BrTrySetFilterControl(var Card: TestPage "LT BR FF Page Card"; NewValue: Text)
    begin
        Card.AmtFilter.SetValue(NewValue);
    end;

    [Test]
    procedure BR_SetValue_FlowFilterControl()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT BR FF Page Card";
    begin
        BrSeed();
        Card.OpenEdit();
        Card.First();
        Observer.Observe('total before', Card.Total.Value());
        ClearLastError();
        if BrTrySetFilterControl(Card, '7') then
            Observer.Observe('setvalue 7', 'ok|' + Card.AmtFilter.Value() + '|total=' + Card.Total.Value())
        else
            Observer.Observe('setvalue 7', 'error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        Card.Close();
        Observer.Expect('total before', '12.00');
        Observer.Expect('setvalue 7', 'ok|7.00|total=12.00');
        Observer.Verify();
    end;
}

table 82963 "LT BR FF Page Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal) { }
        field(3; AmtFilter; Decimal) { FieldClass = FlowFilter; }
        field(4; DateFilter; Date) { FieldClass = FlowFilter; }
        field(5; Total; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("LT BR FF Page Row".Amt where(Amt = field(AmtFilter)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 82963 "LT BR FF Page Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT BR FF Page Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { }
            field(Amt; Rec.Amt) { }
            field(AmtFilter; Rec.AmtFilter) { }
            field(DateFilter; Rec.DateFilter) { }
            field(Total; Rec.Total) { }
        }
    }
}

page 82964 "LT BR FF Page List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT BR FF Page Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
                field(AmtFilter; Rec.AmtFilter) { }
            }
        }
    }
}
