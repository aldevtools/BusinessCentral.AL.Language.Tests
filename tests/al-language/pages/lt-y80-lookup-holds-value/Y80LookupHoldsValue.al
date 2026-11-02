// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT Y80 Log" (pages/lt-y80-gone-rows/Y80GoneRows.al); own objects 94287 - 94292
// Probe (writer Y80, from the runtime lane rt-pages-1102c): TestField.Lookup on a control whose field has a TableRelation (no OnLookup, the related
//   table's LookupPageId) when the field ALREADY HOLDS a value: which row the lookup page stands on when the handler gets it, which triggers the
//   lookup page ran (OnOpenPage with its filters, OnAfterGetRecord, OnAfterGetCurrRecord), and what the field holds after OK on the row it stood on,
//   after a move and OK, and after Cancel. The held value is the first, a middle, the last row, a value that is no row, a blank value, a
//   value in another case, a value of a field that is not the primary key of the related table (TableRelation = Table.Descr), on a Card and on
//   a List row. pages/lt-page-runtime/P82Lookups.al:247 Lookup_TableRelation_Ok pins the first row (G1) only.
// BC versions: 27, 28, 29

table 94287 "LT Y80 LK Group"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y80 LK Group List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 94288 "LT Y80 LK Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Grp; Code[10]) { TableRelation = "LT Y80 LK Group".Code; }
        field(3; Alt; Text[30]) { TableRelation = "LT Y80 LK Group".Descr; }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 94289 "LT Y80 LK Group List"
{
    PageType = List;
    SourceTable = "LT Y80 LK Group";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec.Code) { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('open(' + Rec.GetFilters() + ')');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('R:' + Rec.Code);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Record "LT Y80 Log";
    begin
        Log.Add('C:' + Rec.Code);
    end;
}

page 94290 "LT Y80 LK Card"
{
    PageType = Card;
    SourceTable = "LT Y80 LK Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            field(AltCtl; Rec.Alt) { ApplicationArea = All; }
        }
    }
}

page 94291 "LT Y80 LK List"
{
    PageType = List;
    SourceTable = "LT Y80 LK Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
                field(AltCtl; Rec.Alt) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 94292 "LT Y80 LK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Text;

    local procedure Seed(Held: Code[10]; HeldAlt: Text)
    var
        Group: Record "LT Y80 LK Group";
        Item: Record "LT Y80 LK Item";
        Log: Record "LT Y80 Log";
        I: Integer;
    begin
        Group.DeleteAll();
        Item.DeleteAll();
        for I := 1 to 4 do begin
            Group.Code := 'G' + Format(I);
            Group.Descr := 'Desc ' + Format(I);
            Group.Insert();
        end;
        Item."No." := 'I1';
        Item.Grp := Held;
        Item.Alt := CopyStr(HeldAlt, 1, 30);
        Item.Insert();
        Item."No." := 'I2';
        Item.Grp := 'G4';
        Item.Insert();
        Item."No." := 'I0';
        Item.Grp := 'G1';
        Item.Insert();
        Log.DeleteAll();
    end;

    local procedure Stored(): Text
    var
        Item: Record "LT Y80 LK Item";
    begin
        Item.Get('I1');
        exit(Item.Grp + '|' + Item.Alt);
    end;

    [ModalPageHandler]
    procedure GroupHandler(var P: TestPage "LT Y80 LK Group List")
    var
        Log: Record "LT Y80 Log";
    begin
        Observer.Observe('handler first', P.CodeCtl.Value());
        Observer.Observe('handler log', Log.Take());
        case Mode of
            'ok':
                P.OK().Invoke();
            'next':
                begin
                    Observer.Observe('next', Format(P.Next(), 0, 9));
                    P.OK().Invoke();
                end;
            'previous':
                begin
                    Observer.Observe('previous', Format(P.Previous(), 0, 9));
                    P.OK().Invoke();
                end;
            'first':
                begin
                    P.First();
                    P.OK().Invoke();
                end;
            'last':
                begin
                    P.Last();
                    P.OK().Invoke();
                end;
            'cancel':
                P.Cancel().Invoke();
        end;
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsFirst()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G1', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddleThird()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G3', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsLast()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G4', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle_Next()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'next';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle_Previous()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'previous';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle_First()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'first';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle_Last()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'last';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsMiddle_Cancel()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G2', '');
        Mode := 'cancel';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsNoRow()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('ZZ', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsBlank()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_HoldsLowerCase()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('g3', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_AltHoldsMiddle()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G1', 'Desc 3');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.AltCtl.Value());
        P.AltCtl.Lookup();
        Observer.Observe('after', P.AltCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_AltHoldsNoRow()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G1', 'Other');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.AltCtl.Value());
        P.AltCtl.Lookup();
        Observer.Observe('after', P.AltCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_Card_AltHoldsMiddle_Next()
    var
        P: TestPage "LT Y80 LK Card";
    begin
        Seed('G1', 'Desc 2');
        Mode := 'next';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.AltCtl.Value());
        P.AltCtl.Lookup();
        Observer.Observe('after', P.AltCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_List_HoldsMiddle()
    var
        P: TestPage "LT Y80 LK List";
    begin
        Seed('G3', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_List_HoldsMiddle_Next()
    var
        P: TestPage "LT Y80 LK List";
    begin
        Seed('G2', '');
        Mode := 'next';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('GroupHandler')]
    procedure Y80_LK_List_HoldsNoRow()
    var
        P: TestPage "LT Y80 LK List";
    begin
        Seed('ZZ', '');
        Mode := 'ok';
        P.OpenEdit();
        P.GoToKey('I1');
        Observer.Observe('before', P.GrpCtl.Value());
        P.GrpCtl.Lookup();
        Observer.Observe('after', P.GrpCtl.Value());
        P.Close();
        Observer.Observe('stored', Stored());
        Observer.Finish();
    end;
}
