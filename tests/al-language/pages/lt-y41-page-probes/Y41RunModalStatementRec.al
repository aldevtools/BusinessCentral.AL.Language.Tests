// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); log table 92800 (Y41Log.al); table 92806, pages 92807-92808, test codeunit 92809
// Probe: written against BC on the corpus CI matrix (27.5, 28.5, 29.0); every literal asserted below is what that tier produced.
// Facts: what a global Rec holds after `Rec.SetRecFilter(); Page.RunModal(PageId, Rec);` called as a STATEMENT (no Action assigned),
//   when the page does not move but Rec differs from the stored row: Rec is stale (another variable modified the row), Rec was
//   inserted with Insert(true), Rec holds a Blob value in memory only, and the page itself edits the row. Also the statement form on a
//   list whose handler moves to the next row (OK and Cancel), and the stale case in the expression form for contrast.
//   pages/lt-page-runmodal-rec/PageRunModalRecAfterClose.al pins the expression form with moves.
// Measured (27.5, 28.5, 29.0 alike unless guarded): in the STATEMENT form Rec is not given back: it keeps the values it had before the
//   call (a stale Name/Counter stays stale, an in-memory Blob value stays, a Name the page saved is not read back, a list handler's
//   Next + OK leaves Rec on the start row). In the EXPRESSION form Rec takes the stored row (stale values refreshed, Next + OK gives
//   the next row). A list run with Page.RunModal (not in lookup mode) has no Cancel action: TestActionNotFound.
//   After Insert(true), Rec keeps the stored SystemId. Whether Rec's SystemModifiedAt equals the stored one varied between runs,
//   so it is not asserted.
// BC versions: all (CI)

table 92806 "LT Y41 RM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[50]) { }
        field(3; Counter; Integer) { }
        field(4; Data; Blob) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

page 92807 "LT Y41 RM Card"
{
    PageType = Card;
    SourceTable = "LT Y41 RM Row";
    InsertAllowed = false;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(CounterCtl; Rec.Counter) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Record "LT Y41 Log";
    begin
        Log.AddLine('agr ' + Rec."Code" + ' ' + Rec.Name);
    end;
}

page 92808 "LT Y41 RM List"
{
    PageType = List;
    SourceTable = "LT Y41 RM Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(CounterCtl; Rec.Counter) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 92809 "LT Y41 RunModal Stmt Rec"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        G: Record "LT Y41 RM Row";
        Obs: Codeunit "Probe Observer";

    // The Microsoft shape: a global record, filtered to itself, handed to the page in the statement form.
    local procedure Setup()
    begin
        G.SetRecFilter();
        Page.RunModal(Page::"LT Y41 RM Card", G);
    end;

    local procedure Seed()
    var
        Row: Record "LT Y41 RM Row";
        Log: Record "LT Y41 Log";
    begin
        Row.DeleteAll();
        AddRow('A', 'alpha');
        AddRow('B', 'bravo');
        AddRow('C', 'charlie');
        Log.ClearLog();
        Clear(G);
    end;

    local procedure AddRow(NewCode: Code[20]; NewName: Text[50])
    var
        Row: Record "LT Y41 RM Row";
    begin
        Row.Init();
        Row."Code" := NewCode;
        Row.Name := NewName;
        Row.Counter := 1;
        Row.Insert();
    end;

    // The Blob is read from memory (no CalcFields), so a value that was never stored shows.
    local procedure BlobText(var R: Record "LT Y41 RM Row"): Text
    var
        InS: InStream;
        T: Text;
    begin
        if not R.Data.HasValue() then
            exit('<none>');
        R.Data.CreateInStream(InS);
        InS.ReadText(T);
        exit(T);
    end;

    local procedure ObserveAll(var R: Record "LT Y41 RM Row")
    var
        Db: Record "LT Y41 RM Row";
        Log: Record "LT Y41 Log";
    begin
        Obs.Observe('rec', R."Code" + '|' + R.Name + '|' + Format(R.Counter) + '|' + BlobText(R));
        Obs.Observe('filters', R.GetFilters());
        if Db.Get(R."Code") then begin
            Db.CalcFields(Data);
            Obs.Observe('db', Db."Code" + '|' + Db.Name + '|' + Format(Db.Counter) + '|' + BlobText(Db));
        end else
            Obs.Observe('db', '<missing>');
        Obs.Observe('log', Log.Dump());
    end;

    [ModalPageHandler]
    procedure OkHandler(var P: TestPage "LT Y41 RM Card")
    begin
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetNameOkHandler(var P: TestPage "LT Y41 RM Card")
    begin
        P.NameCtl.SetValue('page');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NextOkHandler(var P: TestPage "LT Y41 RM List")
    begin
        P.Next();
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NextCancelHandler(var P: TestPage "LT Y41 RM List")
    begin
        P.Next();
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RMS_Card_SameRow_Ok()
    begin
        Seed();
        G.Get('A');
        Setup();
        ObserveAll(G);
        Obs.Expect('rec', 'A|alpha|1|<none>');
        Obs.Expect('filters', 'Code: A');
        Obs.Expect('db', 'A|alpha|1|<none>');
        Obs.Expect('log', 'agr A alpha');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RMS_Card_StaleRec_Ok()
    var
        Other: Record "LT Y41 RM Row";
    begin
        Seed();
        G.Get('A');
        Other.Get('A');
        Other.Name := 'db';
        Other.Counter := 5;
        Other.Modify();
        Setup();
        ObserveAll(G);
        Obs.Expect('rec', 'A|alpha|1|<none>');
        Obs.Expect('filters', 'Code: A');
        Obs.Expect('db', 'A|db|5|<none>');
        Obs.Expect('log', 'agr A db');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RMS_Card_StaleRec_Ok_ExpressionForm()
    var
        Other: Record "LT Y41 RM Row";
        Act: Action;
    begin
        Seed();
        G.Get('A');
        Other.Get('A');
        Other.Name := 'db';
        Other.Counter := 5;
        Other.Modify();
        G.SetRecFilter();
        Act := Page.RunModal(Page::"LT Y41 RM Card", G);
        Obs.Observe('action', Format(Act));
        ObserveAll(G);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('rec', 'A|db|5|<none>');
        Obs.Expect('filters', 'Code: A');
        Obs.Expect('db', 'A|db|5|<none>');
        Obs.Expect('log', 'agr A db');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RMS_Card_AfterInsertTrue_Ok()
    var
        Db: Record "LT Y41 RM Row";
    begin
        Seed();
        G.Init();
        G."Code" := 'N';
        G.Name := 'new';
        G.Insert(true);
        Setup();
        ObserveAll(G);
        Db.Get('N');
        Obs.Observe('same SystemId', Format(G.SystemId = Db.SystemId));
        Obs.Expect('rec', 'N|new|0|<none>');
        Obs.Expect('filters', 'Code: N');
        Obs.Expect('db', 'N|new|0|<none>');
        Obs.Expect('log', 'agr N new');
        Obs.Expect('same SystemId', 'Yes');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('OkHandler')]
    procedure RMS_Card_BlobInMemory_Ok()
    var
        OutS: OutStream;
    begin
        Seed();
        G.Get('A');
        G.Data.CreateOutStream(OutS);
        OutS.WriteText('mem');
        Setup();
        ObserveAll(G);
        Obs.Expect('rec', 'A|alpha|1|mem');
        Obs.Expect('filters', 'Code: A');
        Obs.Expect('db', 'A|alpha|1|<none>');
        Obs.Expect('log', 'agr A alpha');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('SetNameOkHandler')]
    procedure RMS_Card_PageEdits_Ok()
    begin
        Seed();
        G.Get('A');
        Setup();
        ObserveAll(G);
        Obs.Expect('rec', 'A|alpha|1|<none>');
        Obs.Expect('filters', 'Code: A');
        Obs.Expect('db', 'A|page|1|<none>');
        Obs.Expect('log', 'agr A alpha');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure RMS_List_Next_Ok()
    var
        R: Record "LT Y41 RM Row";
    begin
        Seed();
        R.Get('A');
        Page.RunModal(Page::"LT Y41 RM List", R);
        ObserveAll(R);
        Obs.Expect('rec', 'A|alpha|1|<none>');
        Obs.Expect('filters', '');
        Obs.Expect('db', 'A|alpha|1|<none>');
        Obs.Expect('log', '');
        Obs.Verify();
    end;

    // A list opened with Page.RunModal (not in lookup mode) has no Cancel action: the handler's Cancel().Invoke() raises.
    [Test]
    [HandlerFunctions('NextCancelHandler')]
    procedure RMS_List_Next_Cancel()
    var
        R: Record "LT Y41 RM Row";
    begin
        Seed();
        R.Get('A');
        asserterror Page.RunModal(Page::"LT Y41 RM List", R);
        Obs.ObserveError('cancel');
        Obs.Observe('rec', R."Code" + '|' + R.Name + '|' + R.GetFilters());
        Obs.Expect('cancel|text', 'The built-in action = Cancel is not found on the page.');
        Obs.Expect('cancel|code', 'TestActionNotFound');
        Obs.Expect('rec', 'A|alpha|');
        Obs.Verify();
    end;

    [Test]
    [HandlerFunctions('NextOkHandler')]
    procedure RMS_List_Next_Ok_ExpressionForm()
    var
        R: Record "LT Y41 RM Row";
        Act: Action;
    begin
        Seed();
        R.Get('A');
        Act := Page.RunModal(Page::"LT Y41 RM List", R);
        Obs.Observe('action', Format(Act));
        ObserveAll(R);
        Obs.Expect('action', 'LookupOK');
        Obs.Expect('rec', 'B|bravo|1|<none>');
        Obs.Expect('filters', '');
        Obs.Expect('db', 'B|bravo|1|<none>');
        Obs.Expect('log', '');
        Obs.Verify();
    end;
}
