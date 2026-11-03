// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70311, page 70312, log codeunit 70313 (used only by codeunit 70315), subscribers 70314, test codeunit 70315
// Probe: written against BC 29 (tag P81, GitHub issue 81); every literal asserted later is what a local BC 29 tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order of the page field OnBeforeValidate / OnAfterValidate events, the page field OnValidate trigger, the table field OnBeforeValidate / OnAfterValidate events and the table OnValidate trigger when a TestPage sets a field (SetValue), when the value is unchanged, when the table trigger raises, and for Rec.Validate on a record
// BC versions: 29 (27 and 28 by CI)

table 70311 "LT P81 VT"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P81 Log";
            begin
                Log.Add('T.Name.OnValidate(' + Name + ')');
            end;
        }
        field(3; Qty; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P81 Log";
            begin
                Log.Add('T.Qty.OnValidate(' + Format(Qty) + ')');
                if Qty < 0 then
                    Error('negative quantity');
            end;
        }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 70312 "LT P81 VT Card"
{
    PageType = Card;
    SourceTable = "LT P81 VT";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name)
                {
                    trigger OnValidate()
                    var
                        Log: Codeunit "LT P81 Log";
                    begin
                        Log.Add('P.Name.OnValidate(' + Rec.Name + ')');
                        Rec.Qty := StrLen(Rec.Name);
                    end;
                }
                field(Qty; Rec.Qty)
                {
                    trigger OnValidate()
                    var
                        Log: Codeunit "LT P81 Log";
                    begin
                        Log.Add('P.Qty.OnValidate(' + Format(Rec.Qty) + ')');
                    end;
                }
            }
        }
    }
}

codeunit 70313 "LT P81 Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure ClearAll()
    begin
        Clear(Entries);
    end;

    procedure Joined(): Text
    var
        Result: Text;
        Entry: Text;
    begin
        foreach Entry in Entries do begin
            if Result <> '' then
                Result += ' > ';
            Result += Entry;
        end;
        exit(Result);
    end;
}

codeunit 70314 "LT P81 Validate Subs"
{
    var
        Log: Codeunit "LT P81 Log";

    [EventSubscriber(ObjectType::Table, Database::"LT P81 VT", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure TableNameBefore(var Rec: Record "LT P81 VT"; var xRec: Record "LT P81 VT"; CurrFieldNo: Integer)
    begin
        Log.Add('T.Name.Before(rec=' + Rec.Name + ',x=' + xRec.Name + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P81 VT", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure TableNameAfter(var Rec: Record "LT P81 VT"; var xRec: Record "LT P81 VT"; CurrFieldNo: Integer)
    begin
        Log.Add('T.Name.After(rec=' + Rec.Name + ',x=' + xRec.Name + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P81 VT", 'OnBeforeValidateEvent', 'Qty', false, false)]
    local procedure TableQtyBefore(var Rec: Record "LT P81 VT"; var xRec: Record "LT P81 VT"; CurrFieldNo: Integer)
    begin
        Log.Add('T.Qty.Before(rec=' + Format(Rec.Qty) + ',x=' + Format(xRec.Qty) + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P81 VT", 'OnAfterValidateEvent', 'Qty', false, false)]
    local procedure TableQtyAfter(var Rec: Record "LT P81 VT"; var xRec: Record "LT P81 VT"; CurrFieldNo: Integer)
    begin
        Log.Add('T.Qty.After(rec=' + Format(Rec.Qty) + ',x=' + Format(xRec.Qty) + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P81 VT Card", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure PageNameBefore(var Rec: Record "LT P81 VT")
    begin
        Log.Add('P.Name.Before(rec=' + Rec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P81 VT Card", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure PageNameAfter(var Rec: Record "LT P81 VT")
    begin
        Log.Add('P.Name.After(rec=' + Rec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P81 VT Card", 'OnBeforeValidateEvent', 'Qty', false, false)]
    local procedure PageQtyBefore(var Rec: Record "LT P81 VT")
    begin
        Log.Add('P.Qty.Before(rec=' + Format(Rec.Qty) + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P81 VT Card", 'OnAfterValidateEvent', 'Qty', false, false)]
    local procedure PageQtyAfter(var Rec: Record "LT P81 VT")
    begin
        Log.Add('P.Qty.After(rec=' + Format(Rec.Qty) + ')');
    end;
}

codeunit 70315 "LT P81 Page Validate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P81 VT";
    begin
        Row.DeleteAll();
        Row.Code := 'K1';
        Row.Name := 'first';
        Row.Qty := 3;
        Row.Insert();
    end;

    [Test]
    procedure TestPage_SetValue_Name_Existing()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Name.SetValue('second');
        Observer.Observe('log', Log.Joined());
        Observer.Observe('name', Card.Name.Value());
        Observer.Observe('qty', Card.Qty.Value());
        Card.Close();
        Observer.Expect('log', 'T.Name.Before(rec=second,x=first,cur=2) > T.Name.OnValidate(second) > T.Name.After(rec=second,x=first,cur=2) > P.Name.Before(rec=second) > P.Name.OnValidate(second) > P.Name.After(rec=second)');
        Observer.Expect('name', 'second');
        Observer.Expect('qty', '6');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_Qty_Existing()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Qty.SetValue(9);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('name', Card.Name.Value());
        Observer.Observe('qty', Card.Qty.Value());
        Observer.Expect('log', 'T.Qty.Before(rec=9,x=3,cur=3) > T.Qty.OnValidate(9) > T.Qty.After(rec=9,x=3,cur=3) > P.Qty.Before(rec=9) > P.Qty.OnValidate(9) > P.Qty.After(rec=9)');
        Observer.Expect('name', 'first');
        Observer.Expect('qty', '9');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_SameValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Name.SetValue('first');
        Observer.Observe('log_name_same', Log.Joined());
        Log.ClearAll();
        Card.Qty.SetValue(3);
        Observer.Observe('log_qty_same', Log.Joined());
        Observer.Expect('log_name_same', 'T.Name.Before(rec=first,x=first,cur=2) > T.Name.OnValidate(first) > T.Name.After(rec=first,x=first,cur=2) > P.Name.Before(rec=first) > P.Name.OnValidate(first) > P.Name.After(rec=first)');
        Observer.Expect('log_qty_same', 'T.Qty.Before(rec=3,x=5,cur=3) > T.Qty.OnValidate(3) > T.Qty.After(rec=3,x=5,cur=3) > P.Qty.Before(rec=3) > P.Qty.OnValidate(3) > P.Qty.After(rec=3)');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_NegativeQty_TableTriggerRaises()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        asserterror Card.Qty.SetValue(-1);
        Observer.ObserveError('err');
        Observer.Observe('log', Log.Joined());
        Observer.Observe('qty_after', Card.Qty.Value());
        Observer.Expect('err|text', 'Validation error for Field: Qty,  Message = ''negative quantity (Select Refresh to discard errors)''');
        Observer.Expect('err|code', 'TestValidation');
        Observer.Expect('log', 'T.Qty.Before(rec=-1,x=3,cur=3) > T.Qty.OnValidate(-1)');
        Observer.Expect('qty_after', '3');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_OpenNew_SetKeyThenName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Row: Record "LT P81 VT";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenNew();
        Log.ClearAll();
        Card.Code.SetValue('K2');
        Observer.Observe('log_code', Log.Joined());
        Log.ClearAll();
        Card.Name.SetValue('new-name');
        Observer.Observe('log_name', Log.Joined());
        Observer.Observe('qty', Card.Qty.Value());
        Card.Close();
        Observer.Observe('row_found', Format(Row.Get('K2')));
        Observer.Observe('row_name', Row.Name);
        Observer.Observe('row_qty', Format(Row.Qty));
        Observer.Expect('log_code', '');
        Observer.Expect('log_name', 'T.Name.Before(rec=new-name,x=,cur=2) > T.Name.OnValidate(new-name) > T.Name.After(rec=new-name,x=,cur=2) > P.Name.Before(rec=new-name) > P.Name.OnValidate(new-name) > P.Name.After(rec=new-name)');
        Observer.Expect('qty', '8');
        Observer.Expect('row_found', 'Yes');
        Observer.Expect('row_name', 'new-name');
        Observer.Expect('row_qty', '8');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_NameThenQty_Sequence()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Name.SetValue('abc');
        Card.Qty.SetValue(50);
        Observer.Observe('log', Log.Joined());
        Observer.Observe('qty', Card.Qty.Value());
        Observer.Expect('log', 'T.Name.Before(rec=abc,x=first,cur=2) > T.Name.OnValidate(abc) > T.Name.After(rec=abc,x=first,cur=2) > P.Name.Before(rec=abc) > P.Name.OnValidate(abc) > P.Name.After(rec=abc) > T.Qty.Before(rec=50,x=3,cur=3) > T.Qty.OnValidate(50) > T.Qty.After(rec=50,x=3,cur=3) > P.Qty.Before(rec=50) > P.Qty.OnValidate(50) > P.Qty.After(rec=50)');
        Observer.Expect('qty', '50');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_EmptyName()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Name.SetValue('');
        Observer.Observe('log', Log.Joined());
        Observer.Observe('qty', Card.Qty.Value());
        Observer.Expect('log', 'T.Name.Before(rec=,x=first,cur=2) > T.Name.OnValidate() > T.Name.After(rec=,x=first,cur=2) > P.Name.Before(rec=) > P.Name.OnValidate() > P.Name.After(rec=)');
        Observer.Expect('qty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_SetValue_NameTooLong()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        asserterror Card.Name.SetValue('0123456789012345678901234567890123456789');
        Observer.ObserveError('err');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('err|text', 'Validation error for Field: Name,  Message = ''The length of the string is 40, but it must be less than or equal to 30 characters. Value: 0123456789012345678901234567890123456789 (Select Refresh to discard errors)''');
        Observer.Expect('err|code', 'TestValidation');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_AssertEquals_And_Value_NoEvents()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Observer.Observe('name', Card.Name.Value());
        Card.Name.AssertEquals('first');
        Observer.Observe('log', Log.Joined());
        Observer.Expect('name', 'first');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure Record_Validate_TableEventsOnly()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Row: Record "LT P81 VT";
    begin
        Seed();
        Row.Get('K1');
        Log.ClearAll();
        Row.Validate(Name, 'vname');
        Observer.Observe('log_name', Log.Joined());
        Log.ClearAll();
        Row.Validate(Qty, 4);
        Observer.Observe('log_qty', Log.Joined());
        Log.ClearAll();
        Row.Name := 'assigned';
        Observer.Observe('log_assign', Log.Joined());
        Observer.Expect('log_name', 'T.Name.Before(rec=vname,x=first,cur=0) > T.Name.OnValidate(vname) > T.Name.After(rec=vname,x=first,cur=0)');
        Observer.Expect('log_qty', 'T.Qty.Before(rec=4,x=3,cur=0) > T.Qty.OnValidate(4) > T.Qty.After(rec=4,x=3,cur=0)');
        Observer.Expect('log_assign', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_EditThenClose_RowPersisted()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P81 Log";
        Row: Record "LT P81 VT";
        Card: TestPage "LT P81 VT Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('K1');
        Log.ClearAll();
        Card.Name.SetValue('persist');
        Card.Close();
        Row.Get('K1');
        Observer.Observe('row_name', Row.Name);
        Observer.Observe('row_qty', Format(Row.Qty));
        Observer.Observe('log', Log.Joined());
        Observer.Expect('row_name', 'persist');
        Observer.Expect('row_qty', '7');
        Observer.Expect('log', 'T.Name.Before(rec=persist,x=first,cur=2) > T.Name.OnValidate(persist) > T.Name.After(rec=persist,x=first,cur=2) > P.Name.Before(rec=persist) > P.Name.OnValidate(persist) > P.Name.After(rec=persist)');
        Observer.Verify();
    end;
}
