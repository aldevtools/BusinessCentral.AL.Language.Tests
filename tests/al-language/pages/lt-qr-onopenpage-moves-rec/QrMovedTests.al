// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onopenpage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in QrMovedObjects.al (87260 - 87265); writer QS: QsViewObjects.al (87365 - 87375, tests QS_*)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: a page opened WITHOUT a record (TestPage OpenView / OpenEdit, Page.Run, Page.RunModal) whose OnOpenPage moves Rec (Get, FindLast,
//   FindFirst + Next, SetRange + FindLast, SetCurrentKey + Get, a key assigned without a read, Get then a filter that excludes the row):
//   which row the page shows (No.|Name of the TestPage), which triggers ran on the way (log, see QrMovedObjects.al), and where Next and
//   Previous go from there. Card and List, on a normal table and on a temporary source that OnOpenPage fills.
//   BC (27.5, 28.5, 29.0 alike): the page opens on the row OnOpenPage left Rec on (C after Get, D after FindLast, B after FindFirst+Next,
//   C after only assigning the key), in the view and key OnOpenPage set; a Rec outside the filter it set opens on the nearest row of the view
//   (B for C with filter A..B). OnAfterGetRecord and OnAfterGetCurrRecord run for that row (a list also reads its window). A temporary source
//   filled in OnOpenPage opens on the row Rec was left on (D after the inserts). Next past the last row of a list opened by Page.Run or
//   RunModal answers Yes on a new empty row.
// Facts (writer QT, QT_Temp* tests): a temporary Worksheet or List filled by a procedure before Run / RunModal / LookupMode opens on the row
//   Rec was left on (A, B, D); a key between rows (BB) opens on the next row (C); a key past the last row (E) opens on the last row (D);
//   SetCurrentKey(Name) + Get(B) opens on B in Name order. OnNextRecord / OnFindRecord pages open on the same row (their calls are logged).
// Facts (writer Y57, corpus issue 996, QR_TempWs* tests): a temporary Worksheet (not a tree) whose OnOpenPage fills Rec and moves it opens
//   on the row Rec was left on, as the temporary List does: D (no move, FindLast), C (Get, key assigned without a read), B (FindFirst +
//   Next), B for C outside the range A..B, B in Name order after SetCurrentKey(Name) + Get(B) (Next goes to A). The same with OpenEdit,
//   Page.Run, RunModal, lookup mode and with an OnNextRecord trigger. Measured: SaaS sandbox BC 29 and the Linux CI containers 27.5, 28.5,
//   29.0, all the same.
// BC versions: 27, 28, 29

codeunit 87266 "LT QR Moved Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT QR Page Log";
        QsLog: Codeunit "LT QS View Log";

    local procedure Seed(Mode: Integer)
    var
        Row: Record "LT QR Page Row";
    begin
        Row.DeleteAll();
        Log.Fill(Row);
        Log.SetMode(Mode);
    end;

    local procedure ReadCard(var P: TestPage "LT QR Moved Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewCard(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Card";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadCard(P);
        P.Close();
    end;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT QR Moved Card")
    begin
        ReadCard(P);
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var P: TestPage "LT QR Moved Card")
    begin
        ReadCard(P);
    end;

    local procedure ReadList(var P: TestPage "LT QR Moved List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewList(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved List";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadList(P);
        P.Close();
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT QR Moved List")
    begin
        ReadList(P);
    end;

    [ModalPageHandler]
    procedure ListModalHandler(var P: TestPage "LT QR Moved List")
    begin
        ReadList(P);
    end;

    local procedure ReadTempCard(var P: TestPage "LT QR Moved Temp Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewTempCard(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Temp Card";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadTempCard(P);
        P.Close();
    end;

    [PageHandler]
    procedure TempCardHandler(var P: TestPage "LT QR Moved Temp Card")
    begin
        ReadTempCard(P);
    end;

    [ModalPageHandler]
    procedure TempCardModalHandler(var P: TestPage "LT QR Moved Temp Card")
    begin
        ReadTempCard(P);
    end;

    local procedure ReadTempList(var P: TestPage "LT QR Moved Temp List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewTempList(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Temp List";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadTempList(P);
        P.Close();
    end;

    [PageHandler]
    procedure TempListHandler(var P: TestPage "LT QR Moved Temp List")
    begin
        ReadTempList(P);
    end;

    [ModalPageHandler]
    procedure TempListModalHandler(var P: TestPage "LT QR Moved Temp List")
    begin
        ReadTempList(P);
    end;

    [Test]
    procedure QR_Card_OpenView_Get()
    begin
        ViewCard(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_FindLast()
    begin
        ViewCard(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_FindFirstNext()
    begin
        ViewCard(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindLast()
    begin
        ViewCard(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetCurrentKeyGet()
    begin
        ViewCard(5, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_KeyAssigned()
    begin
        ViewCard(6, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_GetThenFilterExcludes()
    begin
        ViewCard(7, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:C;R:B;C:B;');
        Observer.Expect('next', 'No|B');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenView_SetRangeFindFirst()
    begin
        ViewCard(8, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Card_OpenEdit_Get()
    begin
        ViewCard(1, true);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_Get()
    begin
        ViewList(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_FindLast()
    begin
        ViewList(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_FindFirstNext()
    begin
        ViewList(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindLast()
    begin
        ViewList(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetCurrentKeyGet()
    begin
        ViewList(5, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_KeyAssigned()
    begin
        ViewList(6, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_GetThenFilterExcludes()
    begin
        ViewList(7, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:C;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'No|B');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenView_SetRangeFindFirst()
    begin
        ViewList(8, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_List_OpenEdit_Get()
    begin
        ViewList(1, true);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_NoMove()
    begin
        ViewTempCard(0, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_Get()
    begin
        ViewTempCard(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindLast()
    begin
        ViewTempCard(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_FindFirstNext()
    begin
        ViewTempCard(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempCard_OpenView_SetRangeFindLast()
    begin
        ViewTempCard(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_NoMove()
    begin
        ViewTempList(0, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_Get()
    begin
        ViewTempList(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_FindLast()
    begin
        ViewTempList(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_FindFirstNext()
    begin
        ViewTempList(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempList_OpenView_SetRangeFindLast()
    begin
        ViewTempList(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure QR_Card_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure QR_List_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved List");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempCardHandler')]
    procedure QR_TempCard_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Temp Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListHandler')]
    procedure QR_TempList_PageRun_NoMove()
    begin
        Seed(0);
        Page.Run(Page::"LT QR Moved Temp List");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure QR_Card_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListModalHandler')]
    procedure QR_List_RunModal_FindLast()
    begin
        Seed(2);
        Page.RunModal(Page::"LT QR Moved List");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempListModalHandler')]
    procedure QR_TempList_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Temp List");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    // Writer QS: pages with a SourceTableView (QsViewObjects.al), opened without a record; OnOpenPage moves Rec as QsLog's mode says.
    local procedure QsSeed(Mode: Integer)
    var
        Row: Record "LT QR Page Row";
    begin
        Row.DeleteAll();
        Log.Fill(Row);
        Log.SetMode(0);
        QsLog.SetMode(Mode);
    end;

    local procedure QsReadKeyAscCard(var P: TestPage "LT QS KeyAsc Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyAscCard(Mode: Integer)
    var
        P: TestPage "LT QS KeyAsc Card";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyAscCard(P);
        P.Close();
    end;

    local procedure QsReadKeyAscList(var P: TestPage "LT QS KeyAsc List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyAscList(Mode: Integer)
    var
        P: TestPage "LT QS KeyAsc List";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyAscList(P);
        P.Close();
    end;

    local procedure QsReadKeyDescCard(var P: TestPage "LT QS KeyDesc Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyDescCard(Mode: Integer)
    var
        P: TestPage "LT QS KeyDesc Card";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyDescCard(P);
        P.Close();
    end;

    local procedure QsReadKeyDescList(var P: TestPage "LT QS KeyDesc List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyDescList(Mode: Integer)
    var
        P: TestPage "LT QS KeyDesc List";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyDescList(P);
        P.Close();
    end;

    local procedure QsReadPkDescCard(var P: TestPage "LT QS PkDesc Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewPkDescCard(Mode: Integer)
    var
        P: TestPage "LT QS PkDesc Card";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadPkDescCard(P);
        P.Close();
    end;

    local procedure QsReadPkDescList(var P: TestPage "LT QS PkDesc List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewPkDescList(Mode: Integer)
    var
        P: TestPage "LT QS PkDesc List";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadPkDescList(P);
        P.Close();
    end;

    local procedure QsReadWhereCard(var P: TestPage "LT QS Where Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewWhereCard(Mode: Integer)
    var
        P: TestPage "LT QS Where Card";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadWhereCard(P);
        P.Close();
    end;

    local procedure QsReadWhereList(var P: TestPage "LT QS Where List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewWhereList(Mode: Integer)
    var
        P: TestPage "LT QS Where List";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadWhereList(P);
        P.Close();
    end;

    local procedure QsReadKeyWhereCard(var P: TestPage "LT QS KeyWhere Card")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyWhereCard(Mode: Integer)
    var
        P: TestPage "LT QS KeyWhere Card";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyWhereCard(P);
        P.Close();
    end;

    local procedure QsReadKeyWhereList(var P: TestPage "LT QS KeyWhere List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', QsLog.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', QsLog.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', QsLog.Take());
    end;

    local procedure QsViewKeyWhereList(Mode: Integer)
    var
        P: TestPage "LT QS KeyWhere List";
    begin
        QsSeed(Mode);
        P.OpenView();
        QsReadKeyWhereList(P);
        P.Close();
    end;

    [Test]
    procedure QS_KeyAsc_Card_NoMove()
    begin
        QsViewKeyAscCard(0);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_GetC()
    begin
        QsViewKeyAscCard(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_FindLast()
    begin
        QsViewKeyAscCard(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_FindFirstNext()
    begin
        QsViewKeyAscCard(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_FindFirst()
    begin
        QsViewKeyAscCard(4);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_KeyAssigned()
    begin
        QsViewKeyAscCard(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_GetD()
    begin
        QsViewKeyAscCard(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_GetA()
    begin
        QsViewKeyAscCard(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_OtherKeyGetB()
    begin
        QsViewKeyAscCard(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_Card_FlipOrderFindFirst()
    begin
        QsViewKeyAscCard(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_NoMove()
    begin
        QsViewKeyAscList(0);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_GetC()
    begin
        QsViewKeyAscList(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_FindLast()
    begin
        QsViewKeyAscList(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_FindFirstNext()
    begin
        QsViewKeyAscList(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_FindFirst()
    begin
        QsViewKeyAscList(4);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_KeyAssigned()
    begin
        QsViewKeyAscList(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_GetD()
    begin
        QsViewKeyAscList(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_GetA()
    begin
        QsViewKeyAscList(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_OtherKeyGetB()
    begin
        QsViewKeyAscList(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyAsc_List_FlipOrderFindFirst()
    begin
        QsViewKeyAscList(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_NoMove()
    begin
        QsViewKeyDescCard(0);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_GetC()
    begin
        QsViewKeyDescCard(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_FindLast()
    begin
        QsViewKeyDescCard(2);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_FindFirstNext()
    begin
        QsViewKeyDescCard(3);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_FindFirst()
    begin
        QsViewKeyDescCard(4);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_KeyAssigned()
    begin
        QsViewKeyDescCard(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_GetD()
    begin
        QsViewKeyDescCard(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_GetA()
    begin
        QsViewKeyDescCard(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_OtherKeyGetB()
    begin
        QsViewKeyDescCard(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_Card_FlipOrderFindFirst()
    begin
        QsViewKeyDescCard(9);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_NoMove()
    begin
        QsViewKeyDescList(0);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_GetC()
    begin
        QsViewKeyDescList(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:C;R:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_FindLast()
    begin
        QsViewKeyDescList(2);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_FindFirstNext()
    begin
        QsViewKeyDescList(3);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:B;R:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_FindFirst()
    begin
        QsViewKeyDescList(4);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:A;R:A;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_KeyAssigned()
    begin
        QsViewKeyDescList(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:C;R:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_GetD()
    begin
        QsViewKeyDescList(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_GetA()
    begin
        QsViewKeyDescList(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:A;R:A;R:A;R:B;R:C;R:D;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_OtherKeyGetB()
    begin
        QsViewKeyDescList(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyDesc_List_FlipOrderFindFirst()
    begin
        QsViewKeyDescList(9);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;R:D;R:C;R:B;R:A;R:D;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_NoMove()
    begin
        QsViewPkDescCard(0);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_GetC()
    begin
        QsViewPkDescCard(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_FindLast()
    begin
        QsViewPkDescCard(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_FindFirstNext()
    begin
        QsViewPkDescCard(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_FindFirst()
    begin
        QsViewPkDescCard(4);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_KeyAssigned()
    begin
        QsViewPkDescCard(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_GetD()
    begin
        QsViewPkDescCard(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_GetA()
    begin
        QsViewPkDescCard(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_OtherKeyGetB()
    begin
        QsViewPkDescCard(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_Card_FlipOrderFindFirst()
    begin
        QsViewPkDescCard(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_NoMove()
    begin
        QsViewPkDescList(0);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_GetC()
    begin
        QsViewPkDescList(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_FindLast()
    begin
        QsViewPkDescList(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_FindFirstNext()
    begin
        QsViewPkDescList(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_FindFirst()
    begin
        QsViewPkDescList(4);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_KeyAssigned()
    begin
        QsViewPkDescList(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_GetD()
    begin
        QsViewPkDescList(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_GetA()
    begin
        QsViewPkDescList(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_OtherKeyGetB()
    begin
        QsViewPkDescList(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_PkDesc_List_FlipOrderFindFirst()
    begin
        QsViewPkDescList(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_NoMove()
    begin
        QsViewWhereCard(0);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_GetC()
    begin
        QsViewWhereCard(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_FindLast()
    begin
        QsViewWhereCard(2);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_FindFirstNext()
    begin
        QsViewWhereCard(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_FindFirst()
    begin
        QsViewWhereCard(4);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_KeyAssigned()
    begin
        QsViewWhereCard(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_GetD()
    begin
        QsViewWhereCard(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_GetA()
    begin
        QsViewWhereCard(7);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:A;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_OtherKeyGetB()
    begin
        QsViewWhereCard(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_Card_FlipOrderFindFirst()
    begin
        QsViewWhereCard(9);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_NoMove()
    begin
        QsViewWhereList(0);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_GetC()
    begin
        QsViewWhereList(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;R:D;R:C;R:B;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_FindLast()
    begin
        QsViewWhereList(2);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_FindFirstNext()
    begin
        QsViewWhereList(3);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;R:D;R:C;R:B;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_FindFirst()
    begin
        QsViewWhereList(4);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:B;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_KeyAssigned()
    begin
        QsViewWhereList(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:C;R:C;R:D;R:C;R:B;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_GetD()
    begin
        QsViewWhereList(6);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_GetA()
    begin
        QsViewWhereList(7);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:A;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_OtherKeyGetB()
    begin
        QsViewWhereList(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:B;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_Where_List_FlipOrderFindFirst()
    begin
        QsViewWhereList(9);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1);O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_NoMove()
    begin
        QsViewKeyWhereCard(0);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_GetC()
    begin
        QsViewKeyWhereCard(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_FindLast()
    begin
        QsViewKeyWhereCard(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_FindFirstNext()
    begin
        QsViewKeyWhereCard(3);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_FindFirst()
    begin
        QsViewKeyWhereCard(4);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_KeyAssigned()
    begin
        QsViewKeyWhereCard(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_GetD()
    begin
        QsViewKeyWhereCard(6);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_GetA()
    begin
        QsViewKeyWhereCard(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_OtherKeyGetB()
    begin
        QsViewKeyWhereCard(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_Card_FlipOrderFindFirst()
    begin
        QsViewKeyWhereCard(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_NoMove()
    begin
        QsViewKeyWhereList(0);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_GetC()
    begin
        QsViewKeyWhereList(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_FindLast()
    begin
        QsViewKeyWhereList(2);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_FindFirstNext()
    begin
        QsViewKeyWhereList(3);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;R:B;R:A;R:B;R:C;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_FindFirst()
    begin
        QsViewKeyWhereList(4);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_KeyAssigned()
    begin
        QsViewKeyWhereList(5);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:C;R:C;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_GetD()
    begin
        QsViewKeyWhereList(6);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:C;R:B;R:A;R:C;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_GetA()
    begin
        QsViewKeyWhereList(7);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'No|A');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_OtherKeyGetB()
    begin
        QsViewKeyWhereList(8);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:B;R:B;R:C;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QS_KeyWhere_List_FlipOrderFindFirst()
    begin
        QsViewKeyWhereList(9);
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:A;R:A;R:A;R:B;R:C;R:A;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure QsHandlerPkDescList(var P: TestPage "LT QS PkDesc List")
    begin
        QsReadPkDescList(P);
    end;

    [Test]
    [HandlerFunctions('QsHandlerPkDescList')]
    procedure QS_PkDesc_List_Run_GetC()
    begin
        QsSeed(1);
        Page.Run(Page::"LT QS PkDesc List");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:C;R:C;R:B;R:A;R:C;R:D;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure QsHandlerPkDescListModal(var P: TestPage "LT QS PkDesc List")
    begin
        QsReadPkDescList(P);
    end;

    [Test]
    [HandlerFunctions('QsHandlerPkDescListModal')]
    procedure QS_PkDesc_List_RunModal_FindLast()
    begin
        QsSeed(2);
        Page.RunModal(Page::"LT QS PkDesc List");
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field1) ORDER(1);O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure QsHandlerKeyWhereCard(var P: TestPage "LT QS KeyWhere Card")
    begin
        QsReadKeyWhereCard(P);
    end;

    [Test]
    [HandlerFunctions('QsHandlerKeyWhereCard')]
    procedure QS_KeyWhere_Card_Run_GetD()
    begin
        QsSeed(6);
        Page.Run(Page::"LT QS KeyWhere Card");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2);O:D;R:D;R:C;C:C;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;C:B;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure QsHandlerKeyDescCardModal(var P: TestPage "LT QS KeyDesc Card")
    begin
        QsReadKeyDescCard(P);
    end;

    [Test]
    [HandlerFunctions('QsHandlerKeyDescCardModal')]
    procedure QS_KeyDesc_Card_RunModal_FindLast()
    begin
        QsSeed(2);
        Page.RunModal(Page::"LT QS KeyDesc Card");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'V:VERSION(1) SORTING(Field2) ORDER(1);O:D;R:D;C:D;');
        Observer.Expect('next', 'No|D');
        Observer.Expect('next log', '');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;C:C;');
        Observer.Verify();
    end;

    // ---- Writer QT (2026-10-22): a temporary Worksheet (and List) that a procedure fills BEFORE Run / RunModal; objects in
    // QtTempWorksheetObjects.al. Which row the page opens on (No.|Name), the triggers on the way, Next and Previous from there. ----

    local procedure QtReadWs(var P: TestPage "LT QT Temp Ws")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWs(var P: TestPage "LT QT Temp Ws")
    begin
        QtReadWs(P);
    end;

    local procedure QtRunModalWs(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadWsNext(var P: TestPage "LT QT Temp Ws Next")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWsNext(var P: TestPage "LT QT Temp Ws Next")
    begin
        QtReadWsNext(P);
    end;

    local procedure QtRunModalWsNext(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws Next";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadWsFind(var P: TestPage "LT QT Temp Ws Find Next")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalWsFind(var P: TestPage "LT QT Temp Ws Find Next")
    begin
        QtReadWsFind(P);
    end;

    local procedure QtRunModalWsFind(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp Ws Find Next";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtReadList(var P: TestPage "LT QT Temp List")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    [ModalPageHandler]
    procedure QtModalList(var P: TestPage "LT QT Temp List")
    begin
        QtReadList(P);
    end;

    local procedure QtRunModalList(Pos: Text; Lookup: Boolean)
    var
        Pg: Page "LT QT Temp List";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        if Lookup then
            Pg.LookupMode(true);
        Observer.Observe('before run log', Log.Take());
        Pg.RunModal();
        Observer.Observe('after close log', Log.Take());
    end;

    local procedure QtRunWs(Pos: Text)
    var
        Pg: Page "LT QT Temp Ws";
        P: TestPage "LT QT Temp Ws";
    begin
        Log.SetMode(0);
        Pg.SetRows(Pos);
        Log.Take();
        P.Trap();
        Pg.Run();
        QtReadWs(P);
        P.Close();
        Observer.Observe('after close log', Log.Take());
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_D_NoMove()
    begin
        QtRunModalWs('', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_A()
    begin
        QtRunModalWs('A', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_B()
    begin
        QtRunModalWs('B', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_BB_Between()
    begin
        QtRunModalWs('BB', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_E_PastLast()
    begin
        QtRunModalWs('E', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:E;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_RunModal_ByName_B()
    begin
        QtRunModalWs('NAME:B', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_A()
    begin
        QtRunModalWs('A', true);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_B()
    begin
        QtRunModalWs('B', true);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWs')]
    procedure QT_TempWs_Lookup_BB_Between()
    begin
        QtRunModalWs('BB', true);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_A()
    begin
        QtRunModalWsNext('A', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'O:A;R:A;N:1>B;R:B;N:1>C;R:C;N:1>D;R:D;N:1>D;R:A;N:-1>A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_B()
    begin
        QtRunModalWsNext('B', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;N:1>C;R:C;N:1>D;R:D;N:1>D;R:B;N:-1>A;R:A;N:-1>A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_RunModal_BB_Between()
    begin
        QtRunModalWsNext('BB', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;R:C;N:1>D;R:D;N:1>D;R:C;N:-1>B;R:B;N:-1>A;R:A;N:-1>A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsNext')]
    procedure QT_TempWsNext_Lookup_B()
    begin
        QtRunModalWsNext('B', true);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;N:1>C;R:C;N:1>D;R:D;N:1>D;R:B;N:-1>A;R:A;N:-1>A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsFind')]
    procedure QT_TempWsFind_RunModal_B()
    begin
        QtRunModalWsFind('B', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;F:=>>B;R:B;N:1>C;R:C;N:1>D;R:D;N:1>D;R:B;N:-1>A;R:A;N:-1>A;R:B;F:=>B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;F:=>C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;F:=>B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalWsFind')]
    procedure QT_TempWsFind_RunModal_BB_Between()
    begin
        QtRunModalWsFind('BB', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;F:=>>C;R:C;N:1>D;R:D;N:1>D;R:C;N:-1>B;R:B;N:-1>A;R:A;N:-1>A;R:C;F:=>C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;F:=>D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;F:=>C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_RunModal_B()
    begin
        QtRunModalList('B', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_RunModal_BB_Between()
    begin
        QtRunModalList('BB', false);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('QtModalList')]
    procedure QT_TempList_Lookup_B()
    begin
        QtRunModalList('B', true);
        Observer.Expect('before run log', '');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_TempWs_Run_B()
    begin
        QtRunWs('B');
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_TempWs_Run_BB_Between()
    begin
        QtRunWs('BB');
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:BB;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QT_TempWs_Run_A()
    begin
        QtRunWs('A');
        Observer.Expect('open', 'A|delta');
        Observer.Expect('open log', 'O:A;R:A;R:B;R:C;R:D;R:A;R:A;C:A;');
        Observer.Expect('next', 'Yes|B');
        Observer.Expect('next log', 'R:B;R:B;C:B;');
        Observer.Expect('previous', 'Yes|A');
        Observer.Expect('previous log', 'R:A;R:A;C:A;');
        Observer.Expect('after close log', '');
        Observer.Verify();
    end;

    // Writer Y57: a temporary Worksheet (not a tree) whose OnOpenPage fills Rec and moves it (QrMovedTempWsObjects.al, pages 93102, 93103).
    local procedure ReadTempWs(var P: TestPage "LT QR Moved Temp Ws")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
        Observer.Observe('first', Format(P.First()) + '|' + P.NoCtl.Value());
        Observer.Observe('first log', Log.Take());
    end;

    local procedure ReadTempWsNext(var P: TestPage "LT QR Moved Temp Ws Next")
    begin
        Observer.Observe('open', P.NoCtl.Value() + '|' + P.NameCtl.Value());
        Observer.Observe('open log', Log.Take());
        Observer.Observe('next', Format(P.Next()) + '|' + P.NoCtl.Value());
        Observer.Observe('next log', Log.Take());
        Observer.Observe('previous', Format(P.Previous()) + '|' + P.NoCtl.Value());
        Observer.Observe('previous log', Log.Take());
    end;

    local procedure ViewTempWs(Mode: Integer; Edit: Boolean)
    var
        P: TestPage "LT QR Moved Temp Ws";
    begin
        Seed(Mode);
        if Edit then
            P.OpenEdit()
        else
            P.OpenView();
        ReadTempWs(P);
        P.Close();
    end;

    local procedure ViewTempWsNext(Mode: Integer)
    var
        P: TestPage "LT QR Moved Temp Ws Next";
    begin
        Seed(Mode);
        P.OpenView();
        ReadTempWsNext(P);
        P.Close();
    end;

    [PageHandler]
    procedure TempWsHandler(var P: TestPage "LT QR Moved Temp Ws")
    begin
        ReadTempWs(P);
    end;

    [ModalPageHandler]
    procedure TempWsModalHandler(var P: TestPage "LT QR Moved Temp Ws")
    begin
        ReadTempWs(P);
    end;

    [ModalPageHandler]
    procedure TempWsNextModalHandler(var P: TestPage "LT QR Moved Temp Ws Next")
    begin
        ReadTempWsNext(P);
    end;

    [Test]
    procedure QR_TempWs_OpenView_NoMove()
    begin
        ViewTempWs(0, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_Get()
    begin
        ViewTempWs(1, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_FindLast()
    begin
        ViewTempWs(2, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_FindFirstNext()
    begin
        ViewTempWs(3, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_RangeFindLast()
    begin
        ViewTempWs(4, false);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('first', 'Yes|B');
        Observer.Expect('first log', 'R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_KeyGet()
    begin
        ViewTempWs(5, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|D');
        Observer.Expect('first log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_KeyNoRead()
    begin
        ViewTempWs(6, false);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_GetOutsideRange()
    begin
        ViewTempWs(7, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:C;R:B;R:A;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenView_RangeFindFirst()
    begin
        ViewTempWs(8, false);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:C;R:D;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|C');
        Observer.Expect('next log', 'R:C;R:C;C:C;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|B');
        Observer.Expect('first log', '');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWs_OpenEdit_Get()
    begin
        ViewTempWs(1, true);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWsNext_OpenView_NoMove()
    begin
        ViewTempWsNext(0);
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;N:D|1>0;N:C|-1>-1;R:C;N:B|-1>-1;R:B;N:A|-1>-1;R:A;N:A|-1>0;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWsNext_OpenView_Get()
    begin
        ViewTempWsNext(1);
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;N:D|1>1;R:D;N:D|1>0;R:C;N:B|-1>-1;R:B;N:A|-1>-1;R:A;N:A|-1>0;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Verify();
    end;

    [Test]
    procedure QR_TempWsNext_OpenView_KeyGet()
    begin
        ViewTempWsNext(5);
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;N:A|1>1;R:A;N:A|1>0;R:B;N:C|-1>-1;R:C;N:D|-1>-1;R:D;N:D|-1>0;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsHandler')]
    procedure QR_TempWs_PageRun_NoMove()
    begin
        Seed(0);
        Page.Run(Page::"LT QR Moved Temp Ws");
        Observer.Expect('open', 'D|alpha');
        Observer.Expect('open log', 'O:D;R:D;R:C;R:B;R:A;R:D;R:D;C:D;');
        Observer.Expect('next', 'Yes|');
        Observer.Expect('next log', 'C:;');
        Observer.Expect('previous', 'Yes|D');
        Observer.Expect('previous log', 'R:D;R:D;C:D;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsHandler')]
    procedure QR_TempWs_PageRun_Get()
    begin
        Seed(1);
        Page.Run(Page::"LT QR Moved Temp Ws");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsHandler')]
    procedure QR_TempWs_PageRun_KeyGet()
    begin
        Seed(5);
        Page.Run(Page::"LT QR Moved Temp Ws");
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|D');
        Observer.Expect('first log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsModalHandler')]
    procedure QR_TempWs_RunModal_Get()
    begin
        Seed(1);
        Page.RunModal(Page::"LT QR Moved Temp Ws");
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsModalHandler')]
    procedure QR_TempWs_LookupMode_Get()
    var
        WsPage: Page "LT QR Moved Temp Ws";
    begin
        Seed(1);
        WsPage.LookupMode(true);
        WsPage.RunModal();
        Observer.Expect('open', 'C|bravo');
        Observer.Expect('open log', 'O:C;R:C;R:D;R:C;R:B;R:A;R:C;R:C;C:C;');
        Observer.Expect('next', 'Yes|D');
        Observer.Expect('next log', 'R:D;R:D;C:D;');
        Observer.Expect('previous', 'Yes|C');
        Observer.Expect('previous log', 'R:C;R:C;C:C;');
        Observer.Expect('first', 'Yes|A');
        Observer.Expect('first log', 'R:A;R:A;C:A;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsModalHandler')]
    procedure QR_TempWs_RunModal_KeyGet()
    begin
        Seed(5);
        Page.RunModal(Page::"LT QR Moved Temp Ws");
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|D');
        Observer.Expect('first log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsModalHandler')]
    procedure QR_TempWs_LookupMode_KeyGet()
    var
        WsPage: Page "LT QR Moved Temp Ws";
    begin
        Seed(5);
        WsPage.LookupMode(true);
        WsPage.RunModal();
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;R:A;R:B;R:C;R:D;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Expect('first', 'Yes|D');
        Observer.Expect('first log', 'R:D;R:D;R:D;C:D;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TempWsNextModalHandler')]
    procedure QR_TempWsNext_LookupMode_KeyGet()
    var
        WsPage: Page "LT QR Moved Temp Ws Next";
    begin
        Seed(5);
        WsPage.LookupMode(true);
        WsPage.RunModal();
        Observer.Expect('open', 'B|charlie');
        Observer.Expect('open log', 'O:B;R:B;R:B;N:A|1>1;R:A;N:A|1>0;R:B;N:C|-1>-1;R:C;N:D|-1>-1;R:D;N:D|-1>0;R:B;R:B;R:B;C:B;');
        Observer.Expect('next', 'Yes|A');
        Observer.Expect('next log', 'R:A;R:A;R:A;C:A;');
        Observer.Expect('previous', 'Yes|B');
        Observer.Expect('previous log', 'R:B;R:B;R:B;C:B;');
        Observer.Verify();
    end;
}
