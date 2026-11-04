// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73179, codeunit 73178
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: a FieldRef as the first argument of Evaluate (Microsoft's Config. Package Management does it); if it does not compile, drop the file.
// Facts: Evaluate(FieldRef, Text): the field takes the value for a Text, Code, Integer, Decimal, Boolean, Date and Option field, the Boolean result for text that does not fit, and the field after a failure.
// BC versions: 29 (27 and 28 by CI)

table 73179 "LT P128 Eval Fld"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[10]) { }
        field(3; Cd; Code[10]) { }
        field(4; Dt; Date) { }
        field(5; Dec; Decimal) { }
        field(6; Flag; Boolean) { }
        field(7; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
        }
        field(8; Num; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73178 "LT P128 Eval FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalInto(var Observer: Codeunit "Probe Observer"; Name: Text; FieldNo: Integer; Txt: Text)
    var
        Row: Record "LT P128 Eval Fld";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Ok: Boolean;
    begin
        Row.Id := 1;
        Row.Txt := 'KEEP';
        Row.Cd := 'KEEP';
        Row.Dt := 20240101D;
        Row.Dec := 9;
        Row.Flag := false;
        Row.Opt := Row.Opt::One;
        Row.Num := 9;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(FieldNo);
        Ok := Evaluate(FldRef, Txt);
        Observer.Observe(Name, Format(Ok) + '|' + Format(FldRef.Value));
    end;

    [Test]
    procedure P128_Evaluate_IntoFieldRef_TextAndCode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalInto(Observer, 'text hello', 2, 'hello');
        EvalInto(Observer, 'text empty', 2, '');
        EvalInto(Observer, 'text too long', 2, 'abcdefghijkl');
        EvalInto(Observer, 'code lower', 3, 'abc');
        EvalInto(Observer, 'code empty', 3, '');
        EvalInto(Observer, 'code too long', 3, 'abcdefghijkl');
        Observer.Expect('text hello', 'Yes|hello');
        Observer.Expect('text empty', 'Yes|');
        Observer.Expect('text too long', 'No|KEEP');
        Observer.Expect('code lower', 'Yes|ABC');
        Observer.Expect('code empty', 'Yes|');
        Observer.Expect('code too long', 'No|KEEP');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_IntoFieldRef_Numbers_Date_Boolean_Option()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalInto(Observer, 'integer 12', 8, '12');
        EvalInto(Observer, 'integer text', 8, 'abc');
        EvalInto(Observer, 'integer empty', 8, '');
        EvalInto(Observer, 'decimal', 5, '1.5');
        EvalInto(Observer, 'decimal text', 5, 'x');
        EvalInto(Observer, 'date', 4, '01/02/24');
        EvalInto(Observer, 'date iso', 4, '2024-02-01');
        EvalInto(Observer, 'date text', 4, 'x');
        EvalInto(Observer, 'boolean yes', 6, 'Yes');
        EvalInto(Observer, 'boolean text', 6, 'x');
        EvalInto(Observer, 'option member', 7, 'Two');
        EvalInto(Observer, 'option ordinal', 7, '2');
        EvalInto(Observer, 'option text', 7, 'Three');
        Observer.Expect('integer 12', 'Yes|12');
        Observer.Expect('integer text', 'No|9');
        Observer.Expect('integer empty', 'No|9');
        Observer.Expect('decimal', 'Yes|1.5');
        Observer.Expect('decimal text', 'No|9');
        Observer.Expect('date', 'Yes|01/02/24');
        Observer.Expect('date iso', 'Yes|02/01/24');
        Observer.Expect('date text', 'No|01/01/24');
        Observer.Expect('boolean yes', 'Yes|Yes');
        Observer.Expect('boolean text', 'No|No');
        Observer.Expect('option member', 'Yes|Two');
        Observer.Expect('option ordinal', 'Yes|Two');
        Observer.Expect('option text', 'No|One');
        Observer.Verify();
    end;

    // Corpus issue 670 (AL issue 812): an Option field read through a FieldRef, its Format compared against text and evaluated from empty text,
    // and Type Helper GetOptionNo on the field's OptionMembers and OptionCaption. Writer CY.
    [TryFunction]
    local procedure TryCompare(var FldRef: FieldRef; Txt: Text; var Equal: Boolean)
    begin
        // FldRef.Value = Txt does not compile (AL0175, must-not-compile case 1792): the text form of the value is compared.
        Equal := Format(FldRef.Value) = Txt;
    end;

    local procedure CompareText(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        Row: Record "LT P128 Eval Fld";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Equal: Boolean;
    begin
        Row.Id := 1;
        Row.Opt := Row.Opt::Two;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(7);
        ClearLastError();
        if TryCompare(FldRef, Txt, Equal) then
            Observer.Observe(Name, Format(Equal))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure CY_OptionFieldRef_CompareWithText_Evaluate_GetOptionNo()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P128 Eval Fld";
        RecRef: RecordRef;
        FldRef: FieldRef;
        TypeHelper: Codeunit "Type Helper";
    begin
        CompareText(Observer, 'compare member name', 'Two');
        CompareText(Observer, 'compare other member', 'One');
        CompareText(Observer, 'compare lower case', 'two');
        CompareText(Observer, 'compare ordinal text', '2');
        CompareText(Observer, 'compare empty', '');
        CompareText(Observer, 'compare not a member', 'Three');
        EvalInto(Observer, 'evaluate lower case', 7, 'two');
        EvalInto(Observer, 'evaluate prefix', 7, 'Tw');
        EvalInto(Observer, 'evaluate space', 7, ' ');
        Row.Id := 1;
        RecRef.GetTable(Row);
        FldRef := RecRef.Field(7);
        Observer.Observe('members', FldRef.OptionMembers);
        Observer.Observe('caption', FldRef.OptionCaption);
        Observer.Observe('getoptionno member', Format(TypeHelper.GetOptionNo('Two', FldRef.OptionMembers)));
        Observer.Observe('getoptionno caption', Format(TypeHelper.GetOptionNo('Two', FldRef.OptionCaption)));
        Observer.Observe('getoptionno lower case', Format(TypeHelper.GetOptionNo('two', FldRef.OptionCaption)));
        Observer.Observe('getoptionno empty', Format(TypeHelper.GetOptionNo('', FldRef.OptionCaption)));
        Observer.Observe('getoptionno not a member', Format(TypeHelper.GetOptionNo('Three', FldRef.OptionCaption)));
        Observer.Observe('getoptionno first', Format(TypeHelper.GetOptionNo('Zero', FldRef.OptionCaption)));
        Observer.Expect('compare member name', 'Yes');
        Observer.Expect('compare other member', 'No');
        Observer.Expect('compare lower case', 'No');
        Observer.Expect('compare ordinal text', 'No');
        Observer.Expect('compare empty', 'No');
        Observer.Expect('compare not a member', 'No');
        Observer.Expect('evaluate lower case', 'Yes|Two');
        Observer.Expect('evaluate prefix', 'No|One');
        Observer.Expect('evaluate space', 'No|One');
        Observer.Expect('members', 'Zero,One,Two');
        Observer.Expect('caption', 'Zero,One,Two');
        Observer.Expect('getoptionno member', '2');
        Observer.Expect('getoptionno caption', '2');
        Observer.Expect('getoptionno lower case', '2');
        Observer.Expect('getoptionno empty', '-1');
        Observer.Expect('getoptionno not a member', '-1');
        Observer.Expect('getoptionno first', '0');
        Observer.Verify();
    end;
}
