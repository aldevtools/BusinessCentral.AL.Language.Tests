// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Rec (71080), LT PnC Log (71071), LT PnC List (71086)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: TestPage "TestPage.Field.Value := 'x' is REFUSED. Assumed the same as Field.SetValue('x') (OnValidate runs)" (probe batch 4)
// BC versions: 29 (27 and 28 by CI)

codeunit 71144 "LT PnC Log 5"
{
    SingleInstance = true;

    var
        Items: List of [Text];

    procedure Add(Value: Text)
    begin
        Items.Add(Value);
    end;

    procedure Reset()
    begin
        Clear(Items);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Item: Text;
    begin
        foreach Item in Items do begin
            if Result <> '' then
                Result += '|';
            Result += Item;
        end;
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Items.Count());
    end;
}

page 71150 "LT PnC List VA"
{
    PageType = List;
    SourceTable = "LT PnC Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('Name.OnValidate');
                        if Rec.Name = 'bad' then
                            Error('bad name');
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Log.Add('Amount.OnValidate');
                    end;
                }
                field(Other; Rec.Other)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        Log: Codeunit "LT PnC Log 5";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Log.Add('OnNewRecord(below=' + Format(BelowxRec) + ')');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.Add('OnInsertRecord(below=' + Format(BelowxRec) + ')');
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.Add('OnModifyRecord');
        exit(true);
    end;
}

codeunit 71110 "LT PnC TestPage Value Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT PnC Rec";
    begin
        R.DeleteAll();
        R."No." := 10;
        R.Name := 'N1';
        R.Insert();
    end;

    [Test]
    procedure ValueAssign_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 5";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.First();
        List.Name.Value := 'viaValue';
        Observer.Observe('log', Log.Joined());
        Observer.Observe('read', List.Name.Value());
        Observer.Observe('readAsText', Format(List.Name.Value));
        List.Close();
        Observer.Expect('log', 'Name.OnValidate');
        Observer.Expect('read', 'viaValue');
        Observer.Expect('readAsText', 'viaValue');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 5";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.First();
        List.Name.SetValue('viaSetValue');
        Observer.Observe('log', Log.Joined());
        Observer.Observe('read', List.Name.Value());
        List.Close();
        Observer.Expect('log', 'Name.OnValidate');
        Observer.Expect('read', 'viaSetValue');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_NotEditable()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        List.Other.Value := '5';
        Observer.Observe('valueAssign', 'no error');
        List.Other.SetValue(5);
        Observer.Observe('setValue', 'no error');
        List.Close();
        Observer.Expect('valueAssign', 'no error');
        Observer.Expect('setValue', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_ValidationError()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        List.OpenEdit();
        List.First();
        asserterror List.Name.Value := 'bad';
        Observer.ObserveError('valueAssign');
        asserterror List.Name.SetValue('bad');
        Observer.ObserveError('setValue');
        List.Close();
        Observer.Expect('valueAssign|text', 'Validation error for Field: Name,  Message = ''bad name''');
        Observer.Expect('valueAssign|code', 'TestValidation');
        Observer.Expect('setValue|text', 'Validation error for Field: Name,  Message = ''bad name''');
        Observer.Expect('setValue|code', 'TestValidation');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_OnViewPage()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        List.OpenView();
        List.First();
        List.Name.Value := 'x';
        Observer.Observe('valueAssign', 'no error');
        List.Name.SetValue('x');
        Observer.Observe('setValue', 'no error');
        List.Close();
        Observer.Expect('valueAssign', 'no error');
        Observer.Expect('setValue', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ValueAssign_Number_FromText_And_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnC Log 5";
        List: TestPage "LT PnC List VA";
    begin
        Seed();
        Log.Reset();
        List.OpenEdit();
        List.First();
        List.Amount.Value := '12.5';
        Observer.Observe('text', List.Amount.Value());
        List.Amount.Value := '3';
        Observer.Observe('integer', List.Amount.Value());
        asserterror List.Amount.Value := 'abc';
        Observer.ObserveError('notANumber');
        Observer.Observe('log', Log.Joined());
        List.Close();
        Observer.Expect('text', '12.50');
        Observer.Expect('integer', '3.00');
        Observer.Expect('notANumber|text', 'Validation error for Field: Amount,  Message = ''Your entry of ''abc'' is not an acceptable value for ''Amount''. ''abc'' is not a part of a valid decimal expression.''');
        Observer.Expect('notANumber|code', 'TestValidation');
        Observer.Expect('log', 'Amount.OnValidate|Amount.OnValidate');
        Observer.Verify();
    end;
}
