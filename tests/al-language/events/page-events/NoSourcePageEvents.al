// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-trigger-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); NoSourcePageFixtures.al (pages 97610-97625 without SourceTable, subscribers 97630-97650, log 97600)
// Probe: written against a BC service tier (al-runner issue 7430); every literal asserted below is what that tier produced.
// local object: the test codeunit only; its page and subscriber objects are in NoSourcePageFixtures.al.
// Facts: the nine page trigger events (OnOpenPageEvent, OnClosePageEvent, OnQueryClosePageEvent, OnAfterGetRecordEvent, OnAfterGetCurrRecordEvent,
//   OnNewRecordEvent, OnInsertRecordEvent, OnModifyRecordEvent, OnDeleteRecordEvent) on pages WITHOUT a SourceTable, for every page type: which
//   fire, in which order against the page's own triggers, on OpenView, OpenEdit, OpenNew, Trap plus Page.Run and Page.RunModal (OK and Cancel);
//   a subscriber that raises; CurrPage.Update and CurrPage.Close in triggers and actions; manual binding; a page extension; parts of a host
//   page; a Role Center with a cue part that has a SourceTable. Existing pins: testpage/P146PageExprSetValue.al QG_NoSource_* (a card without
//   a source table), events/platform-triggers/PageTriggerEventRows.al (with a source table).
// Result (BC 29, Windows service tier, then the corpus CI legs):
//   - Every page type without SourceTable opens with OpenView, OpenEdit, Trap plus Page.Run and RunModal. Only these events fire, in this order:
//     page trigger, then its event: OnOpenPage, OnOpenPageEvent, OnAfterGetCurrRecord, OnAfterGetCurrRecordEvent on open; on close OnQueryClosePage,
//     OnQueryClosePageEvent, OnClosePage, OnClosePageEvent. OnAfterGetRecordEvent, OnNewRecordEvent, OnInsertRecordEvent, OnModifyRecordEvent and
//     OnDeleteRecordEvent never fire (no record), not even for TestPage.New, which fails (DB:ClientInsertDenied).
//   - OpenNew: Card, List, ListPlus, CardPart, ListPart fail with DB:ClientInsertDenied after OnOpenPage and OnOpenPageEvent; Worksheet fails with
//     NotSupportedPageViewMode; StandardDialog and NavigatePage open as with OpenView.
//   - A subscriber with a Rec or xRec parameter does not compile (AL0441, must-not-compile case 3132); a Role Center cannot have triggers (AL0378, case 3133).
//   - In a part host, the host's triggers and events come first, then each part's; on close the parts close first, the host last. A Role Center
//     logs its parts the same way; its cue part with a SourceTable reads 0 through the TestPage even after the cue part found a record.
//   - Not covered because BC raises an unhandled CLR exception (NullReferenceException) that no AL statement can catch: OpenNew and Trap plus Page.Run
//     of a Role Center; RunModal of a Role Center returns without calling a page handler.
// BC versions: 27 to 29 (CI matrix)

codeunit 97690 "LT PNS Events"
{
    Subtype = Test;

    var
        Log: Codeunit "LT PNS Log";

    local procedure Initialize()
    var
        Row: Record "LT PNS Row";
    begin
        Row.DeleteAll();
        Log.ClearAll();
    end;

    [Test]
    procedure NoSourceCard_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97610 LT PNS Card Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunCard();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleCard')]
    procedure NoSourceCard_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalCard(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after run', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;handler Card;Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleCard')]
    procedure NoSourceCard_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalCard(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after run', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;handler Card;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKCard(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelCard(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'List.page.OnOpenPage;List.OnOpenPageEvent;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'List.page.OnOpenPage;List.OnOpenPageEvent;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97611 LT PNS List Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', 'List.page.OnOpenPage;List.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunList();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'List.page.OnOpenPage;List.OnOpenPageEvent;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleList')]
    procedure NoSourceList_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalList(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after run', 'List.page.OnOpenPage;List.OnOpenPageEvent;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;handler List;List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleList')]
    procedure NoSourceList_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalList(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after run', 'List.page.OnOpenPage;List.OnOpenPageEvent;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;handler List;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKList(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelList(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Worksheet.page.OnOpenPage;Worksheet.OnOpenPageEvent;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Worksheet.page.OnOpenPage;Worksheet.OnOpenPageEvent;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'The view mode ''Create'' is not supported by the page ID ''97612''.');
        Observer.Expect('open error|code', 'NotSupportedPageViewMode');
        Observer.Expect('log after open', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunWorksheet();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'Worksheet.page.OnOpenPage;Worksheet.OnOpenPageEvent;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleWorksheet')]
    procedure NoSourceWorksheet_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalWorksheet(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after run', 'Worksheet.page.OnOpenPage;Worksheet.OnOpenPageEvent;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;handler Worksheet;Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleWorksheet')]
    procedure NoSourceWorksheet_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalWorksheet(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after run', 'Worksheet.page.OnOpenPage;Worksheet.OnOpenPageEvent;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;handler Worksheet;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKWorksheet(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelWorksheet(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97613 LT PNS ListPlus Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunListPlus();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleListPlus')]
    procedure NoSourceListPlus_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalListPlus(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after run', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;handler ListPlus;ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleListPlus')]
    procedure NoSourceListPlus_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalListPlus(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after run', 'ListPlus.page.OnOpenPage;ListPlus.OnOpenPageEvent;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;handler ListPlus;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKListPlus(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelListPlus(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunStdDialog();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleStdDialog')]
    procedure NoSourceStdDialog_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalStdDialog(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log after run', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;handler StdDialog;StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleStdDialog')]
    procedure NoSourceStdDialog_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalStdDialog(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log after run', 'StdDialog.page.OnOpenPage;StdDialog.OnOpenPageEvent;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;handler StdDialog;StdDialog.page.OnAfterGetCurrRecord;StdDialog.OnAfterGetCurrRecordEvent;StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKStdDialog(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelStdDialog(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after Cancel', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunNavPage();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleNavPage')]
    procedure NoSourceNavPage_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalNavPage(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'OK');
        Observer.Expect('log after run', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;handler NavPage;NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleNavPage')]
    procedure NoSourceNavPage_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalNavPage(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'No');
        Observer.Expect('run error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('run error|code', 'TestActionNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('log after run', 'NavPage.page.OnOpenPage;NavPage.OnOpenPageEvent;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;handler NavPage;NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKNavPage(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelNavPage(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97616 LT PNS CardPart Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunCardPart();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleCardPart')]
    procedure NoSourceCardPart_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalCardPart(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'OK');
        Observer.Expect('log after run', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;handler CardPart;CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleCardPart')]
    procedure NoSourceCardPart_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalCardPart(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'No');
        Observer.Expect('run error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('run error|code', 'TestActionNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('log after run', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;handler CardPart;CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKCardPart(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCardPart_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelCardPart(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97617 LT PNS ListPart Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunListPart();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('log after run', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleListPart')]
    procedure NoSourceListPart_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalListPart(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'Yes');
        Observer.Expect('action', 'OK');
        Observer.Expect('log after run', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;handler ListPart;ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('HandleListPart')]
    procedure NoSourceListPart_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalListPart(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Expect('run ok', 'No');
        Observer.Expect('run error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('run error|code', 'TestActionNotFound');
        Observer.Expect('action', 'None');
        Observer.Expect('log after run', 'ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;handler ListPart;ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKListPart(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after OK', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPart_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelListPart(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenView_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;Cue.page.OnOpenPage;Cue.OnOpenPageEvent 0;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Cue.OnClosePageEvent 0;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenEdit_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;Cue.page.OnOpenPage;Cue.OnOpenPageEvent 0;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Cue.OnClosePageEvent 0;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActOKRoleCenter(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after OK', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = OK is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after OK', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
        Acted: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCancelRoleCenter(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after Cancel', Log.Dump());
            if not Acted then
                Pg.Close();
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after Cancel', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueCard(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Card.action.UpdateTrue;Card.action.UpdateTrue done;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseCard(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Card.action.UpdateFalse;Card.action.UpdateFalse done;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfCard(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Card.action.CloseSelf;Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;Card.action.CloseSelf done;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueList(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseList(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'List.action.UpdateTrue;List.action.UpdateTrue done;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseList(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseList(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'List.action.UpdateFalse;List.action.UpdateFalse done;List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfList(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseList(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'List.action.CloseSelf;List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;List.action.CloseSelf done;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueWorksheet(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseWorksheet(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Worksheet.action.UpdateTrue;Worksheet.action.UpdateTrue done;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseWorksheet(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseWorksheet(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Worksheet.action.UpdateFalse;Worksheet.action.UpdateFalse done;Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfWorksheet(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseWorksheet(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'Worksheet.action.CloseSelf;Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;Worksheet.action.CloseSelf done;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueListPlus(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseListPlus(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'ListPlus.action.UpdateTrue;ListPlus.action.UpdateTrue done;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseListPlus(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseListPlus(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'ListPlus.action.UpdateFalse;ListPlus.action.UpdateFalse done;ListPlus.page.OnAfterGetCurrRecord;ListPlus.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfListPlus(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseListPlus(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'ListPlus.action.CloseSelf;ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;ListPlus.action.CloseSelf done;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueStdDialog(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseStdDialog(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after action', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseStdDialog(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseStdDialog(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after action', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfStdDialog(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseStdDialog(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'No');
        Observer.Expect('action error|text', 'The action with ID = n is not found on the page.');
        Observer.Expect('action error|code', 'TestActionNotFound');
        Observer.Expect('log after action', '');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_Action_UpdateTrue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateTrueNavPage(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseNavPage(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'NavPage.action.UpdateTrue;NavPage.action.UpdateTrue done;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_Action_UpdateFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActUpdateFalseNavPage(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseNavPage(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'NavPage.action.UpdateFalse;NavPage.action.UpdateFalse done;NavPage.page.OnAfterGetCurrRecord;NavPage.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_Action_CloseSelf_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
        Acted: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Acted := TryActCloseSelfNavPage(Pg);
            Observer.Observe('action ok', Format(Acted));
            if not Acted then
                Observer.ObserveError('action error');
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Closed := TryCloseNavPage(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('action ok', 'Yes');
        Observer.Expect('log after action', 'NavPage.action.CloseSelf;NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;NavPage.action.CloseSelf done;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'Card.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'List.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'List.page.OnQueryClosePage;List.OnQueryClosePageEvent;List.page.OnClosePage;List.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'Worksheet.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'Worksheet.page.OnQueryClosePage;Worksheet.OnQueryClosePageEvent;Worksheet.page.OnClosePage;Worksheet.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceListPlus_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'ListPlus.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'ListPlus.page.OnQueryClosePage;ListPlus.OnQueryClosePageEvent;ListPlus.page.OnClosePage;ListPlus.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceStdDialog_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'StdDialog.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'StdDialog.page.OnQueryClosePage;StdDialog.OnQueryClosePageEvent;StdDialog.page.OnClosePage;StdDialog.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceNavPage_SetValue_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.TxtF.SetValue('typed');
            Observer.Observe('log after setvalue', Log.Dump());
            Observer.Observe('value', Pg.TxtF.Value());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after setvalue', 'NavPage.field.OnValidate;');
        Observer.Expect('value', 'typed');
        Observer.Expect('log after close', 'NavPage.page.OnQueryClosePage;NavPage.OnQueryClosePageEvent;NavPage.page.OnClosePage;NavPage.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnAfterGetCurrRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
    begin
        Initialize();
        Log.SetFailAt('Card.OnAfterGetCurrRecordEvent');
        asserterror Pg.OpenEdit();
        Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Expect('open error|text', 'PNS boom at Card.OnAfterGetCurrRecordEvent');
        Observer.Expect('open error|code', 'Dialog:TargetInvocation');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnOpenPageEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnOpenPageEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'PNS boom at Card.OnOpenPageEvent');
        Observer.Expect('open error|code', 'Dialog');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnClosePageEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnClosePageEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'No');
        // The line break in the error text differs between test runners, so the text is not asserted.
        Observer.Ignore('close error|text');
        Observer.Expect('close error|code', 'TestWrapped');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnQueryClosePageEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnQueryClosePageEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        // CI gets 'No' on 27.5, 28.5 and 29.0. The failure text is the test runner's, so it is not asserted.
        Observer.Ignore('close error|text');
        Observer.Ignore('close error|code');
        Observer.Ignore('log after close');
        Observer.Expect('close ok', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnAfterGetRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnAfterGetRecordEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnNewRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnNewRecordEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnInsertRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnInsertRecordEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnModifyRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnModifyRecordEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnDeleteRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnDeleteRecordEvent');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Closed := TryCloseCard(Pg);
            Observer.Observe('close ok', Format(Closed));
            if not Closed then
                Observer.ObserveError('close error');
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_CloseInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetMode('CloseInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Closed := TryCloseCard(Pg);
        Observer.Observe('close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('close error');
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_UpdateTrueInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetMode('UpdateTrueInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Closed := TryCloseCard(Pg);
        Observer.Observe('close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('close error');
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_UpdateFalseInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetMode('UpdateFalseInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Closed := TryCloseCard(Pg);
        Observer.Observe('close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('close error');
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_CloseInAgcr_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetMode('CloseInAgcr');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Closed := TryCloseCard(Pg);
        Observer.Observe('close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('close error');
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('close ok', 'No');
        Observer.Expect('close error|text', 'The TestPage is not open.');
        Observer.Expect('close error|code', 'TestPageNotOpened');
        Observer.Expect('log after close', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_ManualBinding_BoundBeforeOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Manual: Codeunit "LT PNS Subs Manual";
        Opened: Boolean;
    begin
        Initialize();
        BindSubscription(Manual);
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        UnbindSubscription(Manual);
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;CardManual.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;CardManual.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;CardManual.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;CardManual.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_ManualBinding_BoundAfterOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Manual: Codeunit "LT PNS Subs Manual";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            BindSubscription(Manual);
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
            UnbindSubscription(Manual);
        end;
        Observer.Expect('open ok', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'Card.page.OnQueryClosePage;Card.OnQueryClosePageEvent;CardManual.OnQueryClosePageEvent;Card.page.OnClosePage;Card.OnClosePageEvent;CardManual.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_ManualBinding_NotBound_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Manual: Codeunit "LT PNS Subs Manual";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('manual subscriber instance exists', Format(Opened));
        Observer.Observe('log after open', Log.Dump());
        if Opened then
            Pg.Close();
        Observer.Expect('manual subscriber instance exists', 'Yes');
        Observer.Expect('log after open', 'Card.page.OnOpenPage;Card.OnOpenPageEvent;Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceHostCard_OpenView_PartsAndHostLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS HostCard";
    begin
        Initialize();
        Pg.OpenView();
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('log after open', 'Host.page.OnOpenPage;Host.OnOpenPageEvent;CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;ListPart.page.OnOpenPage;ListPart.OnOpenPageEvent;Host.page.OnAfterGetCurrRecord;Host.OnAfterGetCurrRecordEvent;CardPart.page.OnAfterGetCurrRecord;CardPart.OnAfterGetCurrRecordEvent;ListPart.page.OnAfterGetCurrRecord;ListPart.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Host.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;Host.page.OnClosePage;Host.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceHostCard_OpenEdit_PartSetValue_Log()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS HostCard";
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Pg.CP.TxtF.SetValue('typed');
        Observer.Observe('log after part setvalue', Log.Dump());
        Observer.Observe('part value', Pg.CP.TxtF.Value());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('log after part setvalue', 'CardPart.field.OnValidate;');
        Observer.Expect('part value', 'typed');
        Observer.Expect('log after close', 'ListPart.page.OnQueryClosePage;ListPart.OnQueryClosePageEvent;CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Host.OnQueryClosePageEvent;ListPart.page.OnClosePage;ListPart.OnClosePageEvent;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;Host.page.OnClosePage;Host.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenterCue_OpenView_RowExists_ReadCue()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Row: Record "LT PNS Row";
    begin
        Initialize();
        Row.Id := 7;
        Row.Insert();
        Pg.OpenView();
        Observer.Observe('cue value', Pg.CueP.CueId.Value());
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('cue value', '0');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;Cue.page.OnOpenPage;Cue.OnOpenPageEvent 0;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Cue.OnClosePageEvent 0;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenterCue_OpenView_NoRow_ReadCue()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
    begin
        Initialize();
        Pg.OpenView();
        Observer.Observe('cue value', Pg.CueP.CueId.Value());
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('cue value', '0');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;Cue.page.OnOpenPage;Cue.OnOpenPageEvent 0;');
        Observer.Expect('log after close', 'CardPart.page.OnQueryClosePage;CardPart.OnQueryClosePageEvent;Cue.OnClosePageEvent 0;CardPart.page.OnClosePage;CardPart.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceRoleCenterCue_OpenView_FindFirstInCueOpenPage_ReadCue()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Row: Record "LT PNS Row";
    begin
        Initialize();
        Row.Id := 7;
        Row.Insert();
        Log.SetMode('CueFindFirst');
        Pg.OpenView();
        Observer.Observe('cue value', Pg.CueP.CueId.Value());
        Observer.Observe('log after open', Log.Dump());
        Observer.Expect('cue value', '0');
        Observer.Expect('log after open', 'CardPart.page.OnOpenPage;CardPart.OnOpenPageEvent;Cue.page.OnOpenPage;Cue.OnOpenPageEvent 7;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Navigate_New_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNewCard(Pg);
        Observer.Observe('New ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('New error');
        Observer.Observe('log after New', Log.Dump());
        Observer.Expect('New ok', 'No');
        Observer.Expect('New error|text', 'New method failed because Insert is not allowed. Page = LT PNS Card, Id = 97610.');
        Observer.Expect('New error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after New', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Navigate_Next_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNextCard(Pg);
        Observer.Observe('Next ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Next error');
        Observer.Observe('log after Next', Log.Dump());
        Observer.Expect('Next ok', 'Yes');
        Observer.Expect('log after Next', 'Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Navigate_Previous_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavPreviousCard(Pg);
        Observer.Observe('Previous ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Previous error');
        Observer.Observe('log after Previous', Log.Dump());
        Observer.Expect('Previous ok', 'Yes');
        Observer.Expect('log after Previous', 'Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Navigate_First_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavFirstCard(Pg);
        Observer.Observe('First ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('First error');
        Observer.Observe('log after First', Log.Dump());
        Observer.Expect('First ok', 'Yes');
        Observer.Expect('log after First', 'Card.page.OnAfterGetCurrRecord;Card.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceCard_Navigate_Last_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavLastCard(Pg);
        Observer.Observe('Last ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Last error');
        Observer.Observe('log after Last', Log.Dump());
        Observer.Expect('Last ok', 'Yes');
        Observer.Expect('log after Last', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Navigate_New_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNewList(Pg);
        Observer.Observe('New ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('New error');
        Observer.Observe('log after New', Log.Dump());
        Observer.Expect('New ok', 'No');
        Observer.Expect('New error|text', 'New method failed because Insert is not allowed. Page = LT PNS List, Id = 97611.');
        Observer.Expect('New error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after New', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Navigate_Next_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNextList(Pg);
        Observer.Observe('Next ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Next error');
        Observer.Observe('log after Next', Log.Dump());
        Observer.Expect('Next ok', 'Yes');
        Observer.Expect('log after Next', 'List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Navigate_Previous_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavPreviousList(Pg);
        Observer.Observe('Previous ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Previous error');
        Observer.Observe('log after Previous', Log.Dump());
        Observer.Expect('Previous ok', 'Yes');
        Observer.Expect('log after Previous', 'List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Navigate_First_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavFirstList(Pg);
        Observer.Observe('First ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('First error');
        Observer.Observe('log after First', Log.Dump());
        Observer.Expect('First ok', 'Yes');
        Observer.Expect('log after First', 'List.page.OnAfterGetCurrRecord;List.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceList_Navigate_Last_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavLastList(Pg);
        Observer.Observe('Last ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Last error');
        Observer.Observe('log after Last', Log.Dump());
        Observer.Expect('Last ok', 'Yes');
        Observer.Expect('log after Last', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Navigate_New_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNewWorksheet(Pg);
        Observer.Observe('New ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('New error');
        Observer.Observe('log after New', Log.Dump());
        Observer.Expect('New ok', 'No');
        Observer.Expect('New error|text', 'New method failed because Insert is not allowed. Page = LT PNS Worksheet, Id = 97612.');
        Observer.Expect('New error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after New', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Navigate_Next_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavNextWorksheet(Pg);
        Observer.Observe('Next ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Next error');
        Observer.Observe('log after Next', Log.Dump());
        Observer.Expect('Next ok', 'Yes');
        Observer.Expect('log after Next', 'Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Navigate_Previous_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavPreviousWorksheet(Pg);
        Observer.Observe('Previous ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Previous error');
        Observer.Observe('log after Previous', Log.Dump());
        Observer.Expect('Previous ok', 'Yes');
        Observer.Expect('log after Previous', 'Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Navigate_First_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavFirstWorksheet(Pg);
        Observer.Observe('First ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('First error');
        Observer.Observe('log after First', Log.Dump());
        Observer.Expect('First ok', 'Yes');
        Observer.Expect('log after First', 'Worksheet.page.OnAfterGetCurrRecord;Worksheet.OnAfterGetCurrRecordEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceWorksheet_Navigate_Last_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Moved: Boolean;
    begin
        Initialize();
        Pg.OpenEdit();
        Log.Reset();
        Moved := TryNavLastWorksheet(Pg);
        Observer.Observe('Last ok', Format(Moved));
        if not Moved then
            Observer.ObserveError('Last error');
        Observer.Observe('log after Last', Log.Dump());
        Observer.Expect('Last ok', 'Yes');
        Observer.Expect('log after Last', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceExtBase_OpenView_PageExtensionTriggersAndSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ExtBase";
    begin
        Initialize();
        Pg.OpenView();
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('log after open', 'ExtBase.page.OnOpenPage;ExtBase.ext.OnOpenPage;ExtBase.OnOpenPageEvent;ExtBase.page.OnAfterGetCurrRecord;ExtBase.ext.OnAfterGetCurrRecord;ExtBase.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ExtBase.OnQueryClosePageEvent;ExtBase.page.OnClosePage;ExtBase.ext.OnClosePage;ExtBase.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceExtBase_OpenEdit_PageExtensionTriggersAndSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ExtBase";
    begin
        Initialize();
        Pg.OpenEdit();
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('log after open', 'ExtBase.page.OnOpenPage;ExtBase.ext.OnOpenPage;ExtBase.OnOpenPageEvent;ExtBase.page.OnAfterGetCurrRecord;ExtBase.ext.OnAfterGetCurrRecord;ExtBase.OnAfterGetCurrRecordEvent;');
        Observer.Expect('log after close', 'ExtBase.OnQueryClosePageEvent;ExtBase.page.OnClosePage;ExtBase.ext.OnClosePage;ExtBase.OnClosePageEvent;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceArgsCard_OpenView_SubscribersWithOtherParameters()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ArgsCard";
    begin
        Initialize();
        Pg.OpenView();
        Observer.Observe('log after open', Log.Dump());
        Log.Reset();
        Pg.Close();
        Observer.Observe('log after close', Log.Dump());
        Observer.Expect('log after open', '');
        Observer.Expect('log after close', 'ArgsCard.page.OnQueryClosePage;CardArgs.OnQueryClosePageEvent Yes;');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceArgsCard_OpenNew_SubscribersWithOtherParameters()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ArgsCard";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewArgsCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Expect('open ok', 'No');
        Observer.Expect('open error|text', 'Sorry, the current permissions prevented the action. (Page 97623 LT PNS ArgsCard Insert: AL Language Coverage Tests)');
        Observer.Expect('open error|code', 'DB:ClientInsertDenied');
        Observer.Expect('log after open', '');
        Observer.Verify();
    end;

    [Test]
    procedure NoSourceArgsCard_Close_AllowCloseFalse_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ArgsCard";
        Closed: Boolean;
    begin
        Initialize();
        Pg.OpenView();
        Log.SetMode('DenyClose');
        Log.Reset();
        Closed := TryCloseArgsCard(Pg);
        Observer.Observe('close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('close error');
        Observer.Observe('log after close', Log.Dump());
        Log.SetMode('');
        Log.Reset();
        Closed := TryCloseArgsCard(Pg);
        Observer.Observe('second close ok', Format(Closed));
        if not Closed then
            Observer.ObserveError('second close error');
        Observer.Observe('log after second close', Log.Dump());
        Observer.Expect('close ok', 'Yes');
        Observer.Expect('log after close', 'ArgsCard.page.OnQueryClosePage;CardArgs.OnQueryClosePageEvent Yes;');
        Observer.Expect('second close ok', 'No');
        Observer.Expect('second close error|text', 'The TestPage is not open.');
        Observer.Expect('second close error|code', 'TestPageNotOpened');
        Observer.Expect('log after second close', '');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure HandleCard(var P: TestPage "LT PNS Card")
    begin
        Log.Add('handler Card');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleList(var P: TestPage "LT PNS List")
    begin
        Log.Add('handler List');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        Log.Add('handler Worksheet');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        Log.Add('handler ListPlus');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        Log.Add('handler StdDialog');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleNavPage(var P: TestPage "LT PNS NavPage")
    begin
        Log.Add('handler NavPage');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleCardPart(var P: TestPage "LT PNS CardPart")
    begin
        Log.Add('handler CardPart');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure HandleListPart(var P: TestPage "LT PNS ListPart")
    begin
        Log.Add('handler ListPart');
        if Log.Mode() = 'OK' then
            P.OK().Invoke();
        if Log.Mode() = 'Cancel' then
            P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryOpenViewCard(var P: TestPage "LT PNS Card")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewList(var P: TestPage "LT PNS List")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenViewRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.OpenView();
    end;

    [TryFunction]
    local procedure TryOpenEditCard(var P: TestPage "LT PNS Card")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditList(var P: TestPage "LT PNS List")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenEditRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenNewCard(var P: TestPage "LT PNS Card")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewList(var P: TestPage "LT PNS List")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryOpenNewRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryActOKCard(var P: TestPage "LT PNS Card")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelCard(var P: TestPage "LT PNS Card")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueCard(var P: TestPage "LT PNS Card")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseCard(var P: TestPage "LT PNS Card")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfCard(var P: TestPage "LT PNS Card")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunCard()
    begin
        Page.Run(Page::"LT PNS Card");
    end;

    [TryFunction]
    local procedure TryRunModalCard(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS Card");
    end;

    [TryFunction]
    local procedure TryCloseCard(var P: TestPage "LT PNS Card")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKList(var P: TestPage "LT PNS List")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelList(var P: TestPage "LT PNS List")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueList(var P: TestPage "LT PNS List")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseList(var P: TestPage "LT PNS List")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfList(var P: TestPage "LT PNS List")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunList()
    begin
        Page.Run(Page::"LT PNS List");
    end;

    [TryFunction]
    local procedure TryRunModalList(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS List");
    end;

    [TryFunction]
    local procedure TryCloseList(var P: TestPage "LT PNS List")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunWorksheet()
    begin
        Page.Run(Page::"LT PNS Worksheet");
    end;

    [TryFunction]
    local procedure TryRunModalWorksheet(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS Worksheet");
    end;

    [TryFunction]
    local procedure TryCloseWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunListPlus()
    begin
        Page.Run(Page::"LT PNS ListPlus");
    end;

    [TryFunction]
    local procedure TryRunModalListPlus(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS ListPlus");
    end;

    [TryFunction]
    local procedure TryCloseListPlus(var P: TestPage "LT PNS ListPlus")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunStdDialog()
    begin
        Page.Run(Page::"LT PNS StdDialog");
    end;

    [TryFunction]
    local procedure TryRunModalStdDialog(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS StdDialog");
    end;

    [TryFunction]
    local procedure TryCloseStdDialog(var P: TestPage "LT PNS StdDialog")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateTrueNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.UpdateTrue.Invoke();
    end;

    [TryFunction]
    local procedure TryActUpdateFalseNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.UpdateFalse.Invoke();
    end;

    [TryFunction]
    local procedure TryActCloseSelfNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.CloseSelf.Invoke();
    end;

    [TryFunction]
    local procedure TryRunNavPage()
    begin
        Page.Run(Page::"LT PNS NavPage");
    end;

    [TryFunction]
    local procedure TryRunModalNavPage(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS NavPage");
    end;

    [TryFunction]
    local procedure TryCloseNavPage(var P: TestPage "LT PNS NavPage")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryRunCardPart()
    begin
        Page.Run(Page::"LT PNS CardPart");
    end;

    [TryFunction]
    local procedure TryRunModalCardPart(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS CardPart");
    end;

    [TryFunction]
    local procedure TryCloseCardPart(var P: TestPage "LT PNS CardPart")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryRunListPart()
    begin
        Page.Run(Page::"LT PNS ListPart");
    end;

    [TryFunction]
    local procedure TryRunModalListPart(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS ListPart");
    end;

    [TryFunction]
    local procedure TryCloseListPart(var P: TestPage "LT PNS ListPart")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryActOKRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryActCancelRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.Cancel().Invoke();
    end;

    [TryFunction]
    local procedure TryRunRoleCenter()
    begin
        Page.Run(Page::"LT PNS RoleCenter");
    end;

    [TryFunction]
    local procedure TryRunModalRoleCenter(var Act: Action)
    begin
        Act := Page.RunModal(Page::"LT PNS RoleCenter");
    end;

    [TryFunction]
    local procedure TryCloseRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        P.Close();
    end;

    [TryFunction]
    local procedure TryNavNewCard(var P: TestPage "LT PNS Card")
    begin
        P.New();
    end;

    [TryFunction]
    local procedure TryNavNextCard(var P: TestPage "LT PNS Card")
    begin
        P.Next();
    end;

    [TryFunction]
    local procedure TryNavPreviousCard(var P: TestPage "LT PNS Card")
    begin
        P.Previous();
    end;

    [TryFunction]
    local procedure TryNavFirstCard(var P: TestPage "LT PNS Card")
    begin
        P.First();
    end;

    [TryFunction]
    local procedure TryNavLastCard(var P: TestPage "LT PNS Card")
    begin
        P.Last();
    end;

    [TryFunction]
    local procedure TryNavNewList(var P: TestPage "LT PNS List")
    begin
        P.New();
    end;

    [TryFunction]
    local procedure TryNavNextList(var P: TestPage "LT PNS List")
    begin
        P.Next();
    end;

    [TryFunction]
    local procedure TryNavPreviousList(var P: TestPage "LT PNS List")
    begin
        P.Previous();
    end;

    [TryFunction]
    local procedure TryNavFirstList(var P: TestPage "LT PNS List")
    begin
        P.First();
    end;

    [TryFunction]
    local procedure TryNavLastList(var P: TestPage "LT PNS List")
    begin
        P.Last();
    end;

    [TryFunction]
    local procedure TryNavNewWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.New();
    end;

    [TryFunction]
    local procedure TryNavNextWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.Next();
    end;

    [TryFunction]
    local procedure TryNavPreviousWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.Previous();
    end;

    [TryFunction]
    local procedure TryNavFirstWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.First();
    end;

    [TryFunction]
    local procedure TryNavLastWorksheet(var P: TestPage "LT PNS Worksheet")
    begin
        P.Last();
    end;

    [TryFunction]
    local procedure TryOpenNewArgsCard(var P: TestPage "LT PNS ArgsCard")
    begin
        P.OpenNew();
    end;

    [TryFunction]
    local procedure TryCloseArgsCard(var P: TestPage "LT PNS ArgsCard")
    begin
        P.Close();
    end;
}
