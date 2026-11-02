// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-lookup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT Y80 Log" (pages/lt-y80-gone-rows/Y80GoneRows.al); own objects 94647 - 94652
// Probe (writer Y87, from the runtime lane rt-pages-1102e): TestField.Lookup on a control whose field has a TableRelation (no OnLookup, the related
//   table's LookupPageId) when the field ALREADY HOLDS a value, with related tables LARGER than the four rows of pages/lt-y80-lookup-holds-value/
//   Y80LookupHoldsValue.al: 7, 30, 120 and 300 rows. Which row the lookup page stands on when the handler gets it, which rows the page read (the log
//   is shortened: the number of entries, the first three and the last of a run of OnAfterGetRecord entries, every other entry in full), and what the
//   field holds after OK, after a move and OK, and after Cancel. The held value is the first, a middle, the last row, a value that is no row.
// BC versions: 27, 28, 29

table 94647 "LT Y87 Big Group"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT Y87 Big Group List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 94648 "LT Y87 Big Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Grp; Code[10]) { TableRelation = "LT Y87 Big Group".Code; }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

page 94649 "LT Y87 Big Group List"
{
    PageType = List;
    SourceTable = "LT Y87 Big Group";
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

page 94650 "LT Y87 Big Card"
{
    PageType = Card;
    SourceTable = "LT Y87 Big Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
        }
    }
}

page 94651 "LT Y87 Big List"
{
    PageType = List;
    SourceTable = "LT Y87 Big Item";
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
            }
        }
    }
}

codeunit 94652 "LT Y87 Big Lookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mode: Text;

    local procedure Seed(Rows: Integer; Held: Code[10])
    var
        Group: Record "LT Y87 Big Group";
        Item: Record "LT Y87 Big Item";
        Log: Record "LT Y80 Log";
        I: Integer;
    begin
        Group.DeleteAll();
        Item.DeleteAll();
        for I := 1 to Rows do begin
            Group.Code := 'G' + PadStr('', 3 - StrLen(Format(I)), '0') + Format(I);
            Group.Descr := 'Desc ' + Format(I);
            Group.Insert();
        end;
        Item."No." := 'I1';
        Item.Grp := Held;
        Item.Insert();
        Log.DeleteAll();
    end;

    local procedure Stored(): Text
    var
        Item: Record "LT Y87 Big Item";
    begin
        Item.Get('I1');
        exit(Item.Grp);
    end;

    local procedure Short(Entries: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        Run: List of [Text];
        Result: Text;
    begin
        Parts := Entries.Split(';');
        foreach Part in Parts do
            if Part.StartsWith('R:') then
                Run.Add(Part)
            else begin
                Result += FlushRun(Run);
                Result += Part + ';';
            end;
        Result += FlushRun(Run);
        exit(Result.TrimEnd(';') + ' [' + Format(Parts.Count()) + ' entries]');
    end;

    local procedure FlushRun(var Run: List of [Text]): Text
    var
        Result: Text;
        Count: Integer;
    begin
        Count := Run.Count();
        if Count = 0 then
            exit('');
        if Count <= 4 then begin
            Result := Run.Get(1);
            if Count > 1 then
                Result += ',' + Run.Get(2);
            if Count > 2 then
                Result += ',' + Run.Get(3);
            if Count > 3 then
                Result += ',' + Run.Get(4);
        end else
            Result := Run.Get(1) + ',' + Run.Get(2) + ',' + Run.Get(3) + ',...,' + Run.Get(Count);
        Run.RemoveRange(1, Count);
        exit('R[' + Format(Count) + ']:' + Result + ';');
    end;

    [ModalPageHandler]
    procedure GroupHandler(var P: TestPage "LT Y87 Big Group List")
    var
        Log: Record "LT Y80 Log";
    begin
        Observer.Observe('handler first', P.CodeCtl.Value());
        Observer.Observe('handler log', Short(Log.Take()));
        case Mode of
            'ok':
                P.OK().Invoke();
            'next':
                begin
                    Observer.Observe('next', Format(P.Next(), 0, 9) + '/' + P.CodeCtl.Value());
                    P.OK().Invoke();
                end;
            'previous':
                begin
                    Observer.Observe('previous', Format(P.Previous(), 0, 9) + '/' + P.CodeCtl.Value());
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
    procedure Y87_BL_7_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(7, 'G001');
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
    procedure Y87_BL_7_Middle()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(7, 'G004');
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
    procedure Y87_BL_7_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(7, 'G007');
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
    procedure Y87_BL_30_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G001');
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
    procedure Y87_BL_30_Middle()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_30_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G030');
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
    procedure Y87_BL_120_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G001');
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
    procedure Y87_BL_120_Middle()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_120_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G120');
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
    procedure Y87_BL_300_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(300, 'G001');
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
    procedure Y87_BL_300_Middle()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(300, 'G151');
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
    procedure Y87_BL_300_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(300, 'G300');
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
    procedure Y87_BL_7_NoRow()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(7, 'G999');
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
    procedure Y87_BL_120_NoRow()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G999');
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
    procedure Y87_BL_30_Middle_Next()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Middle_Next()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_30_Middle_Previous()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Middle_Previous()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_30_Middle_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Middle_First()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_30_Middle_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Middle_Last()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_30_Middle_Cancel()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Middle_Cancel()
    var
        P: TestPage "LT Y87 Big Card";
    begin
        Seed(120, 'G061');
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
    procedure Y87_BL_30_Middle_List()
    var
        P: TestPage "LT Y87 Big List";
    begin
        Seed(30, 'G016');
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
    procedure Y87_BL_120_Last_List()
    var
        P: TestPage "LT Y87 Big List";
    begin
        Seed(120, 'G120');
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