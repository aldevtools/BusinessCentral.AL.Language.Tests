// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects 88600 - 88604 (writer RT)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a Worksheet over a normal (not temporary) table, InsertAllowed = false and DeleteAllowed = false (the shape of page 1328
//   "Purch. Order From Sales Order"), whose OnOpenPage empties the table and inserts its rows through Rec, so Rec is left on the row
//   inserted last; a List of the same shape as the control. Opened without a record: run modally in lookup mode (OK invoked), run modally,
//   Page.Run, TestPage OpenEdit and OpenView. Rows inserted in the order A, B, C (Rec left on the last row of the view) and A, C, B (Rec
//   left on a middle row). Which row the page shows, the triggers on the way (log), Next and Previous from there, the RunModal result and
//   the record a lookup hands back.
//   Log: O:<code> = Rec at the end of OnOpenPage, R:<code> = OnAfterGetRecord, C:<code> = OnAfterGetCurrRecord.
// Source: al-runner issue 5785 (Base App codeunit 1018 "Purchase Doc. From Job" runs page 1328 with LookupMode and RunModal).
// BC versions: 27, 28, 29

table 88600 "LT RT Fill Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 88603 "LT RT Fill Log"
{
    SingleInstance = true;

    var
        Entries: Text;
        FillOrder: Text;

    procedure SetOrder(NewFillOrder: Text)
    begin
        FillOrder := NewFillOrder;
        Entries := '';
    end;

    procedure GetOrder(): Text
    begin
        exit(FillOrder);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;

    // Empties the table and inserts one row per letter of the order through the page's Rec (so Rec is left on the last one).
    procedure Fill(var Line: Record "LT RT Fill Line")
    var
        i: Integer;
    begin
        Line.DeleteAll();
        for i := 1 to StrLen(FillOrder) do begin
            Line.Init();
            Line."Code" := CopyStr(FillOrder, i, 1);
            Line.Description := 'Line ' + CopyStr(FillOrder, i, 1);
            Line.Insert();
        end;
    end;
}

page 88601 "LT RT Fill Ws"
{
    PageType = Worksheet;
    SourceTable = "LT RT Fill Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    var
        Log: Codeunit "LT RT Fill Log";
}

page 88602 "LT RT Fill List"
{
    PageType = List;
    SourceTable = "LT RT Fill Line";
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescriptionCtl; Rec.Description) { ApplicationArea = All; }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Log.Fill(Rec);
        Log.Add('O:' + Rec."Code");
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('R:' + Rec."Code");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('C:' + Rec."Code");
    end;

    var
        Log: Codeunit "LT RT Fill Log";
}

codeunit 88604 "LT RT Fill Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT RT Fill Log";

    local procedure Prepare(FillOrder: Text)
    var
        Line: Record "LT RT Fill Line";
    begin
        // A stale row that OnOpenPage must remove: the page shows only the rows it inserted.
        Line.DeleteAll();
        Line."Code" := 'Z';
        Line.Insert();
        Log.SetOrder(FillOrder);
    end;

    local procedure Rows(): Text
    var
        Line: Record "LT RT Fill Line";
        Result: Text;
    begin
        if Line.FindSet() then
            repeat
                Result += Line."Code";
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure ReadWsMoves(var P: TestPage "LT RT Fill Ws")
    begin
        Observer.Observe('open', P.CodeCtl.Value() + '|' + P.DescriptionCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('next', Format(P.Next()) + '|' + P.CodeCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.CodeCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ReadListMoves(var P: TestPage "LT RT Fill List")
    begin
        Observer.Observe('open', P.CodeCtl.Value() + '|' + P.DescriptionCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('rows', Rows());
        Observer.Observe('next', Format(P.Next()) + '|' + P.CodeCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.CodeCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure WsPickShownHandler(var P: TestPage "LT RT Fill Ws")
    begin
        Observer.Observe('open', P.CodeCtl.Value() + '|' + P.DescriptionCtl.Value());
        Observer.Observe('open log', Log.Take());
        P.OK().Invoke();
        Observer.Observe('ok log', Log.Take());
    end;

    [ModalPageHandler]
    procedure WsMovesModalHandler(var P: TestPage "LT RT Fill Ws")
    begin
        ReadWsMoves(P);
    end;

    [PageHandler]
    procedure WsMovesPageHandler(var P: TestPage "LT RT Fill Ws")
    begin
        ReadWsMoves(P);
    end;

    [ModalPageHandler]
    procedure ListPickShownHandler(var P: TestPage "LT RT Fill List")
    begin
        Observer.Observe('open', P.CodeCtl.Value() + '|' + P.DescriptionCtl.Value());
        Observer.Observe('open log', Log.Take());
        P.OK().Invoke();
        Observer.Observe('ok log', Log.Take());
    end;

    local procedure LookupWs(FillOrder: Text)
    var
        Ws: Page "LT RT Fill Ws";
        Line: Record "LT RT Fill Line";
    begin
        Prepare(FillOrder);
        Ws.LookupMode(true);
        Observer.Observe('result', Format(Ws.RunModal()));
        Observer.Observe('after close log', Log.Take());
        Ws.GetRecord(Line);
        Observer.Observe('selected', Line."Code");
        Observer.Observe('rows after close', Rows());
    end;

    // The reporter's shape: lookup mode, run modally, the handler reads the shown row and invokes OK.
    [Test]
    [HandlerFunctions('WsPickShownHandler')]
    procedure RT_FillWs_Lookup_ABC_OK()
    begin
        LookupWs('ABC');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsPickShownHandler')]
    procedure RT_FillWs_Lookup_ACB_OK()
    begin
        LookupWs('ACB');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsMovesModalHandler')]
    procedure RT_FillWs_RunModal_ABC_Moves()
    var
        Ws: Page "LT RT Fill Ws";
    begin
        Prepare('ABC');
        Observer.Observe('result', Format(Ws.RunModal()));
        Observer.Observe('after close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsMovesModalHandler')]
    procedure RT_FillWs_LookupRunModal_ACB_Moves()
    var
        Ws: Page "LT RT Fill Ws";
    begin
        Prepare('ACB');
        Ws.LookupMode(true);
        Observer.Observe('result', Format(Ws.RunModal()));
        Observer.Observe('after close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('WsMovesPageHandler')]
    procedure RT_FillWs_PageRun_ABC_Moves()
    begin
        Prepare('ABC');
        Page.Run(Page::"LT RT Fill Ws");
        Observer.Observe('after run log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RT_FillWs_OpenEdit_ABC_Moves()
    var
        P: TestPage "LT RT Fill Ws";
    begin
        Prepare('ABC');
        P.OpenEdit();
        ReadWsMoves(P);
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RT_FillWs_OpenEdit_ACB_Moves()
    var
        P: TestPage "LT RT Fill Ws";
    begin
        Prepare('ACB');
        P.OpenEdit();
        ReadWsMoves(P);
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure RT_FillWs_OpenView_ACB_Moves()
    var
        P: TestPage "LT RT Fill Ws";
    begin
        Prepare('ACB');
        P.OpenView();
        ReadWsMoves(P);
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('ListPickShownHandler')]
    procedure RT_FillList_Lookup_ABC_OK()
    var
        L: Page "LT RT Fill List";
        Line: Record "LT RT Fill Line";
    begin
        Prepare('ABC');
        L.LookupMode(true);
        Observer.Observe('result', Format(L.RunModal()));
        Observer.Observe('after close log', Log.Take());
        L.GetRecord(Line);
        Observer.Observe('selected', Line."Code");
        Observer.Finish();
    end;

    [Test]
    procedure RT_FillList_OpenEdit_ACB_Moves()
    var
        P: TestPage "LT RT Fill List";
    begin
        Prepare('ACB');
        P.OpenEdit();
        ReadListMoves(P);
        P.Close();
        Observer.Observe('close log', Log.Take());
        Observer.Finish();
    end;
}
