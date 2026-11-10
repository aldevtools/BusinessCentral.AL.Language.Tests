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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceList_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceList_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS List";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewList(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceWorksheet_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Worksheet";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewWorksheet(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPlus_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPlus_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPlus";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPlus(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceStdDialog_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS StdDialog";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewStdDialog(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceNavPage_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceNavPage_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS NavPage";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewNavPage(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCardPart_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCardPart_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS CardPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewCardPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPart_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPart_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS ListPart";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewListPart(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenNew_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenNewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        if Opened then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceRoleCenter_TrapAndPageRun_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Ran: Boolean;
    begin
        Initialize();
        Pg.Trap();
        Ran := TryRunRoleCenter();
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('log after run', Log.Dump());
        if Ran then begin
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandleRoleCenter')]
    procedure NoSourceRoleCenter_RunModal_OK_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('OK');
        Ran := TryRunModalRoleCenter(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('HandleRoleCenter')]
    procedure NoSourceRoleCenter_RunModal_Cancel_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Act: Action;
        Ran: Boolean;
    begin
        Initialize();
        Log.SetMode('Cancel');
        Ran := TryRunModalRoleCenter(Act);
        Observer.Observe('run ok', Format(Ran));
        if not Ran then
            Observer.ObserveError('run error');
        Observer.Observe('action', Format(Act));
        Observer.Observe('log after run', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenView_ThenOKAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.OK().Invoke();
            Observer.Observe('log after OK', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceRoleCenter_OpenView_ThenCancelAction_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS RoleCenter";
        Opened: Boolean;
    begin
        Initialize();
        Opened := TryOpenViewRoleCenter(Pg);
        Observer.Observe('open ok', Format(Opened));
        if Opened then begin
            Log.Reset();
            Pg.Cancel().Invoke();
            Observer.Observe('log after Cancel', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceList_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceList_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceList_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceWorksheet_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPlus_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPlus_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceListPlus_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceStdDialog_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceNavPage_Action_UpdateTrue_EventLog()
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
            Pg.UpdateTrue.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceNavPage_Action_UpdateFalse_EventLog()
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
            Pg.UpdateFalse.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceNavPage_Action_CloseSelf_EventLog()
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
            Pg.CloseSelf.Invoke();
            Observer.Observe('log after action', Log.Dump());
            Log.Reset();
            Pg.Close();
            Observer.Observe('log after close', Log.Dump());
        end;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_SubscriberError_OnAfterGetCurrRecordEvent()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
        Closed: Boolean;
    begin
        Initialize();
        Log.SetFailAt('Card.OnAfterGetCurrRecordEvent');
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_CloseInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Log.SetMode('CloseInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_UpdateTrueInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Log.SetMode('UpdateTrueInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_UpdateFalseInOpen_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Log.SetMode('UpdateFalseInOpen');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Finish();
    end;

    [Test]
    procedure NoSourceCard_CurrPage_CloseInAgcr_EventLog()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "LT PNS Card";
        Opened: Boolean;
    begin
        Initialize();
        Log.SetMode('CloseInAgcr');
        Opened := TryOpenEditCard(Pg);
        Observer.Observe('open ok', Format(Opened));
        if not Opened then
            Observer.ObserveError('open error');
        Observer.Observe('log after open', Log.Dump());
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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

    [ModalPageHandler]
    procedure HandleRoleCenter(var P: TestPage "LT PNS RoleCenter")
    begin
        Log.Add('handler RoleCenter');
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
