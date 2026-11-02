// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT Y17 PH *)
// Probe (gap cycle 1, G13): a Page-typed PageHandler (var Pg: Page X) for Page.Run(Id, Rec) with a stored record (the Contact.CreateSalesQuote
//   shape: GetRecord, empty handler, page procedure, Close), and for a Page variable set up with procedures and SetRecord, then Run (the
//   Navigate shape): which page triggers run around the handler, what GetRecord hands, whether the handler's instance is the variable.
//   Nearby pin: misc/lt-y14-triage/Y14PageTriage.al:383 (Page.Run without a record: no trigger before the handler, GetRecord blank).
// Probe: values recorded on the BC 29 SaaS sandbox; other BC versions are checked by the corpus CI matrix.

table 91806 "LT Y17 PH Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Store; Text[30]) { }
        field(3; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT Y17 PH Log";
    begin
        Log.Add('T.OnModify:' + Rec.Code + '/' + Rec.Note);
    end;
}

codeunit 91809 "LT Y17 PH Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 91807 "LT Y17 PH Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 PH Row";

    layout
    {
        area(Content)
        {
            field(Code; Rec.Code) { ApplicationArea = All; }
            field(Store; Rec.Store) { ApplicationArea = All; }
            field(Note; Rec.Note) { ApplicationArea = All; }
        }
    }

    var
        Log: Codeunit "LT Y17 PH Log";
        Tag: Text;

    trigger OnOpenPage()
    begin
        Log.Add('P.OnOpenPage:' + Rec.Code);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('P.AGR:' + Rec.Code);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('P.AGCR:' + Rec.Code);
    end;

    trigger OnClosePage()
    begin
        Log.Add('P.OnClosePage:' + Rec.Code);
    end;

    procedure SetTag(T: Text)
    begin
        Tag := T;
        Log.Add('set(' + T + ')');
    end;

    procedure GetTag(): Text
    begin
        exit(Tag);
    end;

    procedure RecCode(): Code[20]
    begin
        Log.Add('reccode(' + Rec.Code + ')');
        exit(Rec.Code);
    end;

    procedure TouchRec()
    begin
        Rec.Note := 'touched';
        Rec.Modify();
    end;
}

page 91808 "LT Y17 PH List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT Y17 PH Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Store; Rec.Store) { ApplicationArea = All; }
            }
        }
    }

    var
        Log: Codeunit "LT Y17 PH Log";

    trigger OnOpenPage()
    begin
        Log.Add('L.OnOpenPage:' + Rec.Code);
    end;

    trigger OnAfterGetRecord()
    begin
        Log.Add('L.AGR:' + Rec.Code);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Log.Add('L.AGCR:' + Rec.Code);
    end;

    trigger OnClosePage()
    begin
        Log.Add('L.OnClosePage:' + Rec.Code);
    end;
}

codeunit 91810 "LT Y17 PH Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT Y17 PH Log";
        Runs: Integer;

    local procedure Seed()
    var
        R: Record "LT Y17 PH Row";
    begin
        R.DeleteAll();
        AddRow('A', 'sa');
        AddRow('B', 'sb');
        AddRow('C', 'sc');
        Commit();
        Log.Take();
        Runs := 0;
    end;

    local procedure AddRow(Code: Code[20]; Store: Text[30])
    var
        R: Record "LT Y17 PH Row";
    begin
        R.Init();
        R.Code := Code;
        R.Store := Store;
        R.Insert();
    end;

    local procedure Stored(): Text
    var
        R: Record "LT Y17 PH Row";
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += R.Code + '/' + R.Note + ';';
            until R.Next() = 0;
        exit(Result);
    end;

    local procedure Cleanup()
    var
        R: Record "LT Y17 PH Row";
    begin
        R.DeleteAll();
        Commit();
    end;

    [Test]
    [HandlerFunctions('GetRecordHandler')]
    procedure PageTypedHandler_RunWithRecord_GetRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Get('B');
        Page.Run(Page::"LT Y17 PH Card", R);
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', Stored());
        Cleanup();
        Observer.Expect('log', 'handler;cur=B/sb/find=Yes;T.OnModify:B/h;modify=Yes;');
        Observer.Expect('stored', 'A/;B/h;C/;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure GetRecordHandler(var Pg: Page "LT Y17 PH Card")
    var
        Cur: Record "LT Y17 PH Row";
    begin
        Log.Add('handler');
        Cur.Init();
        Pg.GetRecord(Cur);
        Log.Add('cur=' + Cur.Code + '/' + Cur.Store + '/find=' + Format(Cur.Find()));
        Cur.Note := 'h';
        Log.Add('modify=' + Format(Cur.Modify(true)));
    end;

    [Test]
    [HandlerFunctions('EmptyHandler')]
    procedure PageTypedHandler_RunWithRecord_EmptyHandler()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Get('B');
        Page.Run(Page::"LT Y17 PH Card", R);
        Observer.Observe('returned', 'yes');
        Observer.Observe('log', Log.Take());
        Cleanup();
        Observer.Expect('returned', 'yes');
        Observer.Expect('log', 'handler;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure EmptyHandler(var Pg: Page "LT Y17 PH Card")
    begin
        Log.Add('handler');
    end;

    [Test]
    [HandlerFunctions('ProcedureHandler')]
    procedure PageTypedHandler_RunWithRecord_PageProcedure()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Get('B');
        Page.Run(Page::"LT Y17 PH Card", R);
        Observer.Observe('log', Log.Take());
        Observer.Observe('stored', Stored());
        Cleanup();
        Observer.Expect('log', 'handler;reccode(B);got=B;handler end;');
        Observer.Expect('stored', 'A/;B/touched;C/;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure ProcedureHandler(var Pg: Page "LT Y17 PH Card")
    begin
        Log.Add('handler');
        Log.Add('got=' + Pg.RecCode());
        // A direct call: a write inside a TryFunction depends on the server setting that allows it (refused on the BC 28.5 container).
        Pg.TouchRec();
        Log.Add('handler end');
    end;

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure PageTypedHandler_RunWithRecord_Close()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Get('B');
        Page.Run(Page::"LT Y17 PH Card", R);
        Observer.Observe('log', Log.Take());
        Cleanup();
        Observer.Expect('log', 'handler;closed;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CloseHandler(var Pg: Page "LT Y17 PH Card")
    begin
        Log.Add('handler');
        Pg.Close();
        Log.Add('closed');
    end;

    [Test]
    [HandlerFunctions('ListGetRecordHandler')]
    procedure PageTypedHandler_RunWithFilteredRecord_List()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.SetRange(Code, 'B', 'C');
        R.FindLast();
        Page.Run(Page::"LT Y17 PH List", R);
        Observer.Observe('log', Log.Take());
        Cleanup();
        Observer.Expect('log', 'handler;cur=C/sc/filter=;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure ListGetRecordHandler(var Pg: Page "LT Y17 PH List")
    var
        Cur: Record "LT Y17 PH Row";
    begin
        Log.Add('handler');
        Pg.GetRecord(Cur);
        Log.Add('cur=' + Cur.Code + '/' + Cur.Store + '/filter=' + Cur.GetFilters());
    end;

    [Test]
    [HandlerFunctions('GetRecordOnlyHandler')]
    procedure PageTypedHandler_RunWithUnstoredRecord()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Init();
        R.Code := 'NEW';
        R.Store := 'snew';
        Page.Run(Page::"LT Y17 PH Card", R);
        Observer.Observe('log', Log.Take());
        Cleanup();
        Observer.Expect('log', 'handler;cur=NEW/snew/find=No;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure GetRecordOnlyHandler(var Pg: Page "LT Y17 PH Card")
    var
        Cur: Record "LT Y17 PH Row";
    begin
        Log.Add('handler');
        Pg.GetRecord(Cur);
        Log.Add('cur=' + Cur.Code + '/' + Cur.Store + '/find=' + Format(Cur.Find()));
    end;

    [Test]
    [HandlerFunctions('GetRecordOnlyHandler')]
    procedure PageTypedHandler_RunWithRecordAndField()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
    begin
        Seed();
        R.Get('B');
        Page.Run(Page::"LT Y17 PH Card", R, R.FieldNo(Note));
        Observer.Observe('log', Log.Take());
        Cleanup();
        Observer.Expect('log', 'handler;cur=B/sb/find=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TagHandler')]
    procedure PageTypedHandler_SetUpVariable_Run()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
        Pg: Page "LT Y17 PH Card";
    begin
        Seed();
        R.Get('B');
        Pg.SetTag('pre');
        Pg.SetRecord(R);
        Pg.Run();
        Observer.Observe('log', Log.Take());
        Observer.Observe('tag after run', Pg.GetTag());
        Cleanup();
        Observer.Expect('log', 'set(pre);handler1 tag=pre;reccode(B);got=B;set(in1);');
        Observer.Expect('tag after run', '');
        Observer.Verify();
    end;

    [PageHandler]
    procedure TagHandler(var Pg: Page "LT Y17 PH Card")
    begin
        Runs += 1;
        Log.Add('handler' + Format(Runs) + ' tag=' + Pg.GetTag());
        Log.Add('got=' + Pg.RecCode());
        Pg.SetTag('in' + Format(Runs));
    end;

    [Test]
    [HandlerFunctions('TagHandler')]
    procedure PageTypedHandler_SetUpVariable_SetTableView_Run()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
        Pg: Page "LT Y17 PH Card";
    begin
        Seed();
        R.SetRange(Code, 'C');
        Pg.SetTag('pre');
        Pg.SetTableView(R);
        Pg.Run();
        Observer.Observe('log', Log.Take());
        Observer.Observe('tag after run', Pg.GetTag());
        Cleanup();
        Observer.Expect('log', 'set(pre);handler1 tag=pre;reccode();got=;set(in1);');
        Observer.Expect('tag after run', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TagHandler')]
    procedure PageTypedHandler_SetUpVariable_RunTwice()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT Y17 PH Row";
        Pg: Page "LT Y17 PH Card";
    begin
        Seed();
        R.Get('B');
        Pg.SetTag('pre');
        Pg.SetRecord(R);
        Pg.Run();
        Observer.Observe('log first', Log.Take());
        ClearLastError();
        if not TryRunAgain(Pg) then
            Observer.ObserveError('second run');
        Observer.Observe('log second', Log.Take());
        Observer.Observe('tag after runs', Pg.GetTag());
        Cleanup();
        Observer.Expect('log first', 'set(pre);handler1 tag=pre;reccode(B);got=B;set(in1);');
        Observer.Expect('log second', 'handler2 tag=;reccode();got=;set(in2);');
        Observer.Expect('tag after runs', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunAgain(var Pg: Page "LT Y17 PH Card")
    begin
        Pg.Run();
    end;
}
