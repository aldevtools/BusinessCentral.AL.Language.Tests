// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 93858, pages 93860-93861, codeunits 93855 (log), 93856 (test)
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: a Page-typed PageHandler (var Pg: Page X) and ModalPageHandler (var Pg: Page X; var Reply: Action) for a page run from a
//   Page variable that its own procedure set up (SetRecords does Rec.Copy(Temp, true): the Error Messages shape), for Page.Run(Id,
//   TempRec) with a temporary record, for a stored source set up by a procedure that does Rec.Get, and for a variable that only has a
//   tag. What GetRecord hands, which page triggers run around the handler, what the caller's temporary record holds afterwards, and
//   whether the variable is set up after the run.
//   Log format: set = SetRecords, open = OnOpenPage, agcr = OnAfterGetCurrRecord, h = handler (tag, got record, counts).
// Neighbours: pages/lt-y17-page-handler-record/Y17PageHandlerRecord.al (stored record, SetRecord and SetTableView),
//   misc/lt-y14-triage/Y14PageTriage.al:383 (Page.Run without a record).
// BC versions: all (CI)

table 93858 "LT Y72 PH Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Msg; Text[30]) { }
        field(3; Kind; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 93855 "LT Y72 PH Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ';';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 93860 "LT Y72 PH Temp List"
{
    PageType = List;
    SourceTable = "LT Y72 PH Row";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(MsgCtl; Rec.Msg) { ApplicationArea = All; }
            }
        }
    }

    var
        Tag: Text;

    procedure SetRecords(var Temp: Record "LT Y72 PH Row" temporary)
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        if Temp.FindFirst() then;
        Rec.Copy(Temp, true);
        Log.Add('set(' + Format(Temp.Id) + ')');
    end;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure RowCount(): Integer
    begin
        exit(Rec.Count());
    end;

    procedure CurId(): Integer
    begin
        exit(Rec.Id);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        Log.Add('open(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        Log.Add('agcr(' + Format(Rec.Id) + ')');
    end;
}

page 93861 "LT Y72 PH Stored List"
{
    PageType = List;
    SourceTable = "LT Y72 PH Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
                field(MsgCtl; Rec.Msg) { ApplicationArea = All; }
            }
        }
    }

    procedure Fill(Id: Integer)
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        Rec.Get(Id);
        Log.Add('fill(' + Format(Rec.Id) + ')');
    end;

    procedure CurId(): Integer
    begin
        exit(Rec.Id);
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        Log.Add('open(' + Format(Rec.Id) + ')');
    end;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT Y72 PH Log";
    begin
        Log.Add('agcr(' + Format(Rec.Id) + ')');
    end;
}

codeunit 93856 "LT Y72 Page Handler Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT Y72 PH Log";
        Got: Record "LT Y72 PH Row" temporary;
        GotStored: Record "LT Y72 PH Row" temporary;

    local procedure Seed()
    begin
        ClearLastError();
        Observer.Discard();
        Log.Take();
        Got.Reset();
        Got.DeleteAll();
        GotStored.Reset();
        GotStored.DeleteAll();
    end;

    local procedure FillTemp(var Temp: Record "LT Y72 PH Row" temporary)
    begin
        Temp.DeleteAll();
        AddTemp(Temp, 1, 'a');
        AddTemp(Temp, 2, 'b');
        AddTemp(Temp, 3, 'c');
    end;

    local procedure AddTemp(var Temp: Record "LT Y72 PH Row" temporary; Id: Integer; Msg: Text[30])
    begin
        Temp.Init();
        Temp.Id := Id;
        Temp.Msg := Msg;
        Temp.Insert();
    end;

    local procedure FillStored()
    var
        Row: Record "LT Y72 PH Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Msg := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Msg := 'b';
        Row.Insert();
        Row.Id := 3;
        Row.Msg := 'c';
        Row.Insert();
    end;

    local procedure ObserveAfter(var Temp: Record "LT Y72 PH Row" temporary)
    begin
        Observer.Observe('after log', Log.Take());
        Observer.Observe('after caller id', Format(Temp.Id));
        Observer.Observe('after caller count', Format(Temp.Count()));
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure TypedHandler_SetByProcedure_TempShared()
    var
        Temp: Record "LT Y72 PH Row" temporary;
        Pe: Page "LT Y72 PH Temp List";
    begin
        Seed();
        FillTemp(Temp);
        Pe.SetRecords(Temp);
        Pe.Run();
        ObserveAfter(Temp);
        Observer.Observe('tag after run', Pe.GetTag());
        Observer.Observe('count after run', Format(Pe.RowCount()));
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_TempShared_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_TempShared_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_TempShared_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure TypedHandler_TempRecord_PageRun_OnRowTwo()
    var
        Temp: Record "LT Y72 PH Row" temporary;
    begin
        Seed();
        FillTemp(Temp);
        Temp.Get(2);
        Page.Run(Page::"LT Y72 PH Temp List", Temp);
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_OnRowTwo_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_OnRowTwo_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_OnRowTwo_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure TypedHandler_TempRecord_PageRun_Filtered()
    var
        Temp: Record "LT Y72 PH Row" temporary;
    begin
        Seed();
        FillTemp(Temp);
        Temp.SetFilter(Id, '2..3');
        Temp.FindFirst();
        Page.Run(Page::"LT Y72 PH Temp List", Temp);
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Filtered_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Filtered_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Filtered_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure TypedHandler_TempRecord_PageRun_Empty()
    var
        Temp: Record "LT Y72 PH Row" temporary;
    begin
        Seed();
        Page.Run(Page::"LT Y72 PH Temp List", Temp);
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Empty_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Empty_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRun_Empty_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('StoredHandler')]
    procedure TypedHandler_SetByProcedure_Stored()
    var
        Ps: Page "LT Y72 PH Stored List";
    begin
        Seed();
        FillStored();
        Ps.Fill(2);
        Ps.Run();
        Observer.Observe('after log', Log.Take());
        Observer.Observe('after cur id', Format(Ps.CurId()));
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_Stored_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_Stored_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_Stored_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempHandler')]
    procedure TypedHandler_TagOnly()
    var
        Pe: Page "LT Y72 PH Temp List";
    begin
        Seed();
        Pe.SetTag('t1');
        Pe.Run();
        Observer.Observe('after log', Log.Take());
        Observer.Observe('tag after run', Pe.GetTag());
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_TagOnly_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TagOnly_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TagOnly_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempModalHandler')]
    procedure TypedHandler_SetByProcedure_RunModal()
    var
        Temp: Record "LT Y72 PH Row" temporary;
        Pe: Page "LT Y72 PH Temp List";
        Reply: Action;
    begin
        Seed();
        FillTemp(Temp);
        Pe.SetRecords(Temp);
        Reply := Pe.RunModal();
        Observer.Observe('reply', Format(Reply));
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempModalHandlerCancel')]
    procedure TypedHandler_SetByProcedure_RunModal_Cancel()
    var
        Temp: Record "LT Y72 PH Row" temporary;
        Pe: Page "LT Y72 PH Temp List";
        Reply: Action;
    begin
        Seed();
        FillTemp(Temp);
        Pe.SetRecords(Temp);
        Reply := Pe.RunModal();
        Observer.Observe('reply', Format(Reply));
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_Cancel_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_Cancel_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_SetByProcedure_RunModal_Cancel_More3()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('TempModalHandler')]
    procedure TypedHandler_TempRecord_PageRunModal()
    var
        Temp: Record "LT Y72 PH Row" temporary;
        Reply: Action;
    begin
        Seed();
        FillTemp(Temp);
        Temp.Get(2);
        Reply := Page.RunModal(Page::"LT Y72 PH Temp List", Temp);
        Observer.Observe('reply', Format(Reply));
        ObserveAfter(Temp);
        Observer.Finish();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRunModal_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRunModal_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure TypedHandler_TempRecord_PageRunModal_More3()
    begin
        Observer.More();
    end;

    [PageHandler]
    procedure TempHandler(var Pg: Page "LT Y72 PH Temp List")
    begin
        LogTemp(Pg);
    end;

    [ModalPageHandler]
    procedure TempModalHandler(var Pg: Page "LT Y72 PH Temp List"; var Reply: Action)
    begin
        LogTemp(Pg);
        Reply := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure TempModalHandlerCancel(var Pg: Page "LT Y72 PH Temp List"; var Reply: Action)
    begin
        LogTemp(Pg);
        Reply := Action::LookupCancel;
    end;

    local procedure LogTemp(var Pg: Page "LT Y72 PH Temp List")
    begin
        Got.DeleteAll();
        Got.Init();
        Pg.GetRecord(Got);
        Log.Add('h tag=' + Pg.GetTag() + ' got=' + Format(Got.Id) + '/' + Got.Msg + ' gotcount=' + Format(Got.Count()) + ' pagecount=' + Format(Pg.RowCount()) + ' cur=' + Format(Pg.CurId()));
    end;

    [PageHandler]
    procedure StoredHandler(var Pg: Page "LT Y72 PH Stored List")
    begin
        GotStored.DeleteAll();
        GotStored.Init();
        Pg.GetRecord(GotStored);
        Log.Add('h got=' + Format(GotStored.Id) + '/' + GotStored.Msg + ' cur=' + Format(Pg.CurId()));
    end;
}
