// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI EE *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Error('') (an error with an empty text) raised from a TestPage action's Invoke, from a control OnValidate (SetValue) and from an
//   OnOpenPage (OpenEdit), with and without asserterror, next to Error('text') and a [TryFunction] that raises Error(''): whether the
//   test method goes on, GetLastErrorText / GetLastErrorCode, and whether the rows the trigger wrote before the error stay.
// Settles al-runtime-rs docs/probes-needed.md row "An error with an empty text (Error('')) out of a TestPage action's Invoke"
//   (Gen. Jnl.-Post Preview ends every posting preview with Error(''); Tests-ERM 134760, 134762, 134227).
// BC versions: 29 (27 and 28 by CI)

table 86850 "LT QI EE Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 86851 "LT QI EE Card"
{
    PageType = Card;
    SourceTable = "LT QI EE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(NameCtl; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        WriteMark(300, 'validate ' + Rec.Name);
                        if Rec.Name = 'empty' then
                            Error('');
                        if Rec.Name = 'text' then
                            Error('LT QI validate error');
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EmptyAct)
            {
                ApplicationArea = All;
                Caption = 'Empty error';

                trigger OnAction()
                begin
                    WriteMark(100, 'empty action ran');
                    Error('');
                end;
            }
            action(TextAct)
            {
                ApplicationArea = All;
                Caption = 'Text error';

                trigger OnAction()
                begin
                    WriteMark(101, 'text action ran');
                    Error('LT QI action error');
                end;
            }
            action(TryEmptyAct)
            {
                ApplicationArea = All;
                Caption = 'Try empty error';

                trigger OnAction()
                var
                    Ok: Boolean;
                begin
                    Ok := TryEmpty();
                    WriteMark(102, 'try=' + Format(Ok) + ' text=[' + GetLastErrorText() + '] code=[' + GetLastErrorCode() + ']');
                end;
            }
        }
    }

    [TryFunction]
    local procedure TryEmpty()
    begin
        Error('');
    end;

    local procedure WriteMark(WriteId: Integer; WriteName: Text)
    var
        Row: Record "LT QI EE Row";
    begin
        Row.Init();
        Row.Id := WriteId;
        Row.Name := CopyStr(WriteName, 1, MaxStrLen(Row.Name));
        if not Row.Insert() then
            Row.Modify();
    end;
}

page 86852 "LT QI EE Open Card"
{
    PageType = Card;
    SourceTable = "LT QI EE Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Row: Record "LT QI EE Row";
    begin
        Row.Init();
        Row.Id := 200;
        Row.Name := 'open ran';
        Row.Insert();
        Error('');
    end;
}

codeunit 86853 "LT QI EE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QI EE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'seed';
        Row.Insert();
        ClearLastError();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT QI EE Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + '=' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Result);
    end;

    // asserterror rolls back every write of the test method, Seed() included, so the rows the previous test method left are back
    // (seen on BC 29): ask only for the row the trigger wrote before its error.
    local procedure Kept(MarkerId: Integer; MarkerName: Text): Text
    var
        Row: Record "LT QI EE Row";
    begin
        if not Row.Get(MarkerId) then
            exit(Format(false));
        exit(Format(Row.Name = MarkerName));
    end;

    // ---- action Invoke ----

    [Test]
    procedure QI_EE_EmptyAction_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.EmptyAct.Invoke();
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-invoke');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-invoke|text', '');
        Observer.Expect('after-invoke|code', 'Dialog');
        Observer.Expect('rows', '1=seed;100=empty action ran;');
        Observer.Expect('name-after', 'seed');
        Observer.Verify();
    end;

    [Test]
    procedure QI_EE_TextAction_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.TextAct.Invoke();
        Observer.ObserveError('invoke');
        Observer.Observe('marker-kept', Kept(101, 'text action ran'));
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Expect('invoke|text', 'LT QI action error');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('marker-kept', 'No');
        Observer.Expect('name-after', 'seed');
        Observer.Verify();
    end;

    [Test]
    procedure QI_EE_TryEmptyAction()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.TryEmptyAct.Invoke();
        Observer.ObserveError('after-invoke');
        Observer.Observe('rows', Rows());
        Card.Close();
        Observer.Expect('after-invoke|text', '');
        Observer.Expect('after-invoke|code', 'Dialog');
        Observer.Expect('rows', '1=seed;102=try=No text=[] code=[Dialog];');
        Observer.Verify();
    end;

    // ---- control OnValidate (SetValue) ----

    [Test]
    procedure QI_EE_EmptyValidate_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.NameCtl.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('rows', Rows());
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Observe('rows-after-close', Rows());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('rows', '1=seed;300=validate empty;');
        Observer.Expect('name-after', 'seed');
        Observer.Expect('rows-after-close', '1=seed;300=validate empty;');
        Observer.Verify();
    end;

    [Test]
    procedure QI_EE_TextValidate_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Card";
    begin
        Seed();
        Card.OpenEdit();
        asserterror Card.NameCtl.SetValue('text');
        Observer.ObserveError('setvalue');
        Observer.Observe('marker-kept', Kept(300, 'validate text'));
        Observer.Observe('name-after', Card.NameCtl.Value());
        Card.Close();
        Observer.Observe('marker-kept-after-close', Kept(300, 'validate text'));
        Observer.Expect('setvalue|text', 'Validation error for Field: NameCtl,  Message = ''LT QI validate error (Select Refresh to discard errors)''');
        Observer.Expect('setvalue|code', 'TestValidation');
        Observer.Expect('marker-kept', 'No');
        Observer.Expect('name-after', 'seed');
        Observer.Expect('marker-kept-after-close', 'No');
        Observer.Verify();
    end;

    // ---- OnOpenPage (OpenEdit) ----

    [Test]
    procedure QI_EE_EmptyOpen_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT QI EE Open Card";
    begin
        Seed();
        asserterror Card.OpenEdit();
        Observer.ObserveError('open');
        Observer.Observe('marker-kept', Kept(200, 'open ran'));
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', 'Dialog');
        Observer.Expect('marker-kept', 'No');
        Observer.Verify();
    end;

    // Writer QZ: Error('') from the table field's OnValidate during SetValue (fixtures in QzTableValidateEmptyError.al).
    local procedure QzSeed(): Record "LT QZ EE Row"
    var
        Row: Record "LT QZ EE Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 5;
        Row.AutoGen := true;
        Row.Name := 'seed';
        Row.Insert();
        ClearLastError();
        exit(Row);
    end;

    local procedure QzStored(): Text
    var
        Row: Record "LT QZ EE Row";
    begin
        Row.Get(5);
        exit(Format(Row.AutoGen) + '|' + Row.Name);
    end;

    [Test]
    [HandlerFunctions('QzConfirmNo')]
    procedure QZ_EE_TableValidate_ConfirmNo_List_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ EE Row";
        List: TestPage "LT QZ EE List";
    begin
        Row := QzSeed();
        List.OpenEdit();
        List.GoToRecord(Row);
        List.AutoGen.SetValue(false);
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', List.AutoGen.Value());
        List.Close();
        Observer.Observe('stored-after-close', QzStored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'Yes');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QzConfirmNo')]
    procedure QZ_EE_TableValidate_ConfirmNo_List_Asserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ EE Row";
        List: TestPage "LT QZ EE List";
    begin
        Row := QzSeed();
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.AutoGen.SetValue(false);
            Error('no error');
        end;
        Observer.ObserveError('setvalue');
        Observer.Observe('value-after', List.AutoGen.Value());
        List.Close();
        Observer.Expect('setvalue|text', 'no error');
        Observer.Expect('setvalue|code', 'Dialog');
        Observer.Expect('value-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_EE_TableValidate_Direct_List_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ EE Row";
        List: TestPage "LT QZ EE List";
    begin
        Row := QzSeed();
        List.OpenEdit();
        List.GoToRecord(Row);
        List.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', List.Name.Value());
        List.Close();
        Observer.Observe('stored-after-close', QzStored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_EE_TableValidate_Direct_Card_NoAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ EE Row";
        Card: TestPage "LT QZ EE Card";
    begin
        Row := QzSeed();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('empty');
        Observer.Observe('went-on', 'yes');
        Observer.ObserveError('after-setvalue');
        Observer.Observe('value-after', Card.Name.Value());
        Card.Close();
        Observer.Observe('stored-after-close', QzStored());
        Observer.Expect('went-on', 'yes');
        Observer.Expect('after-setvalue|text', '');
        Observer.Expect('after-setvalue|code', 'NSValidateField:Dialog');
        Observer.Expect('value-after', 'seed');
        Observer.Expect('stored-after-close', 'Yes|seed');
        Observer.Verify();
    end;

    [ConfirmHandler]
    procedure QzConfirmNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
